import Quickshell
import Quickshell.Io
import QtQuick

pragma Singleton

QtObject {
  id: root

  readonly property string pluginsDir: Quickshell.env("HOME") + "/.config/quickshell/plugins"

  // Full list of discovered plugins (enabled + disabled).
  property var plugins: []
  property var pluginIndex: ({})
  property var pluginErrors: ({})

  // Runtime state for active plugin components.
  property var daemonComponents: ({})
  property var daemonInstances: ({})
  property var launcherProviderComponents: ({})
  property var launcherProviderInstances: ({})
  property var pluginApis: ({})

  // Fingerprints for hot-reload detection.
  property var pluginFingerprints: ({})

  readonly property var barPlugins: {
    var result = [];
    for (var i = 0; i < plugins.length; ++i) {
      var p = plugins[i];
      if (p.enabled && p.entryPoints && p.entryPoints.barWidget)
        result.push(p);
    }
    return result;
  }

  readonly property var desktopPlugins: {
    var result = [];
    for (var i = 0; i < plugins.length; ++i) {
      var p = plugins[i];
      if (p.enabled && p.entryPoints && p.entryPoints.desktopWidget)
        result.push(p);
    }
    return result;
  }

  readonly property var launcherPlugins: {
    var result = [];
    for (var i = 0; i < plugins.length; ++i) {
      var p = plugins[i];
      if (p.enabled && p.entryPoints && p.entryPoints.launcherProvider)
        result.push(p);
    }
    return result;
  }

  readonly property var daemonPlugins: {
    var result = [];
    for (var i = 0; i < plugins.length; ++i) {
      var p = plugins[i];
      if (p.enabled && p.entryPoints && p.entryPoints.daemon)
        result.push(p);
    }
    return result;
  }

  signal pluginCatalogChanged
  signal pluginRuntimeChanged

  function scanPlugins() {
    scanProc.running = true;
  }

  function pluginById(pluginId) {
    return pluginIndex[String(pluginId || "")] || null;
  }

  function getPluginAPI(pluginId) {
    return pluginApis[String(pluginId || "")] || null;
  }

  function enablePlugin(pluginId) {
    var id = String(pluginId || "");
    if (!pluginIndex[id])
      return false;
    var disabledList = (Config.disabledPlugins || []).slice();
    var idx = disabledList.indexOf(id);
    if (idx !== -1) {
      disabledList.splice(idx, 1);
      Config.disabledPlugins = disabledList;
    }
    _refreshEnabledStates();
    return true;
  }

  function disablePlugin(pluginId) {
    var id = String(pluginId || "");
    if (!pluginIndex[id])
      return false;
    var disabledList = (Config.disabledPlugins || []).slice();
    if (disabledList.indexOf(id) === -1) {
      disabledList.push(id);
      Config.disabledPlugins = disabledList;
    }
    _refreshEnabledStates();
    return true;
  }

  function _isValidPermission(permission) {
    return permission === "settings_read"
      || permission === "settings_write"
      || permission === "state_read"
      || permission === "state_write"
      || permission === "process";
  }

  function _normalizePermissions(rawPermissions) {
    if (!Array.isArray(rawPermissions))
      return [];
    var out = [];
    var seen = ({});
    for (var i = 0; i < rawPermissions.length; ++i) {
      var perm = String(rawPermissions[i] || "").trim();
      if (perm === "" || seen[perm] || !_isValidPermission(perm))
        continue;
      seen[perm] = true;
      out.push(perm);
    }
    return out;
  }

  function _hasPermission(plugin, permission) {
    if (!plugin || !permission)
      return false;
    var perms = plugin.permissions || [];
    return perms.indexOf(permission) !== -1;
  }

  function _rejectPermission(pluginId, permission, operation) {
    console.warn("PluginService: Permission denied for", pluginId, "permission=", permission, "operation=", operation);
    return false;
  }

  function _ensurePluginStateDir(pluginId) {
    var dir = pluginsDir + "/" + pluginId;
    var proc = ensureStateDirProcComponent.createObject(root);
    proc.command = ["mkdir", "-p", dir];
    proc.running = true;
    proc.exited.connect(function() {
      proc.destroy();
    });
  }

  function _statePath(pluginId) {
    return pluginsDir + "/" + pluginId + "/state.json";
  }

  function _buildPluginApi(plugin) {
    var pluginId = plugin.id;
    var stateFilePath = _statePath(pluginId);

    return {
      id: pluginId,
      hasPermission: function(permission) {
        return root._hasPermission(plugin, permission);
      },
      loadSetting: function(key, defaultValue) {
        if (!root._hasPermission(plugin, "settings_read"))
          return defaultValue;
        var settings = Config.pluginSettings || ({ });
        var pluginSettings = settings[pluginId] || ({ });
        return pluginSettings[key] !== undefined ? pluginSettings[key] : defaultValue;
      },
      saveSetting: function(key, value) {
        if (!root._hasPermission(plugin, "settings_write"))
          return root._rejectPermission(pluginId, "settings_write", "saveSetting");
        var settings = Object.assign({}, Config.pluginSettings || ({ }));
        var pluginSettings = Object.assign({}, settings[pluginId] || ({ }));
        pluginSettings[key] = value;
        settings[pluginId] = pluginSettings;
        Config.pluginSettings = settings;
        return true;
      },
      removeSetting: function(key) {
        if (!root._hasPermission(plugin, "settings_write"))
          return root._rejectPermission(pluginId, "settings_write", "removeSetting");
        var settings = Object.assign({}, Config.pluginSettings || ({ }));
        var pluginSettings = Object.assign({}, settings[pluginId] || ({ }));
        if (pluginSettings[key] === undefined)
          return true;
        delete pluginSettings[key];
        settings[pluginId] = pluginSettings;
        Config.pluginSettings = settings;
        return true;
      },
      loadState: function() {
        if (!root._hasPermission(plugin, "state_read"))
          return ({ });
        var fv = root.stateReaderComponent.createObject(root, { path: stateFilePath });
        var parsed = ({ });
        try {
          var raw = fv.text();
          if (raw && String(raw).trim() !== "")
            parsed = JSON.parse(raw);
        } catch (e) {}
        fv.destroy();
        return parsed;
      },
      saveState: function(data) {
        if (!root._hasPermission(plugin, "state_write"))
          return root._rejectPermission(pluginId, "state_write", "saveState");
        root._ensurePluginStateDir(pluginId);
        var writer = root.stateWriterComponent.createObject(root, { path: stateFilePath });
        writer.setText(JSON.stringify(data || ({ }), null, 2));
        writer.destroy();
        return true;
      },
      runProcess: function(commandArray) {
        if (!root._hasPermission(plugin, "process"))
          return root._rejectPermission(pluginId, "process", "runProcess");
        if (!Array.isArray(commandArray) || commandArray.length === 0)
          return false;
        Quickshell.execDetached(commandArray);
        return true;
      }
    };
  }

  function _buildPluginPath(plugin, entryKey) {
    if (!plugin || !plugin.entryPoints)
      return "";
    var rel = String(plugin.entryPoints[entryKey] || "");
    if (rel === "")
      return "";
    return String(plugin.path || "") + rel;
  }

  function _instantiateLauncherProvider(plugin) {
    var providerPath = _buildPluginPath(plugin, "launcherProvider");
    if (providerPath === "")
      return;

    var component = Qt.createComponent("file://" + providerPath);
    if (component.status !== Component.Ready) {
      console.warn("PluginService: Failed to load launcher provider", plugin.id, component.errorString());
      return;
    }

    var api = pluginApis[plugin.id] || _buildPluginApi(plugin);
    var instance = component.createObject(root, {
      pluginApi: api,
      pluginManifest: plugin,
      pluginService: root
    });
    if (!instance) {
      console.warn("PluginService: Failed to instantiate launcher provider", plugin.id, component.errorString());
      return;
    }

    var components = Object.assign({}, launcherProviderComponents);
    var instances = Object.assign({}, launcherProviderInstances);
    var apis = Object.assign({}, pluginApis);
    components[plugin.id] = component;
    instances[plugin.id] = instance;
    apis[plugin.id] = api;
    launcherProviderComponents = components;
    launcherProviderInstances = instances;
    pluginApis = apis;
  }

  function _destroyLauncherProvider(pluginId) {
    var pid = String(pluginId || "");

    if (launcherProviderInstances[pid]) {
      try {
        if (launcherProviderInstances[pid].shutdown)
          launcherProviderInstances[pid].shutdown();
      } catch (e) {}
      launcherProviderInstances[pid].destroy();
    }

    var instances = Object.assign({}, launcherProviderInstances);
    var components = Object.assign({}, launcherProviderComponents);
    delete instances[pid];
    delete components[pid];
    launcherProviderInstances = instances;
    launcherProviderComponents = components;
  }

  function _instantiateDaemon(plugin) {
    var daemonPath = _buildPluginPath(plugin, "daemon");
    if (daemonPath === "")
      return;

    var component = Qt.createComponent("file://" + daemonPath);
    if (component.status !== Component.Ready) {
      console.warn("PluginService: Failed to load daemon", plugin.id, component.errorString());
      return;
    }

    var api = pluginApis[plugin.id] || _buildPluginApi(plugin);
    var instance = component.createObject(root, {
      pluginApi: api,
      pluginManifest: plugin,
      pluginService: root
    });
    if (!instance) {
      console.warn("PluginService: Failed to instantiate daemon", plugin.id, component.errorString());
      return;
    }

    var components = Object.assign({}, daemonComponents);
    var instances = Object.assign({}, daemonInstances);
    var apis = Object.assign({}, pluginApis);
    components[plugin.id] = component;
    instances[plugin.id] = instance;
    apis[plugin.id] = api;
    daemonComponents = components;
    daemonInstances = instances;
    pluginApis = apis;

    try {
      if (instance.start)
        instance.start();
    } catch (e) {}
  }

  function _destroyDaemon(pluginId) {
    var pid = String(pluginId || "");

    if (daemonInstances[pid]) {
      try {
        if (daemonInstances[pid].stop)
          daemonInstances[pid].stop();
      } catch (e) {}
      daemonInstances[pid].destroy();
    }

    var instances = Object.assign({}, daemonInstances);
    var components = Object.assign({}, daemonComponents);
    delete instances[pid];
    delete components[pid];
    daemonInstances = instances;
    daemonComponents = components;
  }

  function _refreshRuntime() {
    // Unload anything no longer active.
    for (var activeDaemonId in daemonInstances) {
      var activeDaemon = pluginById(activeDaemonId);
      if (!activeDaemon || !activeDaemon.enabled || !activeDaemon.entryPoints || !activeDaemon.entryPoints.daemon)
        _destroyDaemon(activeDaemonId);
    }

    for (var activeProviderId in launcherProviderInstances) {
      var activeProvider = pluginById(activeProviderId);
      if (!activeProvider || !activeProvider.enabled || !activeProvider.entryPoints || !activeProvider.entryPoints.launcherProvider)
        _destroyLauncherProvider(activeProviderId);
    }

    // Load all enabled daemons and launcher providers.
    var daemons = daemonPlugins;
    for (var i = 0; i < daemons.length; ++i) {
      if (!daemonInstances[daemons[i].id])
        _instantiateDaemon(daemons[i]);
    }

    var launchers = launcherPlugins;
    for (var j = 0; j < launchers.length; ++j) {
      if (!launcherProviderInstances[launchers[j].id])
        _instantiateLauncherProvider(launchers[j]);
    }

    pluginRuntimeChanged();
  }

  function _typeValid(typeName) {
    return typeName === "bar-widget"
      || typeName === "desktop-widget"
      || typeName === "launcher-provider"
      || typeName === "daemon"
      || typeName === "multi";
  }

  function _entryPathValid(pathValue) {
    var p = String(pathValue || "");
    if (p === "")
      return false;
    if (p.indexOf("..") !== -1)
      return false;
    return p.match(/\.qml$/) !== null;
  }

  function _validateManifest(manifest, pluginPath) {
    if (!manifest || typeof manifest !== "object")
      return ({ ok: false, error: "manifest must be an object" });

    var required = ["id", "name", "description", "author", "version", "type", "entryPoints", "permissions"];
    for (var i = 0; i < required.length; ++i) {
      var key = required[i];
      if (manifest[key] === undefined)
        return ({ ok: false, error: "missing required field: " + key });
    }

    var pluginId = String(manifest.id || "");
    if (!pluginId.match(/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/))
      return ({ ok: false, error: "id must be filesystem-safe" });

    var typeName = String(manifest.type || "");
    if (!_typeValid(typeName))
      return ({ ok: false, error: "invalid type: " + typeName });

    if (!manifest.entryPoints || typeof manifest.entryPoints !== "object")
      return ({ ok: false, error: "entryPoints must be an object" });

    var ep = manifest.entryPoints;
    var hasBar = _entryPathValid(ep.barWidget);
    var hasDesktop = _entryPathValid(ep.desktopWidget);
    var hasLauncher = _entryPathValid(ep.launcherProvider);
    var hasDaemon = _entryPathValid(ep.daemon);
    var hasSettings = ep.settings === undefined ? false : _entryPathValid(ep.settings);

    if (ep.settings !== undefined && !hasSettings)
      return ({ ok: false, error: "entryPoints.settings must be a .qml path" });

    if (typeName === "bar-widget" && !hasBar)
      return ({ ok: false, error: "bar-widget type requires entryPoints.barWidget" });
    if (typeName === "desktop-widget" && !hasDesktop)
      return ({ ok: false, error: "desktop-widget type requires entryPoints.desktopWidget" });
    if (typeName === "launcher-provider" && !hasLauncher)
      return ({ ok: false, error: "launcher-provider type requires entryPoints.launcherProvider" });
    if (typeName === "daemon" && !hasDaemon)
      return ({ ok: false, error: "daemon type requires entryPoints.daemon" });
    if (typeName === "multi" && !hasBar && !hasDesktop && !hasLauncher && !hasDaemon)
      return ({ ok: false, error: "multi type requires at least one runtime entry point" });

    if (!Array.isArray(manifest.permissions))
      return ({ ok: false, error: "permissions must be an array" });
    for (var pIdx = 0; pIdx < manifest.permissions.length; ++pIdx) {
      var pName = String(manifest.permissions[pIdx] || "").trim();
      if (pName === "" || !_isValidPermission(pName))
        return ({ ok: false, error: "invalid permission: " + pName });
    }

    var normalized = {
      id: pluginId,
      name: String(manifest.name || pluginId),
      description: String(manifest.description || ""),
      author: String(manifest.author || "Unknown"),
      version: String(manifest.version || "0.0.0"),
      type: typeName,
      path: String(pluginPath || ""),
      permissions: _normalizePermissions(manifest.permissions),
      metadata: manifest.metadata && typeof manifest.metadata === "object" ? manifest.metadata : ({ }),
      launcher: manifest.launcher && typeof manifest.launcher === "object" ? manifest.launcher : ({ }),
      entryPoints: {
        barWidget: hasBar ? String(ep.barWidget) : "",
        desktopWidget: hasDesktop ? String(ep.desktopWidget) : "",
        launcherProvider: hasLauncher ? String(ep.launcherProvider) : "",
        daemon: hasDaemon ? String(ep.daemon) : "",
        settings: hasSettings ? String(ep.settings) : ""
      }
    };

    return ({ ok: true, manifest: normalized });
  }

  function _pluginRuntimeFingerprint(plugin) {
    return String(plugin.fingerprint || "");
  }

  function _refreshEnabledStates() {
    var disabledList = Config.disabledPlugins || [];
    var updated = [];
    var index = ({});
    for (var i = 0; i < plugins.length; ++i) {
      var current = plugins[i];
      var nextPlugin = Object.assign({}, current, {
        enabled: disabledList.indexOf(current.id) === -1
      });
      updated.push(nextPlugin);
      index[nextPlugin.id] = nextPlugin;
    }
    plugins = updated;
    pluginIndex = index;
    _refreshRuntime();
    pluginCatalogChanged();
  }

  function _applyScannedPlugins(nextPlugins, nextErrors) {
    var disabledList = Config.disabledPlugins || [];
    var nextFingerprints = Object.assign({}, pluginFingerprints);
    var nextList = [];
    var nextIndex = ({});

    for (var i = 0; i < nextPlugins.length; ++i) {
      var plugin = Object.assign({}, nextPlugins[i]);
      plugin.enabled = disabledList.indexOf(plugin.id) === -1;
      nextList.push(plugin);
      nextIndex[plugin.id] = plugin;

      var previous = pluginFingerprints[plugin.id];
      var currentFingerprint = _pluginRuntimeFingerprint(plugin);
      nextFingerprints[plugin.id] = currentFingerprint;

      if (previous !== undefined && previous !== currentFingerprint) {
        // Reload runtime-managed plugin components when files change.
        _destroyDaemon(plugin.id);
        _destroyLauncherProvider(plugin.id);
      }
    }

    // Unload removed plugins.
    for (var existingId in pluginFingerprints) {
      if (!nextIndex[existingId]) {
        _destroyDaemon(existingId);
        _destroyLauncherProvider(existingId);
        delete nextFingerprints[existingId];
      }
    }

    plugins = nextList;
    pluginIndex = nextIndex;
    pluginErrors = nextErrors;
    pluginFingerprints = nextFingerprints;

    _refreshRuntime();
    pluginCatalogChanged();
  }

  function launcherTriggerForPlugin(pluginId) {
    var plugin = pluginById(pluginId);
    if (!plugin)
      return "";
    var configured = Config.pluginLauncherTriggers || ({ });
    if (configured[pluginId] !== undefined)
      return String(configured[pluginId] || "");
    return String(plugin.launcher && plugin.launcher.trigger !== undefined ? plugin.launcher.trigger : "");
  }

  function launcherNoTriggerForPlugin(pluginId) {
    var plugin = pluginById(pluginId);
    if (!plugin)
      return false;
    var configured = Config.pluginLauncherNoTrigger || ({ });
    if (configured[pluginId] !== undefined)
      return configured[pluginId] === true;
    return plugin.launcher && plugin.launcher.noTrigger === true;
  }

  function _matchTriggeredProvider(text) {
    var raw = String(text || "");
    if (raw === "")
      return ({ pluginId: "", trigger: "", query: "" });

    var providers = launcherPlugins;
    var best = ({ pluginId: "", trigger: "", query: "" });
    for (var i = 0; i < providers.length; ++i) {
      var plugin = providers[i];
      var trigger = launcherTriggerForPlugin(plugin.id);
      if (trigger === "")
        continue;
      if (raw.indexOf(trigger) !== 0)
        continue;
      if (trigger.length > best.trigger.length) {
        best.pluginId = plugin.id;
        best.trigger = trigger;
        best.query = raw.substring(trigger.length).trim();
      }
    }
    return best;
  }

  function shouldOpenPluginsModeForQuery(text) {
    return _matchTriggeredProvider(text).pluginId !== "";
  }

  function getLauncherProviders() {
    return launcherPlugins.slice();
  }

  function _normalizeLauncherItem(item, plugin) {
    if (!item || typeof item !== "object")
      return null;
    var normalized = {
      pluginId: plugin.id,
      pluginName: plugin.name,
      name: String(item.name || item.title || "Untitled"),
      title: String(item.title || ""),
      description: String(item.description || ""),
      icon: String(item.icon || "󰏗"),
      score: Number(item.score || 0),
      data: item.data !== undefined ? item.data : null,
      exec: item.exec !== undefined ? item.exec : "",
      action: item.action !== undefined ? item.action : null,
      pluginItem: true,
      _providerItem: item
    };
    return normalized;
  }

  function queryLauncherItems(text, pluginsMode) {
    var raw = String(text || "");
    var triggered = _matchTriggeredProvider(raw);
    var query = triggered.pluginId !== "" ? triggered.query : raw.trim();
    var providers = launcherPlugins;
    var out = [];

    for (var i = 0; i < providers.length; ++i) {
      var plugin = providers[i];
      var providerId = plugin.id;
      var instance = launcherProviderInstances[providerId];
      if (!instance || typeof instance.items !== "function")
        continue;

      if (triggered.pluginId !== "" && providerId !== triggered.pluginId)
        continue;

      if (!pluginsMode && triggered.pluginId === "" && !launcherNoTriggerForPlugin(providerId))
        continue;

      try {
        var response = instance.items(query, {
          mode: pluginsMode ? "plugins" : "search",
          triggered: triggered.pluginId !== "",
          trigger: triggered.trigger,
          pluginId: providerId
        });

        if (!Array.isArray(response))
          continue;

        for (var j = 0; j < response.length; ++j) {
          var normalized = _normalizeLauncherItem(response[j], plugin);
          if (normalized)
            out.push(normalized);
        }
      } catch (e) {
        console.warn("PluginService: launcher provider error", providerId, e);
      }
    }

    return out;
  }

  function executeLauncherItem(item, queryText) {
    if (!item || !item.pluginId)
      return false;
    var provider = launcherProviderInstances[item.pluginId];
    if (!provider)
      return false;

    if (typeof provider.execute === "function") {
      try {
        return provider.execute(item._providerItem || item, {
          query: String(queryText || ""),
          pluginId: item.pluginId
        }) !== false;
      } catch (e) {
        console.warn("PluginService: launcher execute failed", item.pluginId, e);
        return false;
      }
    }

    if (item.exec && String(item.exec) !== "") {
      Quickshell.execDetached(["bash", "-lc", String(item.exec)]);
      return true;
    }

    if (typeof item.action === "function") {
      try {
        item.action();
        return true;
      } catch (err) {
        console.warn("PluginService: launcher action failed", err);
      }
    }

    return false;
  }

  property Process scanProc: Process {
    id: scanProc
    command: [
      "sh", "-c",
      "PLUGINS_DIR=" + root.pluginsDir + "; "
      + "for d in \"$PLUGINS_DIR\"/*/; do "
      + "[ -d \"$d\" ] || continue; "
      + "[ -f \"$d/manifest.json\" ] || continue; "
      + "manifest=$(jq -c . \"$d/manifest.json\" 2>/dev/null) || continue; "
      + "fingerprint=$(find \"$d\" -type f -printf '%P:%T@\\n' 2>/dev/null | sort | sha256sum | cut -d' ' -f1); "
      + "printf '{\"path\":%s,\"fingerprint\":%s,\"manifest\":%s}\\n' \"$(printf %s \"$d\" | jq -Rsa .)\" \"$(printf %s \"$fingerprint\" | jq -Rsa .)\" \"$manifest\"; "
      + "done 2>/dev/null"
    ]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n").filter(function(l) {
          return l.length > 0;
        });

        var loaded = [];
        var errors = ({});
        var seen = ({});

        for (var i = 0; i < lines.length; ++i) {
          try {
            var payload = JSON.parse(lines[i]);
            var pluginPath = String(payload.path || "");
            var manifest = payload.manifest;
            var validation = root._validateManifest(manifest, pluginPath);
            if (!validation.ok) {
              var badId = manifest && manifest.id ? String(manifest.id) : "plugin-" + i;
              errors[badId] = validation.error;
              continue;
            }

            var normalized = validation.manifest;
            if (seen[normalized.id]) {
              errors[normalized.id] = "duplicate plugin id";
              continue;
            }
            seen[normalized.id] = true;
            normalized.fingerprint = String(payload.fingerprint || "");
            loaded.push(normalized);
          } catch (e) {
            // Ignore malformed scan line.
          }
        }

        root._applyScannedPlugins(loaded, errors);
      }
    }
  }

  property Component stateReaderComponent: Component {
    FileView {
      blockLoading: true
      printErrors: false
    }
  }

  property Component stateWriterComponent: Component {
    FileView {
      blockWrites: true
      atomicWrites: true
      printErrors: false
    }
  }

  property Component ensureStateDirProcComponent: Component {
    Process {
      running: false
    }
  }

  property Connections _configConn: Connections {
    target: Config
    function onDisabledPluginsChanged() { root._refreshEnabledStates(); }
    function onPluginLauncherTriggersChanged() { root.pluginRuntimeChanged(); }
    function onPluginLauncherNoTriggerChanged() { root.pluginRuntimeChanged(); }
  }

  Timer {
    id: hotReloadTimer
    interval: 2200
    repeat: true
    running: Config.pluginHotReload === true
    onTriggered: root.scanPlugins()
  }

  Component.onCompleted: {
    Qt.callLater(function() { root.scanPlugins(); });
  }
}
