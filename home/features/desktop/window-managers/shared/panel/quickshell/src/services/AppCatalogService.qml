pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ShellUtils.js" as SU

QtObject {
  id: root

  property var items: []
  property bool loaded: false
  property bool loading: false
  property bool cacheLoaded: false
  property bool loadedFromCache: false
  property string lastError: ""
  property var _waiters: []
  property var _paths: []
  readonly property string cachePath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/app_catalog.json"

  readonly property var desktopRoots: [
    "/usr/share/applications",
    "/usr/local/share/applications",
    (Quickshell.env("HOME") || "/home") + "/.local/share/applications",
    (Quickshell.env("HOME") || "/home") + "/.nix-profile/share/applications",
    "/run/current-system/sw/share/applications"
  ]

  function _desktopIdForPath(path) {
    var value = String(path || "");
    var slashIndex = value.lastIndexOf("/");
    if (slashIndex !== -1)
      value = value.substring(slashIndex + 1);
    if (value.endsWith(".desktop"))
      value = value.substring(0, value.length - 8);
    return value;
  }

  function _normalizeExec(execValue) {
    var cleaned = String(execValue || "");
    cleaned = cleaned.replace(/ ?%[fFuUdDnNickvm]/g, "");
    cleaned = cleaned.replace(/"/g, "");
    return cleaned.trim();
  }

  function _spaceSeparated(value) {
    return String(value || "").replace(/;/g, " ").trim();
  }

  function _parseDesktopEntry(text, path) {
    var lines = String(text || "").split(/\r?\n/);
    var inDesktopEntry = false;
    var inOtherGroup = false;
    var fields = {
      name: "",
      exec: "",
      icon: "",
      categories: "",
      keywords: "",
      hidden: "",
      noDisplay: "",
      terminal: ""
    };

    for (var i = 0; i < lines.length; ++i) {
      var line = String(lines[i] || "");
      if (line === "[Desktop Entry]") {
        inDesktopEntry = true;
        inOtherGroup = false;
        continue;
      }
      if (line.startsWith("[") && line.endsWith("]")) {
        if (inDesktopEntry)
          inOtherGroup = true;
        continue;
      }
      if (!inDesktopEntry || inOtherGroup)
        continue;

      if (fields.name === "" && line.startsWith("Name="))
        fields.name = line.substring(5);
      else if (fields.exec === "" && line.startsWith("Exec="))
        fields.exec = line.substring(5);
      else if (fields.icon === "" && line.startsWith("Icon="))
        fields.icon = line.substring(5);
      else if (fields.categories === "" && line.startsWith("Categories="))
        fields.categories = line.substring(11);
      else if (fields.keywords === "" && line.startsWith("Keywords="))
        fields.keywords = line.substring(9);
      else if (fields.noDisplay === "" && line.startsWith("NoDisplay="))
        fields.noDisplay = line.substring(10);
      else if (fields.hidden === "" && line.startsWith("Hidden="))
        fields.hidden = line.substring(7);
      else if (fields.terminal === "" && line.startsWith("Terminal="))
        fields.terminal = line.substring(9);
    }

    if (fields.name === "" || fields.exec === "")
      return null;
    if (String(fields.noDisplay).toLowerCase() === "true" || String(fields.hidden).toLowerCase() === "true")
      return null;

    return {
      name: fields.name,
      exec: _normalizeExec(fields.exec),
      icon: fields.icon,
      desktopId: _desktopIdForPath(path),
      category: _spaceSeparated(fields.categories),
      keywords: _spaceSeparated(fields.keywords),
      terminal: String(fields.terminal).toLowerCase() === "true"
    };
  }

  function _readTextFile(pathValue) {
    var reader = _fileReaderComponent.createObject(root, { path: pathValue });
    var text = null;
    try {
      text = reader.text();
    } catch (err) {
      text = null;
    }
    reader.destroy();
    return text;
  }

  function _finalize(itemsValue, errorText) {
    root.loading = false;
    root.loaded = errorText === "";
    root.lastError = String(errorText || "");
    if (root.loaded) {
      root.loadedFromCache = false;
      root.items = Array.isArray(itemsValue) ? itemsValue : [];
      root._persistItems(root.items);
    }
    var waiters = root._waiters.slice();
    root._waiters = [];
    for (var i = 0; i < waiters.length; ++i) {
      try {
        waiters[i](root.loaded ? root.items : [], root.lastError);
      } catch (e) {}
    }
  }

  function _enumerateDesktopFilesCommand() {
    return ["sh", "-c",
      "for dir in \"$@\"; do [ -d \"$dir\" ] || continue; find \"$dir\" -maxdepth 1 \\( -type f -o -type l \\) -name '*.desktop' -print; done",
      "sh"].concat(root.desktopRoots);
  }

  function _parseEnumeratedPaths(raw) {
    var lines = String(raw || "").split("\n");
    var unique = {};
    var paths = [];
    for (var i = 0; i < lines.length; ++i) {
      var path = String(lines[i] || "").trim();
      if (path === "" || unique[path] === true)
        continue;
      unique[path] = true;
      paths.push(path);
    }
    return paths;
  }

  function _buildItemsFromPaths(paths) {
    var items = [];
    var seenDesktopIds = {};
    for (var i = 0; i < paths.length; ++i) {
      var path = String(paths[i] || "");
      if (path === "")
        continue;
      var text = _readTextFile(path);
      if (text === null)
        continue;
      var item = _parseDesktopEntry(text, path);
      if (!item)
        continue;
      var desktopId = String(item.desktopId || "");
      if (desktopId !== "" && seenDesktopIds[desktopId] === true)
        continue;
      if (desktopId !== "")
        seenDesktopIds[desktopId] = true;
      items.push(item);
    }
    return items;
  }

  function _loadPersistedCache() {
    root.cacheLoaded = true;
    var raw = "";
    try {
      raw = _cacheFile.text();
    } catch (err) {
      raw = "";
    }
    if (!raw)
      return false;
    try {
      var parsed = JSON.parse(raw);
      var cachedItems = Array.isArray(parsed) ? parsed : parsed.items;
      if (!Array.isArray(cachedItems))
        return false;
      root.items = cachedItems;
      root.loaded = true;
      root.loadedFromCache = true;
      return true;
    } catch (err2) {
      return false;
    }
  }

  function _persistItems(itemsValue) {
    try {
      _cacheFile.setText(JSON.stringify({
        savedAt: Date.now(),
        items: Array.isArray(itemsValue) ? itemsValue : []
      }));
    } catch (err) {}
  }

  function ensureLoaded(callback) {
    if (root.loaded) {
      if (callback)
        callback(root.items, "");
      if (root.loadedFromCache && !root.loading)
        refresh(null);
      return;
    }
    if (!root.cacheLoaded)
      root._loadPersistedCache();
    if (root.loaded) {
      if (callback)
        callback(root.items, "");
      if (!root.loading)
        refresh(null);
      return;
    }
    refresh(callback);
  }

  function refresh(callback) {
    if (callback)
      root._waiters = root._waiters.concat([callback]);
    if (root.loading)
      return;

    root.loading = true;
    root.lastError = "";
    _enumeration.command = _enumerateDesktopFilesCommand();
    _enumeration.running = true;
  }

  function prewarm() {
    ensureLoaded(null);
  }

  Component.onCompleted: {
    root._loadPersistedCache();
  }

  property Process _enumeration: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root._paths = root._parseEnumeratedPaths(this.text || "");
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (!root.loading)
          return;
        var err = String(this.text || "").trim();
        if (err !== "")
          root.lastError = err;
      }
    }
    onExited: (exitCode, _exitStatus) => {
      if (exitCode !== 0) {
        root._finalize([], root.lastError !== "" ? root.lastError : "Failed to enumerate desktop applications.");
        return;
      }
      root._finalize(root._buildItemsFromPaths(root._paths), "");
    }
  }

  property Component _fileReaderComponent: Component {
    FileView {
      blockLoading: true
      printErrors: false
    }
  }

  property FileView _cacheFile: FileView {
    path: root.cachePath
    blockLoading: true
    printErrors: false
  }
}
