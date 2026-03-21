pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ShellUtils.js" as SU
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
    var imageIds = [];
    for (var i = 0; i < entries.length; ++i) {
      var c = String(entries[i].content || "");
      if (c.indexOf("[[ binary data") !== -1 && (c.indexOf("png") !== -1 || c.indexOf("jpg") !== -1 || c.indexOf("jpeg") !== -1 || c.indexOf("bmp") !== -1 || c.indexOf("webp") !== -1))
        imageIds.push(String(entries[i].id));
    }
    if (imageIds.length === 0)
      return;

    var dir = root._cacheDir;
    // safeId is always parseInt'd, and dir is a hardcoded path, so $1 is sufficient
    var idList = [];
    for (var j = 0; j < imageIds.length; ++j) {
      var safeId = parseInt(imageIds[j], 10);
      if (!isNaN(safeId))
        idList.push(String(safeId));
    }
    if (idList.length === 0) return;
    _imageDecodePoll.command = ["sh", "-c",
      "d=\"$1\"; mkdir -p \"$d\"; shift; for id in \"$@\"; do cliphist decode \"$id\" > \"$d/$id.png\" 2>/dev/null & done; wait",
      "sh", dir].concat(idList);
    _imageDecodePoll._pendingIds = imageIds;
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
    property var _pendingIds: []
    running: false
    onExited: (exitCode, _exitStatus) => {
      if (exitCode !== 0)
        return;
      var newMap = {};
      var ids = _pendingIds;
      for (var i = 0; i < ids.length; ++i) {
        var safeId = parseInt(ids[i], 10);
        if (!isNaN(safeId))
          newMap[String(safeId)] = root._cacheDir + "/" + safeId + ".png";
      }
      root._decodedImages = newMap;
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
