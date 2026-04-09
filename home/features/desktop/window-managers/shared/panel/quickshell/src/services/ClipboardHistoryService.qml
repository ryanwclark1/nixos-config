pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ShellUtils.js" as SU
import "ClipboardDisplayHelpers.js" as ClipboardDisplay
import "."

QtObject {
  id: root
  property bool _destroyed: false

  property var items: []
  property bool loaded: false
  property bool loading: false
  property string lastError: ""
  property var _waiters: []
  property var _entryLinesById: ({})

  readonly property string _cacheDir: {
    var rt = Quickshell.env("XDG_RUNTIME_DIR");
    return (rt !== "" ? rt : "/tmp") + "/quickshell-clipboard";
  }
  property var _decodedImages: ({})
  property int _imageGeneration: 0

  function imagePath(id) {
    var _gen = _imageGeneration; // force binding dependency
    void _gen;
    var key = String(id || "");
    return _decodedImages.hasOwnProperty(key) ? _decodedImages[key] : "";
  }

  readonly property bool available: DependencyService.allAvailable(["cliphist", "wl-copy", "wl-paste"])

  function _finalize(itemsValue, errorText) {
    root.loading = false;
    root.loaded = errorText === "";
    root.lastError = String(errorText || "");
    if (root.loaded)
      root.items = Array.isArray(itemsValue) ? itemsValue : [];
    var waiters = root._waiters.slice();
    root._waiters = [];
    for (var i = 0; i < waiters.length; ++i) {
      try {
        waiters[i](root.loaded ? root.items : [], root.lastError);
      } catch (e) {
        Logger.w("ClipboardHistoryService", "callback threw", e);
      }
    }
  }

  function _parseHistory(rawText) {
    var lines = String(rawText || "").split("\n");
    var entries = [];
    var lineMap = {};
    for (var i = 0; i < lines.length; ++i) {
      var rawLine = String(lines[i] || "");
      if (rawLine.trim() === "")
        continue;
      var tabIndex = rawLine.indexOf("\t");
      if (tabIndex === -1)
        continue;
      var id = rawLine.substring(0, tabIndex);
      var content = rawLine.substring(tabIndex + 1);
      if (id === "" || content === "")
        continue;
      lineMap[id] = rawLine;
      entries.push({
        id: id,
        content: content
      });
    }
    root._entryLinesById = lineMap;
    return entries;
  }

  function _decodeImages(entries) {
    var imageJobs = [];
    for (var i = 0; i < entries.length; ++i) {
      var ext = ClipboardDisplay.imagePreviewExtension(entries[i].content || "");
      if (ext !== "")
        imageJobs.push({ id: String(entries[i].id), ext: ext });
    }
    if (imageJobs.length === 0) {
      root._decodedImages = ({});
      root._imageGeneration += 1;
      return;
    }

    var dir = root._cacheDir;
    // safeId is always parseInt'd, ext is derived from a fixed allow-list, and dir is a hardcoded path.
    var jobArgs = [];
    for (var j = 0; j < imageJobs.length; ++j) {
      var safeId = parseInt(imageJobs[j].id, 10);
      if (!isNaN(safeId)) {
        jobArgs.push(String(safeId));
        jobArgs.push(imageJobs[j].ext);
      }
    }
    if (jobArgs.length === 0) {
      root._decodedImages = ({});
      root._imageGeneration += 1;
      return;
    }
    _imageDecodePoll.command = ["sh", "-c",
      "d=\"$1\"; mkdir -p \"$d\"; shift; "
      + "while [ \"$#\" -ge 2 ]; do "
      + "id=\"$1\"; ext=\"$2\"; shift 2; out=\"$d/$id.$ext\"; "
      + "rm -f \"$out\"; "
      + "cliphist decode \"$id\" > \"$out\" 2>/dev/null || { rm -f \"$out\"; continue; }; "
      + "mt=$(file -Lb --mime-type \"$out\" 2>/dev/null || true); "
      + "case \"$mt\" in "
      + "image/png|image/jpeg|image/webp|image/gif|image/bmp) printf '%s\\t%s\\n' \"$id\" \"$out\" ;; "
      + "*) rm -f \"$out\" ;; "
      + "esac; "
      + "done",
      "sh", dir].concat(jobArgs);
    _imageDecodePoll._parsedMap = ({});
    _imageDecodePoll.running = true;
  }

  function refresh(callback) {
    if (callback)
      root._waiters = root._waiters.concat([callback]);
    if (root.loading)
      return;
    if (!root.available) {
      root._finalize([], "Clipboard history requires cliphist, wl-copy, and wl-paste.");
      return;
    }

    root.loading = true;
    root.lastError = "";
    _historyPoll.command = ["cliphist", "list"];
    _historyPoll.running = true;
  }

  function ensureLoaded(callback) {
    if (root.loaded) {
      if (callback)
        callback(root.items, "");
      return;
    }
    refresh(callback);
  }

  function restore(id) {
    var safeId = parseInt(id, 10);
    if (isNaN(safeId))
      return false;
    Quickshell.execDetached(["sh", "-c", "cliphist decode " + safeId + " | wl-copy"]);
    return true;
  }

  function deleteEntry(id) {
    var key = String(id || "");
    var line = String(root._entryLinesById[key] || "");
    if (line === "")
      return false;
    Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", line]);
    Qt.callLater(function() { if (root._destroyed) return; root.refresh(null); });
    return true;
  }

  function wipe() {
    Quickshell.execDetached(["cliphist", "wipe"]);
    root._entryLinesById = ({});
    root.items = [];
  }

  property Process _historyPoll: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var entries = root._parseHistory(this.text || "");
        root._finalize(entries, "");
        root._decodeImages(entries);
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        var err = String(this.text || "").trim();
        if (err !== "")
          root.lastError = err;
      }
    }
    onExited: (exitCode, _exitStatus) => {
      if (!root.loading)
        return;
      if (exitCode !== 0)
        root._finalize([], root.lastError !== "" ? root.lastError : "Failed to load clipboard history.");
    }
  }

  property Process _imageDecodePoll: Process {
    property var _parsedMap: ({})
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = String(this.text || "").trim().split("\n");
        var next = {};
        for (var i = 0; i < lines.length; ++i) {
          var line = String(lines[i] || "").trim();
          if (line === "")
            continue;
          var tabIndex = line.indexOf("\t");
          if (tabIndex === -1)
            continue;
          var id = line.substring(0, tabIndex).trim();
          var path = line.substring(tabIndex + 1).trim();
          if (id !== "" && path !== "")
            next[id] = path;
        }
        parent._parsedMap = next;
      }
    }
    onExited: (exitCode, _exitStatus) => {
      if (exitCode !== 0)
        return;
      root._decodedImages = Object.assign({}, _parsedMap);
      root._imageGeneration += 1;
    }
  }

  Component.onDestruction: _destroyed = true

  // Auto-refresh when clipboard content changes
  property Connections _clipboardConn: Connections {
    target: Quickshell
    function onClipboardTextChanged() {
      _autoRefreshTimer.restart();
    }
  }

  property Timer _autoRefreshTimer: Timer {
    interval: 200  // Small delay to avoid race with cliphist daemon
    repeat: false
    onTriggered: root.refresh(null)
  }
}
