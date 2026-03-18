pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property var items: []
  property bool loaded: false
  property bool loading: false
  property string lastError: ""
  property var _waiters: []
  property var _entryLinesById: ({})

  readonly property bool available: DependencyService.allAvailable(["cliphist", "wl-copy", "wl-paste"])

  function _shellQuote(text) {
    return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
  }

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
      } catch (e) {}
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
    Quickshell.execDetached(["sh", "-c", "printf '%s\\n' " + root._shellQuote(line) + " | cliphist delete"]);
    Qt.callLater(function() { root.refresh(null); });
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
        root._finalize(root._parseHistory(this.text || ""), "");
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
}
