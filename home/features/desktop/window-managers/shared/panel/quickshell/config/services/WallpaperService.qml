import QtQuick
import Quickshell
import Quickshell.Io
import "."

pragma Singleton

// WallpaperService — per-monitor wallpaper management with swww/hyprpaper support.
// Scans multiple well-known wallpaper directories and exposes the list of available
// wallpapers as `availableWallpapers`.  Tracks the currently-active wallpaper for each
// monitor in `wallpapers` (a monitorName → path map), persisted through Config.
//
// Wall-setter is tool-agnostic: tries swww first, then compositor-specific fallback
// provided by CompositorAdapter, then swaybg. Optionally runs pywal to regenerate colours.

QtObject {
  id: root

  // ---- Public state ----------------------------------------------------------

  // Map of monitorName → absolute image path, e.g. {"DP-1": "/home/user/Wallpapers/foo.jpg"}
  // Initialised from Config.wallpaperPaths on startup.
  property var wallpapers: ({})

  // Flat list of discovered image files across all search directories.
  // Each entry: { path: string, filename: string, dir: string }
  property var availableWallpapers: []

  // True while a directory scan is in progress.
  property bool scanning: false
  property bool solidColorActive: false
  property string solidColorHex: "000000ff"
  property var solidColorsByMonitor: ({})
  property string _applyImagePath: ""
  property string _applyMonitorName: ""
  property string _applyStdout: ""
  property string _applyStderr: ""
  property var _queuedApply: null
  property string _colorHex: "000000ff"
  property string _colorMonitorName: ""
  property string _colorApplyStderr: ""
  property bool _colorNotify: true
  property var _queuedSolidApplies: []

  // Primary wallpaper directory shown in the UI (default: Pictures).
  // The service always scans *all* wallpaperSearchDirs; this is just the folder
  // used by wallpaper selection workflows.
  readonly property string wallpaperDir: normalizedWallpaperDir(Config.wallpaperDefaultFolder)

  // Ordered list of directories to scan.
  // User-selected default folder replaces the built-in list.
  readonly property var wallpaperSearchDirs: [
    wallpaperDir
  ]

  // ---- Public API ------------------------------------------------------------

  // Trigger an async rescan of all wallpaperSearchDirs.
  function scanWallpapers() {
    if (scanning) return;
    scanning = true;
    // Build a script that iterates each directory independently, safely quoting each
    // path via single-quotes so spaces in $HOME are handled correctly.
    // Wrap individual finds in a subshell group, then sort -u the combined output.
    var findCmds = [];
    var fallbackDir = (Quickshell.env("HOME") || "/home") + "/Pictures";
    for (var i = 0; i < wallpaperSearchDirs.length; i++) {
      var qd = "'" + wallpaperSearchDirs[i].replace(/'/g, "'\\''") + "'";
      var qFallback = "'" + fallbackDir.replace(/'/g, "'\\''") + "'";
      findCmds.push(
        "{ d=" + qd + "; [ -d \"$d\" ] || d=" + qFallback + "; [ -d \"$d\" ] && "
        + "find \"$d\" -maxdepth 2 -type f "
        + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' "
        + "   -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' \\) "
        + "2>/dev/null | while IFS= read -r f; do "
        + "mt=$(file -Lb --mime-type \"$f\" 2>/dev/null || true); "
        + "case \"$mt\" in "
        + "image/jpeg|image/png|image/webp|image/gif|image/bmp|image/tiff) printf '%s\\n' \"$f\" ;; "
        + "esac; "
        + "done || true; }"
      );
    }
    var script = "{ " + findCmds.join("; ") + "; } | sort -u";
    scanProc.command = ["sh", "-c", script];
    scanProc.running = true;
  }

  // Apply `imagePath` as wallpaper for `monitorName`.
  // Pass an empty string for monitorName to target all monitors.
  // SECURITY: commands are assembled as arrays — no shell word-splitting on paths.
  function setWallpaper(imagePath, monitorName) {
    if (!imagePath) return;
    var request = { imagePath: imagePath, monitorName: monitorName || "" };
    if (applyProc.running) {
      _queuedApply = request;
      return;
    }
    _startApply(request);
  }

  function _startApply(request) {
    _applyImagePath = request.imagePath;
    _applyMonitorName = request.monitorName;
    _applyStdout = "";
    _applyStderr = "";
    applyProc.command = ["sh", "-c", _buildSetterScript(_applyImagePath, _applyMonitorName)];
    applyProc.running = true;
  }

  // Advance to the next available wallpaper for `monitorName` (wraps around).
  function nextWallpaper(monitorName) {
    if (availableWallpapers.length === 0) return;
    var current = wallpapers[monitorName || "__all__"] || "";
    var idx = _indexOfPath(current);
    var next = (idx + 1) % availableWallpapers.length;
    setWallpaper(availableWallpapers[next].path, monitorName);
  }

  // Pick a random available wallpaper for `monitorName`.
  function randomWallpaper(monitorName) {
    if (availableWallpapers.length === 0) return;
    var idx = Math.floor(Math.random() * availableWallpapers.length);
    setWallpaper(availableWallpapers[idx].path, monitorName);
  }

  // Apply a solid color background via swww.
  function setSolidColor(colorHex, monitorName, persistSetting, notifyUser) {
    var request = {
      colorHex: (colorHex || "000000ff").replace(/^#/, ""),
      monitorName: monitorName || "",
      persistSetting: persistSetting === undefined ? true : !!persistSetting,
      notifyUser: notifyUser === undefined ? true : !!notifyUser
    };
    if (applyProc.running || colorApplyProc.running) {
      _queuedSolidApplies = _queuedSolidApplies.concat([request]);
      return;
    }
    _startSolidApply(request);
  }

  function _startSolidApply(request) {
    _colorHex = request.colorHex;
    _colorMonitorName = request.monitorName;
    _colorNotify = request.notifyUser;
    if (request.persistSetting)
      Config.wallpaperSolidColor = _colorHex;
    _colorApplyStderr = "";
    colorApplyProc.command = ["sh", "-c", _buildSolidColorScript(_colorHex, _colorMonitorName)];
    colorApplyProc.running = true;
  }

  function solidColorForMonitor(monitorName) {
    var key = monitorName || "__all__";
    return solidColorsByMonitor[key] || solidColorsByMonitor["__all__"] || "";
  }

  function clearSolidForMonitor(monitorName, reapplyImage, notifyUser) {
    if (applyProc.running || colorApplyProc.running) {
      if (notifyUser !== false)
        ToastService.showNotice("Wallpaper busy", "Please wait for current wallpaper operation.");
      return;
    }
    var key = monitorName || "__all__";
    var mapObj = Object.assign({}, solidColorsByMonitor);
    delete mapObj[key];
    _persistSolidMap(mapObj);
    if (!solidColorActive)
      solidColorHex = Config.wallpaperSolidColor || "000000ff";

    if (!reapplyImage) {
      if (notifyUser !== false)
        ToastService.showSuccess("Solid disabled", "Using image mode for this target.");
      return;
    }

    var imagePath = key === "__all__"
      ? (wallpapers["__all__"] || "")
      : (wallpapers[key] || wallpapers["__all__"] || "");
    if (imagePath) {
      setWallpaper(imagePath, monitorName || "");
    } else if (notifyUser !== false) {
      ToastService.showNotice("No image wallpaper", "No saved image was found for this target.");
    }
  }

  function _persistSolidMap(mapObj) {
    solidColorsByMonitor = mapObj;
    Config.wallpaperSolidColorsByMonitor = Object.assign({}, mapObj);
    solidColorActive = Object.keys(mapObj).length > 0;
  }

  // ---- Auto-cycling ----------------------------------------------------------

  property Timer cycleTimer: Timer {
    id: cycleTimer
    repeat: true
    running: Config.wallpaperCycleInterval > 0
    interval: Math.max(1, Config.wallpaperCycleInterval) * 60 * 1000
    onTriggered: {
      // Cycle every connected monitor independently if they have a wallpaper set,
      // otherwise cycle the global slot.
      var keys = Object.keys(root.wallpapers);
      if (keys.length === 0) {
        root.nextWallpaper("");
      } else {
        for (var i = 0; i < keys.length; i++) {
          root.nextWallpaper(keys[i] === "__all__" ? "" : keys[i]);
        }
      }
    }
  }

  // React to interval config changes
  property Connections _cycleConfigWatcher: Connections {
    target: Config
    function onWallpaperCycleIntervalChanged() {
      cycleTimer.interval = Math.max(1, Config.wallpaperCycleInterval) * 60 * 1000;
      cycleTimer.running = Config.wallpaperCycleInterval > 0;
    }
    function onWallpaperDefaultFolderChanged() {
      root.scanWallpapers();
    }
  }

  // ---- Scan process ----------------------------------------------------------

  property Process scanProc: Process {
    id: scanProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n").filter(function(l) {
          return l.length > 0;
        });
        var result = [];
        for (var i = 0; i < lines.length; i++) {
          var p = lines[i].trim();
          if (!p) continue;
          var parts = p.split("/");
          var filename = parts[parts.length - 1];
          var dir = parts.slice(0, parts.length - 1).join("/");
          result.push({ path: p, filename: filename, dir: dir });
        }
        root.availableWallpapers = result;
        root.scanning = false;
      }
    }
  }

  property Process applyProc: Process {
    id: applyProc
    running: false
    onExited: (exitCode, exitStatus) => {
      var key = root._applyMonitorName || "__all__";
      if (exitCode === 0) {
        var clearedSolid = Object.assign({}, root.solidColorsByMonitor);
        if (key === "__all__") {
          clearedSolid = {};
        } else {
          delete clearedSolid[key];
        }
        root._persistSolidMap(clearedSolid);
        if (!root.solidColorActive)
          root.solidColorHex = Config.wallpaperSolidColor || "000000ff";
        var updated = Object.assign({}, root.wallpapers);
        updated[key] = root._applyImagePath;
        root.wallpapers = updated;
        Config.wallpaperPaths = Object.assign({}, root.wallpapers);

        if (Config.wallpaperRunPywal && !Config.themeName) {
          Quickshell.execDetached(["sh", "-c",
            "wal -i " + root._shellQuote(root._applyImagePath) + " -n -q 2>/dev/null || true"
          ]);
        }
        var backendLine = "";
        var outLines = (root._applyStdout || "").split("\n");
        for (var i = 0; i < outLines.length; i++) {
          if (outLines[i].indexOf("BACKEND:") === 0) {
            backendLine = outLines[i].trim();
            break;
          }
        }
        console.debug("WallpaperService: applied wallpaper via", backendLine || "unknown", "monitor", key, "path", root._applyImagePath);
      } else {
        var err = (root._applyStderr || "").trim();
        if (!err.length) err = "All wallpaper backends failed";
        console.warn("WallpaperService: failed to apply wallpaper", "monitor", key, "path", root._applyImagePath, "error", err);
        ToastService.showError("Wallpaper apply failed", "Check quickshell logs for backend errors.");
      }

      if (root._queuedApply) {
        var next = root._queuedApply;
        root._queuedApply = null;
        root._startApply(next);
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        root._applyStdout = this.text || "";
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        root._applyStderr = this.text || "";
      }
    }
  }

  property Process colorApplyProc: Process {
    id: colorApplyProc
    running: false
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        var err = (root._colorApplyStderr || "").trim();
        if (!err.length) err = "Failed to apply solid color background";
        console.warn("WallpaperService: solid color apply failed", "color", root._colorHex, "monitor", root._colorMonitorName || "__all__", "error", err);
        if (root._colorNotify)
          ToastService.showError("Solid color failed", "Could not apply solid color wallpaper.");
        if (root._queuedSolidApplies.length > 0) {
          var nextReqFail = root._queuedSolidApplies[0];
          root._queuedSolidApplies = root._queuedSolidApplies.slice(1);
          root._startSolidApply(nextReqFail);
        }
        return;
      }
      var key = root._colorMonitorName || "__all__";
      var updated = Object.assign({}, root.wallpapers);
      delete updated[key];
      root.wallpapers = updated;
      Config.wallpaperPaths = Object.assign({}, root.wallpapers);
      var solidMap = Object.assign({}, root.solidColorsByMonitor);
      if (key === "__all__")
        solidMap = { "__all__": root._colorHex };
      else
        solidMap[key] = root._colorHex;
      root._persistSolidMap(solidMap);
      root.solidColorHex = root._colorHex;
      console.debug("WallpaperService: applied solid color", root._colorHex, "monitor", root._colorMonitorName || "__all__");
      if (root._colorNotify)
        ToastService.showSuccess("Solid color applied", "#" + root._colorHex.slice(0, 6));
      if (root._queuedSolidApplies.length > 0) {
        var nextReq = root._queuedSolidApplies[0];
        root._queuedSolidApplies = root._queuedSolidApplies.slice(1);
        root._startSolidApply(nextReq);
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        root._colorApplyStderr = this.text || "";
      }
    }
  }

  // ---- Startup ---------------------------------------------------------------

  Component.onCompleted: {
    // Restore persisted per-monitor wallpaper map
    if (Config.wallpaperPaths && typeof Config.wallpaperPaths === "object") {
      wallpapers = Object.assign({}, Config.wallpaperPaths);
    }
    solidColorHex = Config.wallpaperSolidColor || "000000ff";
    if (Config.wallpaperSolidColorsByMonitor && typeof Config.wallpaperSolidColorsByMonitor === "object") {
      solidColorsByMonitor = Object.assign({}, Config.wallpaperSolidColorsByMonitor);
      solidColorActive = Object.keys(solidColorsByMonitor).length > 0;
    }
    if (Config.wallpaperUseSolidOnStartup) {
      setSolidColor(solidColorHex, "", false, false);
    } else if (solidColorActive) {
      if (solidColorsByMonitor["__all__"]) {
        setSolidColor(solidColorsByMonitor["__all__"], "", false, false);
      } else {
        var keys = Object.keys(solidColorsByMonitor);
        for (var i = 0; i < keys.length; i++) {
          var mon = keys[i];
          setSolidColor(solidColorsByMonitor[mon], mon, false, false);
        }
      }
    }
    scanWallpapers();
  }

  // ---- Private helpers -------------------------------------------------------

  function _indexOfPath(path) {
    for (var i = 0; i < availableWallpapers.length; i++) {
      if (availableWallpapers[i].path === path) return i;
    }
    return -1;
  }

  function normalizedWallpaperDir(rawPath) {
    var home = Quickshell.env("HOME") || "/home";
    var fallback = home + "/Pictures";
    var input = (rawPath || "").trim();
    if (!input) return fallback;
    if (input === "~") return home;
    if (input.indexOf("~/") === 0) return home + input.slice(1);
    if (input.indexOf("/") === 0) return input;
    return fallback;
  }

  // Minimal single-quote escaping for POSIX shell: replace ' with '\''
  function _shellQuote(s) {
    return "'" + s.replace(/'/g, "'\\''") + "'";
  }

  function _buildSetterScript(imagePath, monitorName) {
    var quoted = _shellQuote(imagePath);
    var outputFlag = monitorName ? ("--outputs " + _shellQuote(monitorName) + " ") : "";
    var hyprTarget = monitorName ? (monitorName + ",") : ",";
    var compositorWallpaperArg = _shellQuote(hyprTarget + imagePath);

    return "set -u; ok=0; "
         + "if command -v swww >/dev/null 2>&1; then "
         + "  if ! swww query >/dev/null 2>&1; then "
         + "    swww-daemon >/dev/null 2>&1 & "
         + "    tries=0; while ! swww query >/dev/null 2>&1 && [ \"$tries\" -lt 10 ]; do sleep 0.2; tries=$((tries + 1)); done; "
         + "  fi; "
         + "  if swww img " + outputFlag + quoted + " --transition-type fade --transition-duration 2; then "
         + "    echo BACKEND:swww; ok=1; "
         + "  fi; "
         + "fi; "
         + CompositorAdapter.wallpaperCompositorFallbackSnippet(compositorWallpaperArg)
         + "if [ \"$ok\" -eq 0 ] && command -v swaybg >/dev/null 2>&1; then "
         + "  pkill swaybg >/dev/null 2>&1 || true; "
         + "  swaybg -i " + quoted + " -m fill >/dev/null 2>&1 & "
         + "  echo BACKEND:swaybg; ok=1; "
         + "fi; "
         + "[ \"$ok\" -eq 1 ]";
  }

  function _buildSolidColorScript(colorHex, monitorName) {
    var outputFlag = monitorName ? ("--outputs " + _shellQuote(monitorName) + " ") : "";
    return "set -u; "
         + "command -v swww >/dev/null 2>&1 || { echo 'swww not installed' >&2; exit 1; }; "
         + "if ! swww query >/dev/null 2>&1; then "
         + "  swww-daemon >/dev/null 2>&1 & "
         + "  tries=0; while ! swww query >/dev/null 2>&1 && [ \"$tries\" -lt 10 ]; do sleep 0.2; tries=$((tries + 1)); done; "
         + "fi; "
         + "swww clear " + outputFlag + _shellQuote(colorHex);
  }
}
