pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * DependencyService
 *
 * Centralized service for checking system dependencies (binaries, scripts).
 * Provides a way to check if a feature can be enabled based on available tools.
 */
QtObject {
  id: root

  // ── State ──────────────────────────────────────
  property var _availability: ({})
  property var _features: ({})
  property bool initialized: false

  // ── Public API ─────────────────────────────────

  /**
   * Check if a binary is available in the system PATH.
   */
  function isAvailable(binary) {
    return !!_availability[binary];
  }

  /**
   * Check if a list of binaries are all available.
   */
  function allAvailable(binaries) {
    if (!binaries || binaries.length === 0) return true;
    for (var i = 0; i < binaries.length; i++) {
      if (!isAvailable(binaries[i])) return false;
    }
    return true;
  }

  /**
   * Check if any of the binaries in the list is available (fallback pattern).
   */
  function anyAvailable(binaries) {
    if (!binaries || binaries.length === 0) return true;
    for (var i = 0; i < binaries.length; i++) {
      if (isAvailable(binaries[i])) return true;
    }
    return false;
  }

  /**
   * Get the first available binary from a list of fallbacks.
   */
  function getFallback(binaries, defaultReturn = "") {
    for (var i = 0; i < binaries.length; i++) {
      if (isAvailable(binaries[i])) return binaries[i];
    }
    return defaultReturn;
  }

  /**
   * Register a feature that depends on certain binaries.
   * If any required binary is missing, the feature is marked unavailable.
   */
  function registerFeature(name, requiredBinaries) {
    var available = allAvailable(requiredBinaries);
    var next = Object.assign({}, _features);
    next[name] = {
      name: name,
      required: requiredBinaries,
      available: available
    };
    _features = next;
    return available;
  }

  /**
   * Check if a registered feature is available.
   */
  function isFeatureAvailable(name) {
    return _features[name] ? _features[name].available : false;
  }

  /**
   * Check if a local script in the scripts/ directory is available and executable.
   */
  function isScriptAvailable(scriptName) {
    // This is more complex to check from JS without a Process, 
    // but we can assume if it's in the initial list or 
    // we can use a similar approach to binaries.
    return isAvailable(scriptName);
  }

  // ── Initialization ─────────────────────────────

  // List of common dependencies to check on startup
  readonly property var _initialDependencies: [
    "nmcli", "ip", "tailscale", "cava", "playerctl", "cliphist", "wl-copy", "xclip",
    "hyprctl", "niri", "swww", "waypaper", "fastfetch", "htop", "btop", "btm",
    "brightnessctl", "light", "wpctl", "pactl", "amixer", "bluetoothctl",
    "grim", "slurp", "swappy", "wf-recorder", "ffmpeg", "magick", "jq", "sed", "awk",
    "./scripts/cliphist.sh", "./scripts/cava.sh", "./scripts/apps.sh", 
    "./scripts/network.sh", "./scripts/screenshot.sh", "./scripts/updator.sh"
  ]

  Component.onCompleted: {
    _checkBinaries(_initialDependencies);
  }

  function _checkBinaries(binaries) {
    var checkCmd = "for b in " + binaries.join(" ") + "; do " +
                   "if command -v \"$b\" >/dev/null 2>&1; then printf \"$b:1\\n\"; else printf \"$b:0\\n\"; fi; " +
                   "done";

    _checker.command = ["sh", "-c", checkCmd];
    _checker.running = true;
  }

  property Process _checker: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        var next = Object.assign({}, root._availability);
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(":");
          if (parts.length === 2) {
            next[parts[0]] = parts[1] === "1";
          }
        }
        root._availability = next;
        root.initialized = true;

        // Update all features after availability changes
        var nextFeatures = Object.assign({}, root._features);
        for (var featureName in nextFeatures) {
          var feature = nextFeatures[featureName];
          var available = root.allAvailable(feature.required);
          if (available !== feature.available)
            feature.available = available;
        }
        root._features = nextFeatures;
      }
    }
  }

  /**
   * Allow dynamic checks for dependencies not in the initial list.
   */
  function checkDynamic(binaries, callback) {
    var checkCmd = "for b in " + binaries.join(" ") + "; do " +
                   "if command -v \"$b\" >/dev/null 2>&1; then printf \"$b:1\\n\"; else printf \"$b:0\\n\"; fi; " +
                   "done";

    var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root);
    var collector = Qt.createQmlObject('import Quickshell.Io; StdioCollector { }', proc);
    proc.stdout = collector;

    collector.streamFinished.connect(function() {
      var lines = (collector.text || "").trim().split("\n");
      var results = {};
      var next = Object.assign({}, root._availability);
      for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split(":");
        if (parts.length === 2) {
          var available = parts[1] === "1";
          results[parts[0]] = available;
          next[parts[0]] = available;
        }
      }
      root._availability = next;
      if (callback) callback(results);
      proc.destroy();
    });

    proc.command = ["sh", "-c", checkCmd];
    proc.running = true;
  }
}
