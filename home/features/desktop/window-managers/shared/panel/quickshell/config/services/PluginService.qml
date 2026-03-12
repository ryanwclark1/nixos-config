import Quickshell
import Quickshell.Io
import QtQuick

pragma Singleton

// PluginService — discovers and manages user QML plugins.
//
// Plugins live at: ~/.config/quickshell/plugins/<plugin-id>/
// Each folder must contain a manifest.json:
//   {
//     "id": "my-widget",
//     "name": "My Widget",
//     "description": "A custom desktop widget",
//     "author": "User",
//     "version": "1.0",
//     "type": "desktop-widget",   // "bar-widget" or "desktop-widget"
//     "main": "Widget.qml"
//   }
//
// Enabled/disabled state is persisted via Config.disabledPlugins.

QtObject {
  id: root

  readonly property string pluginsDir: Quickshell.env("HOME") + "/.config/quickshell/plugins"

  // Full list of discovered plugins (all, enabled or not)
  property var plugins: []

  // Convenience filtered views
  readonly property var barPlugins: {
    var result = [];
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i];
      if (p.enabled && p.type === "bar-widget") result.push(p);
    }
    return result;
  }

  readonly property var desktopPlugins: {
    var result = [];
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i];
      if (p.enabled && p.type === "desktop-widget") result.push(p);
    }
    return result;
  }

  // Re-run the directory scan
  function scanPlugins() {
    scanProc.running = true;
  }

  function enablePlugin(pluginId) {
    var disabledList = (Config.disabledPlugins || []).slice();
    var idx = disabledList.indexOf(pluginId);
    if (idx !== -1) {
      disabledList.splice(idx, 1);
      Config.disabledPlugins = disabledList;
    }
    _refreshEnabledStates();
  }

  function disablePlugin(pluginId) {
    var disabledList = (Config.disabledPlugins || []).slice();
    if (disabledList.indexOf(pluginId) === -1) {
      disabledList.push(pluginId);
      Config.disabledPlugins = disabledList;
    }
    _refreshEnabledStates();
  }

  function _refreshEnabledStates() {
    var disabledList = Config.disabledPlugins || [];
    var updated = [];
    for (var i = 0; i < plugins.length; i++) {
      var p = {
        id:          plugins[i].id,
        name:        plugins[i].name,
        description: plugins[i].description,
        author:      plugins[i].author,
        version:     plugins[i].version,
        type:        plugins[i].type,
        mainFile:    plugins[i].mainFile,
        path:        plugins[i].path,
        enabled:     disabledList.indexOf(plugins[i].id) === -1
      };
      updated.push(p);
    }
    plugins = updated;
  }

  // ── Scan process ─────────────────────────────────────────────────────────
  // Lists every sub-directory, reads manifest.json (augmented with the path),
  // and emits one JSON object per line via jq.
  property Process scanProc: Process {
    id: scanProc
    command: [
      "sh", "-c",
      "PLUGINS_DIR=" + root.pluginsDir + "; "
      + "for d in \"$PLUGINS_DIR\"/*/; do "
      + "[ -f \"$d/manifest.json\" ] && "
      + "jq -c --arg path \"$d\" '. + {\"path\": $path}' \"$d/manifest.json\"; "
      + "done 2>/dev/null"
    ]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n").filter(function(l) {
          return l.length > 0;
        });
        var result = [];
        var disabledList = Config.disabledPlugins || [];

        for (var i = 0; i < lines.length; i++) {
          try {
            var m = JSON.parse(lines[i]);
            var rawId = m.id || (m.name ? m.name.toLowerCase().replace(/\s+/g, "-") : "plugin-" + i);
            result.push({
              id:          rawId,
              name:        m.name        || "Unknown Plugin",
              description: m.description || "",
              author:      m.author      || "Unknown",
              version:     m.version     || "1.0",
              type:        m.type        || "desktop-widget",
              mainFile:    m.main        || "Main.qml",
              path:        m.path        || "",
              enabled:     disabledList.indexOf(rawId) === -1
            });
          } catch (e) {
            // Skip malformed manifests silently
          }
        }

        root.plugins = result;
      }
    }
  }

  // Re-sync enabled states whenever the persisted list changes
  // (e.g. after Config.load() restores them from disk)
  property Connections _configConn: Connections {
    target: Config
    function onDisabledPluginsChanged() { root._refreshEnabledStates(); }
  }

  Component.onCompleted: {
    // Small delay so Config has finished loading before we scan
    Qt.callLater(function() { root.scanPlugins(); });
  }
}
