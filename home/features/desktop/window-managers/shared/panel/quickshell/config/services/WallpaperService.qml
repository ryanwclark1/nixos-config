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
// Wall-setter is tool-agnostic: tries swww first (most common on Hyprland) then falls
// back to `hyprctl hyprpaper`.  Optionally runs pywal to regenerate the colour scheme.

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

  // Primary wallpaper directory shown in the UI (default: Pictures).
  // The service always scans *all* wallpaperSearchDirs; this is just the folder
  // opened by the "Open Folder" button.
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

    // Update in-memory state
    var updated = Object.assign({}, wallpapers);
    var key = monitorName || "__all__";
    updated[key] = imagePath;
    wallpapers = updated;

    // Persist through Config
    Config.wallpaperPaths = Object.assign({}, wallpapers);

    // Build the setter command
    var setter = _buildSetterScript(imagePath, monitorName || "");
    Quickshell.execDetached(["sh", "-c", setter]);

    // Optionally regenerate pywal colour scheme (skip when a base24 theme is active)
    if (Config.wallpaperRunPywal && !Config.themeName) {
      Quickshell.execDetached(["sh", "-c",
        "wal -i " + _shellQuote(imagePath) + " -n -q 2>/dev/null || true"
      ]);
    }
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

  // Open the primary wallpaper directory in the default file manager.
  function openWallpaperFolder() {
    Quickshell.execDetached(["xdg-open", wallpaperDir]);
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

  // ---- Startup ---------------------------------------------------------------

  Component.onCompleted: {
    // Restore persisted per-monitor wallpaper map
    if (Config.wallpaperPaths && typeof Config.wallpaperPaths === "object") {
      wallpapers = Object.assign({}, Config.wallpaperPaths);
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

    return "if command -v swww >/dev/null 2>&1; then "
         + "  swww img " + outputFlag + quoted
         + "    --transition-type fade --transition-duration 2 2>/dev/null || "
         + "  swww img " + outputFlag + quoted + " 2>/dev/null; "
         + "elif command -v hyprctl >/dev/null 2>&1; then "
         + "  hyprctl hyprpaper wallpaper " + _shellQuote(hyprTarget + imagePath) + " 2>/dev/null; "
         + "elif command -v swaybg >/dev/null 2>&1; then "
         + "  swaybg -i " + quoted + " -m fill & "
         + "fi";
  }
}
