pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property var _systemAvailability: ({})
  property var _resolvedCommands: ({})
  property var _features: ({})
  property bool initialized: false

  readonly property string _homeBinDir: (Quickshell.env("HOME") || "/home") + "/.local/bin"
  readonly property var _systemDependencies: [
    "amixer", "awk", "bluetoothctl", "brightnessctl", "cliphist", "ffmpeg", "grim",
    "htop", "hyprctl", "ip", "jq", "light", "magick", "nmcli", "niri", "pactl",
    "playerctl", "sed", "slurp", "swww", "tailscale", "waypaper", "wf-recorder",
    "wl-copy", "wl-paste", "wpctl"
  ]
  readonly property var _managedCommandSpecs: ({
      "qs-ai": {
        requires: ["wl-copy"]
      },
      "qs-ai-stream": {
        requires: []
      },
      "qs-bookmarks": {
        requires: []
      },
      "qs-cava": {
        requires: []
      },
      "qs-emoji": {
        requires: []
      },
      "qs-icon-resolver": {
        requires: []
      },
      "qs-inhibitor": {
        requires: []
      },
      "qs-keybinds": {
        requires: []
      },
      "qs-network": {
        requires: ["nmcli"]
      },
      "qs-run": {
        requires: []
      },
      "qs-screenshot": {
        requires: ["grim", "slurp", "wl-copy"]
      },
      "qs-sleep-monitor": {
        requires: []
      },
      "qs-updator": {
        requires: []
      },
      "qs-wallpapers": {
        requires: []
      }
    })

  function _shellQuote(text) {
    return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
  }

  function _managedCommandNames() {
    return Object.keys(root._managedCommandSpecs);
  }

  function _managedSpec(name) {
    return root._managedCommandSpecs[String(name || "")] || null;
  }

  function _managedFallbackPath(name) {
    return root._homeBinDir + "/" + String(name || "");
  }

  function knows(name) {
    var key = String(name || "");
    return root._systemDependencies.indexOf(key) !== -1 || !!root._managedCommandSpecs[key];
  }

  function isAvailable(name) {
    var key = String(name || "");
    if (!!root._managedCommandSpecs[key])
      return hasResolvedCommand(key);
    return !!root._systemAvailability[key];
  }

  function hasResolvedCommand(name) {
    var key = String(name || "");
    var command = root._resolvedCommands[key];
    if (!command || command.length === 0)
      return false;
    var spec = root._managedCommandSpecs[key];
    if (!spec)
      return false;
    return root.allAvailable(spec.requires || []);
  }

  function resolveCommand(name, extraArgs) {
    var key = String(name || "");
    var args = Array.isArray(extraArgs) ? extraArgs : [];
    if (!!root._managedCommandSpecs[key]) {
      if (!hasResolvedCommand(key))
        return [];
      return root._resolvedCommands[key].concat(args);
    }
    if (!isAvailable(key))
      return [];
    return [key].concat(args);
  }

  function missingFor(name) {
    var key = String(name || "");
    var missing = [];
    if (!!root._managedCommandSpecs[key]) {
      if (!root._resolvedCommands[key] || root._resolvedCommands[key].length === 0)
        missing.push(key);
      var requires = root._managedCommandSpecs[key].requires || [];
      for (var i = 0; i < requires.length; ++i) {
        if (!root.isAvailable(requires[i]))
          missing.push(requires[i]);
      }
      return missing;
    }
    if (!root.isAvailable(key))
      missing.push(key);
    return missing;
  }

  function allAvailable(names) {
    if (!names || names.length === 0) return true;
    for (var i = 0; i < names.length; i++) {
      if (!isAvailable(names[i])) return false;
    }
    return true;
  }

  function anyAvailable(names) {
    if (!names || names.length === 0) return true;
    for (var i = 0; i < names.length; i++) {
      if (isAvailable(names[i])) return true;
    }
    return false;
  }

  function getFallback(names, defaultReturn) {
    var fallback = defaultReturn === undefined ? "" : defaultReturn;
    if (!names || names.length === 0)
      return fallback;
    for (var i = 0; i < names.length; i++) {
      if (isAvailable(names[i]))
        return names[i];
    }
    return fallback;
  }

  function registerFeature(name, requiredNames) {
    var available = allAvailable(requiredNames);
    var next = Object.assign({}, _features);
    next[name] = {
      name: name,
      required: requiredNames,
      available: available
    };
    _features = next;
    return available;
  }

  function isFeatureAvailable(name) {
    return _features[name] ? _features[name].available : false;
  }

  function refresh() {
    _checkKnownDependencies();
  }

  function _checkKnownDependencies() {
    var script = [];
    var i;
    for (i = 0; i < root._systemDependencies.length; ++i) {
      var binary = root._systemDependencies[i];
      script.push(
        "if command -v " + root._shellQuote(binary) + " >/dev/null 2>&1; then printf 'system|" + binary + "|1\\n'; else printf 'system|" + binary + "|0\\n'; fi"
      );
    }

    var helpers = root._managedCommandNames();
    for (i = 0; i < helpers.length; ++i) {
      var helper = helpers[i];
      var fallbackPath = root._managedFallbackPath(helper);
      script.push(
        "if command -v " + root._shellQuote(helper) + " >/dev/null 2>&1; then printf 'managed|" + helper + "|%s\\n' \"$(command -v " + root._shellQuote(helper) + ")\"; " +
        "elif [ -x " + root._shellQuote(fallbackPath) + " ]; then printf 'managed|" + helper + "|" + fallbackPath.replace(/'/g, "'\\''") + "\\n'; " +
        "else printf 'managed|" + helper + "|\\n'; fi"
      );
    }

    _checker.command = ["sh", "-c", script.join("; ")];
    _checker.running = true;
  }

  function _applyProbeOutput(rawText) {
    var lines = String(rawText || "").trim().split("\n");
    var nextSystem = {};
    var nextResolved = {};
    var i;

    for (i = 0; i < root._systemDependencies.length; ++i)
      nextSystem[root._systemDependencies[i]] = false;

    for (i = 0; i < lines.length; ++i) {
      var line = String(lines[i] || "");
      if (line === "")
        continue;
      var firstSep = line.indexOf("|");
      var secondSep = line.indexOf("|", firstSep + 1);
      if (firstSep === -1 || secondSep === -1)
        continue;
      var kind = line.substring(0, firstSep);
      var name = line.substring(firstSep + 1, secondSep);
      var value = line.substring(secondSep + 1);
      if (kind === "system") {
        nextSystem[name] = value === "1";
      } else if (kind === "managed") {
        var trimmed = value.trim();
        if (trimmed !== "")
          nextResolved[name] = [trimmed];
      }
    }

    root._systemAvailability = nextSystem;
    root._resolvedCommands = nextResolved;
    root.initialized = true;

    var nextFeatures = Object.assign({}, root._features);
    for (var featureName in nextFeatures) {
      var feature = nextFeatures[featureName];
      var available = root.allAvailable(feature.required);
      if (available !== feature.available)
        feature.available = available;
    }
    root._features = nextFeatures;
  }

  Component.onCompleted: refresh()

  property Process _checker: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root._applyProbeOutput(this.text || "");
      }
    }
  }

  function checkDynamic(names, callback) {
    var binaries = Array.isArray(names) ? names : [];
    if (binaries.length === 0) {
      if (callback)
        callback({});
      return;
    }

    var script = [];
    for (var i = 0; i < binaries.length; ++i) {
      var binary = String(binaries[i] || "");
      if (binary === "")
        continue;
      script.push(
        "if command -v " + root._shellQuote(binary) + " >/dev/null 2>&1; then printf '" + binary.replace(/'/g, "'\\''") + ":1\\n'; else printf '" + binary.replace(/'/g, "'\\''") + ":0\\n'; fi"
      );
    }

    var proc = Qt.createQmlObject('import Quickshell.Io; Process { }', root);
    var collector = Qt.createQmlObject('import Quickshell.Io; StdioCollector { }', proc);
    proc.stdout = collector;

    collector.streamFinished.connect(function() {
      var lines = (collector.text || "").trim().split("\n");
      var results = {};
      var next = Object.assign({}, root._systemAvailability);
      for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split(":");
        if (parts.length === 2) {
          var available = parts[1] === "1";
          results[parts[0]] = available;
          next[parts[0]] = available;
        }
      }
      root._systemAvailability = next;
      if (callback)
        callback(results);
      proc.destroy();
    });

    proc.command = ["sh", "-c", script.join("; ")];
    proc.running = true;
  }
}
