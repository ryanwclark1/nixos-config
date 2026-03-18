import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: rt
  default property list<QtObject> _data

  required property var service  // parent PluginService singleton

  // ── Runtime state ───────────────────────────
  property var daemonComponents: ({})
  property var daemonInstances: ({})
  property var launcherProviderComponents: ({})
  property var launcherProviderInstances: ({})
  property var pluginApis: ({})

  // ── State persistence ───────────────────────

  function _ensurePluginStateDir(pluginId) {
    var dir = service.pluginsDir + "/" + pluginId;
    var proc = ensureStateDirProcComponent.createObject(rt);
    proc.command = ["mkdir", "-p", dir];
    proc.running = true;
    proc.exited.connect(function() {
      proc.destroy();
    });
  }

  function _statePath(pluginId) {
    return service.pluginsDir + "/" + pluginId + "/state.json";
  }

  function _normalizeStateEnvelope(raw) {
    if (raw && typeof raw === "object" && raw.payload !== undefined) {
      return {
        stateVersion: Number(raw.stateVersion || 1),
        updatedAt: String(raw.updatedAt || ""),
        payload: raw.payload && typeof raw.payload === "object" ? raw.payload : ({})
      };
    }
    if (raw && typeof raw === "object") {
      return {
        stateVersion: 1,
        updatedAt: "",
        payload: raw
      };
    }
    return {
      stateVersion: 1,
      updatedAt: "",
      payload: ({})
    };
  }

  function _readStateEnvelope(pathValue) {
    var fv = rt.stateReaderComponent.createObject(rt, { path: pathValue });
    var envelope = _normalizeStateEnvelope(({ }));
    try {
      var raw = fv.text();
      if (raw && String(raw).trim() !== "")
        envelope = _normalizeStateEnvelope(JSON.parse(raw));
    } catch (e) {
      console.warn("PluginService: state parse error:", e);
    }
    fv.destroy();
    return envelope;
  }

  function _writeStateEnvelope(pathValue, envelope) {
    var writer = rt.stateWriterComponent.createObject(rt, { path: pathValue });
    writer.setText(JSON.stringify({
      stateVersion: Number(envelope.stateVersion || 1),
      updatedAt: String(envelope.updatedAt || new Date().toISOString()),
      payload: envelope.payload && typeof envelope.payload === "object" ? envelope.payload : ({})
    }, null, 2));
    writer.destroy();
    return true;
  }

  // ── Plugin API builder ──────────────────────

  function _buildPluginApi(plugin) {
    var pluginId = plugin.id;
    var stateFilePath = _statePath(pluginId);

    return {
      id: pluginId,
      hasPermission: function(permission) {
        return service._hasPermission(plugin, permission);
      },
      loadSetting: function(key, defaultValue) {
        if (!service._hasPermission(plugin, "settings_read"))
          return defaultValue;
        var settings = Config.pluginSettings || ({ });
        var pluginSettings = settings[pluginId] || ({ });
        return pluginSettings[key] !== undefined ? pluginSettings[key] : defaultValue;
      },
      saveSetting: function(key, value) {
        if (!service._hasPermission(plugin, "settings_write"))
          return service._rejectPermission(pluginId, "settings_write", "saveSetting");
        var settings = Object.assign({}, Config.pluginSettings || ({ }));
        var pluginSettings = Object.assign({}, settings[pluginId] || ({ }));
        pluginSettings[key] = value;
        settings[pluginId] = pluginSettings;
        Config.pluginSettings = settings;
        return true;
      },
      removeSetting: function(key) {
        if (!service._hasPermission(plugin, "settings_write"))
          return service._rejectPermission(pluginId, "settings_write", "removeSetting");
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
        if (!service._hasPermission(plugin, "state_read"))
          return ({ });
        return rt._readStateEnvelope(stateFilePath).payload;
      },
      saveState: function(data) {
        if (!service._hasPermission(plugin, "state_write"))
          return service._rejectPermission(pluginId, "state_write", "saveState");
        rt._ensurePluginStateDir(pluginId);
        return rt._writeStateEnvelope(stateFilePath, {
          stateVersion: Number(plugin.metadata && plugin.metadata.stateVersion || 1),
          updatedAt: new Date().toISOString(),
          payload: data && typeof data === "object" ? data : ({})
        });
      },
      loadStateEnvelope: function() {
        if (!service._hasPermission(plugin, "state_read"))
          return rt._normalizeStateEnvelope(({ }));
        return rt._readStateEnvelope(stateFilePath);
      },
      saveStateEnvelope: function(envelope) {
        if (!service._hasPermission(plugin, "state_write"))
          return service._rejectPermission(pluginId, "state_write", "saveStateEnvelope");
        rt._ensurePluginStateDir(pluginId);
        return rt._writeStateEnvelope(stateFilePath, rt._normalizeStateEnvelope(envelope));
      },
      migrateState: function(targetVersion, migrateFn) {
        if (!service._hasPermission(plugin, "state_read") || !service._hasPermission(plugin, "state_write"))
          return service._rejectPermission(pluginId, "state_write", "migrateState");
        if (typeof migrateFn !== "function")
          return false;
        var envelope = rt._readStateEnvelope(stateFilePath);
        var current = Number(envelope.stateVersion || 1);
        var target = Number(targetVersion || current);
        if (target <= current)
          return true;

        var payload = envelope.payload && typeof envelope.payload === "object" ? envelope.payload : ({});
        for (var ver = current + 1; ver <= target; ++ver) {
          var nextPayload = migrateFn(payload, ver, current);
          if (!nextPayload || typeof nextPayload !== "object")
            return false;
          payload = nextPayload;
        }

        rt._ensurePluginStateDir(pluginId);
        return rt._writeStateEnvelope(stateFilePath, {
          stateVersion: target,
          updatedAt: new Date().toISOString(),
          payload: payload
        });
      },
      runProcess: function(commandArray) {
        if (!service._hasPermission(plugin, "process"))
          return service._rejectPermission(pluginId, "process", "runProcess");
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

  // ── Launcher provider lifecycle ─────────────

  function _instantiateLauncherProvider(plugin) {
    var providerPath = _buildPluginPath(plugin, "launcherProvider");
    if (providerPath === "")
      return;

    var component = Qt.createComponent("file://" + providerPath);
    if (component.status !== Component.Ready) {
      console.warn("PluginService: Failed to load launcher provider", plugin.id, component.errorString());
      service._setPluginStatus(plugin.id, "failed", "E_LAUNCHER_COMPONENT_LOAD", component.errorString());
      return;
    }

    var api = pluginApis[plugin.id] || _buildPluginApi(plugin);
    var instance = component.createObject(rt, {
      pluginApi: api,
      pluginManifest: plugin,
      pluginService: service
    });
    if (!instance) {
      console.warn("PluginService: Failed to instantiate launcher provider", plugin.id, component.errorString());
      service._setPluginStatus(plugin.id, "failed", "E_LAUNCHER_INSTANCE_CREATE", component.errorString());
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
    service._setPluginStatus(plugin.id, "active", "", "");
  }

  function _destroyLauncherProvider(pluginId) {
    var pid = String(pluginId || "");

    if (launcherProviderInstances[pid]) {
      try {
        if (launcherProviderInstances[pid].shutdown)
          launcherProviderInstances[pid].shutdown();
      } catch (e) {
        console.warn("PluginService: shutdown error:", pid, e);
      }
      launcherProviderInstances[pid].destroy();
    }

    var instances = Object.assign({}, launcherProviderInstances);
    var components = Object.assign({}, launcherProviderComponents);
    delete instances[pid];
    delete components[pid];
    launcherProviderInstances = instances;
    launcherProviderComponents = components;

    var plugin = service.pluginById(pid);
    if (!plugin)
      service._removePluginStatus(pid);
    else if (plugin.enabled)
      service._setPluginStatus(pid, "enabled", "", "");
    else
      service._setPluginStatus(pid, "disabled", "", "");
  }

  // ── Daemon lifecycle ────────────────────────

  function _instantiateDaemon(plugin) {
    var daemonPath = _buildPluginPath(plugin, "daemon");
    if (daemonPath === "")
      return;

    var component = Qt.createComponent("file://" + daemonPath);
    if (component.status !== Component.Ready) {
      console.warn("PluginService: Failed to load daemon", plugin.id, component.errorString());
      service._setPluginStatus(plugin.id, "failed", "E_DAEMON_COMPONENT_LOAD", component.errorString());
      return;
    }

    var api = pluginApis[plugin.id] || _buildPluginApi(plugin);
    var instance = component.createObject(rt, {
      pluginApi: api,
      pluginManifest: plugin,
      pluginService: service
    });
    if (!instance) {
      console.warn("PluginService: Failed to instantiate daemon", plugin.id, component.errorString());
      service._setPluginStatus(plugin.id, "failed", "E_DAEMON_INSTANCE_CREATE", component.errorString());
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
    service._setPluginStatus(plugin.id, "active", "", "");

    try {
      if (instance.start)
        instance.start();
    } catch (e) {
      service._setPluginStatus(plugin.id, "failed", "E_DAEMON_START", String(e));
    }
  }

  function _destroyDaemon(pluginId) {
    var pid = String(pluginId || "");

    if (daemonInstances[pid]) {
      try {
        if (daemonInstances[pid].stop)
          daemonInstances[pid].stop();
      } catch (e) {
        console.warn("PluginService: daemon stop error:", pid, e);
      }
      daemonInstances[pid].destroy();
    }

    var instances = Object.assign({}, daemonInstances);
    var components = Object.assign({}, daemonComponents);
    delete instances[pid];
    delete components[pid];
    daemonInstances = instances;
    daemonComponents = components;

    var plugin = service.pluginById(pid);
    if (!plugin)
      service._removePluginStatus(pid);
    else if (plugin.enabled)
      service._setPluginStatus(pid, "enabled", "", "");
    else
      service._setPluginStatus(pid, "disabled", "", "");
  }

  // ── Runtime refresh ─────────────────────────

  function refreshRuntime() {
    var nextApis = ({});
    var enabledPlugins = service.plugins || [];
    for (var p = 0; p < enabledPlugins.length; ++p) {
      var ap = enabledPlugins[p];
      if (ap && ap.enabled) {
        nextApis[ap.id] = pluginApis[ap.id] || _buildPluginApi(ap);
        service._setPluginStatus(ap.id, "enabled", "", "");
      } else if (ap) {
        service._setPluginStatus(ap.id, "disabled", "", "");
      }
    }
    pluginApis = nextApis;

    var daemonKeys = Object.keys(daemonInstances);
    for (var di = 0; di < daemonKeys.length; ++di) {
      var activeDaemonId = daemonKeys[di];
      var activeDaemon = service.pluginById(activeDaemonId);
      if (!activeDaemon || !activeDaemon.enabled || !activeDaemon.entryPoints || !activeDaemon.entryPoints.daemon)
        _destroyDaemon(activeDaemonId);
    }

    var providerKeys = Object.keys(launcherProviderInstances);
    for (var pi = 0; pi < providerKeys.length; ++pi) {
      var activeProviderId = providerKeys[pi];
      var activeProvider = service.pluginById(activeProviderId);
      if (!activeProvider || !activeProvider.enabled || !activeProvider.entryPoints || !activeProvider.entryPoints.launcherProvider)
        _destroyLauncherProvider(activeProviderId);
    }

    var daemons = service.daemonPlugins;
    for (var i = 0; i < daemons.length; ++i) {
      if (!daemonInstances[daemons[i].id])
        _instantiateDaemon(daemons[i]);
    }

    var launchers = service.launcherPlugins;
    for (var j = 0; j < launchers.length; ++j) {
      if (!launcherProviderInstances[launchers[j].id])
        _instantiateLauncherProvider(launchers[j]);
    }

    service.pluginRuntimeUpdated();
  }

  // ── Launcher integration ────────────────────

  function launcherTriggerForPlugin(pluginId) {
    var plugin = service.pluginById(pluginId);
    if (!plugin)
      return "";
    var configured = Config.pluginLauncherTriggers || ({ });
    if (configured[pluginId] !== undefined)
      return String(configured[pluginId] || "");
    return String(plugin.launcher && plugin.launcher.trigger !== undefined ? plugin.launcher.trigger : "");
  }

  function launcherNoTriggerForPlugin(pluginId) {
    var plugin = service.pluginById(pluginId);
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

    var providers = service.launcherPlugins;
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
    return service.launcherPlugins.slice();
  }

  function _normalizeLauncherItem(item, plugin) {
    if (!item || typeof item !== "object")
      return null;
    var name = String(item.name || item.title || "").trim();
    if (name === "")
      return null;
    var score = Number(item.score);
    if (!isFinite(score))
      score = 0;
    var normalized = {
      pluginId: plugin.id,
      pluginName: plugin.name,
      name: name,
      title: String(item.title || ""),
      description: String(item.description || ""),
      icon: String(item.icon || "󰏗"),
      score: score,
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
    var providers = service.launcherPlugins;
    var out = [];
    var dedupe = ({});
    var maxItemsPerProvider = 60;

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

        service._setPluginStatus(providerId, "active", "", "");

        for (var j = 0; j < response.length && j < maxItemsPerProvider; ++j) {
          var normalized = _normalizeLauncherItem(response[j], plugin);
          if (normalized) {
            var dedupeKey = providerId + "::" + normalized.name + "::" + String(normalized.exec || "");
            if (dedupe[dedupeKey])
              continue;
            dedupe[dedupeKey] = true;
            out.push(normalized);
          }
        }
      } catch (e) {
        console.warn("PluginService: launcher provider error", providerId, e);
        service._setPluginStatus(providerId, "degraded", "E_LAUNCHER_QUERY", String(e));
      }
    }

    out.sort(function(a, b) {
      var as = Number(a.score || 0);
      var bs = Number(b.score || 0);
      if (bs !== as)
        return bs - as;
      return String(a.name || "").localeCompare(String(b.name || ""));
    });

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
        service._setPluginStatus(item.pluginId, "degraded", "E_LAUNCHER_EXECUTE", String(e));
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
        service._setPluginStatus(item.pluginId, "degraded", "E_LAUNCHER_ACTION", String(err));
      }
    }

    return false;
  }

  // ── Internal components ─────────────────────

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
}
