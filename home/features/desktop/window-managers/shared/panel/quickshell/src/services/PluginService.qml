pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property bool _destroyed: false

    readonly property string pluginsDir: Quickshell.env("HOME") + "/.config/quickshell/plugins"

    // Full list of discovered plugins (enabled + disabled).
    property var plugins: []
    property var pluginIndex: ({})
    property var pluginErrors: ({})
    property var pluginStatuses: ({})

    // Fingerprints for hot-reload detection.
    property var pluginFingerprints: ({})

    // ── Runtime delegate ────────────────────────
    property PluginRuntime _rt: PluginRuntime {
        id: runtimeDelegate
        service: root
    }

    // Runtime state facades (expose _rt properties at the service level)
    readonly property var daemonComponents: runtimeDelegate.daemonComponents
    readonly property var daemonInstances: runtimeDelegate.daemonInstances
    readonly property var launcherProviderComponents: runtimeDelegate.launcherProviderComponents
    readonly property var launcherProviderInstances: runtimeDelegate.launcherProviderInstances
    readonly property var pluginApis: runtimeDelegate.pluginApis

    function _filterByEntryPoint(key) {
        var result = [];
        for (var i = 0; i < plugins.length; ++i) {
            var p = plugins[i];
            if (p.enabled && p.entryPoints && p.entryPoints[key])
                result.push(p);
        }
        return result;
    }

    readonly property var barPlugins: root._filterByEntryPoint("barWidget")
    readonly property var desktopPlugins: root._filterByEntryPoint("desktopWidget")
    readonly property var launcherPlugins: root._filterByEntryPoint("launcherProvider")
    readonly property var daemonPlugins: root._filterByEntryPoint("daemon")
    readonly property var controlCenterPlugins: root._filterByEntryPoint("controlCenterWidget")

    property var _visibleControlCenterPlugins: []
    readonly property alias visibleControlCenterPlugins: root._visibleControlCenterPlugins

    function _refreshVisibleControlCenterPlugins() {
        if (!Config) return;
        var hidden = Array.isArray(Config.controlCenterHiddenPlugins) ? Config.controlCenterHiddenPlugins : [];
        var order = Array.isArray(Config.controlCenterPluginOrder) ? Config.controlCenterPluginOrder : [];
        var catalog = root.controlCenterPlugins;
        var byId = ({});
        var seen = ({});
        var result = [];
        var i;

        for (i = 0; i < catalog.length; ++i)
            byId[catalog[i].id] = catalog[i];

        for (i = 0; i < order.length; ++i) {
            var orderedId = String(order[i] || "");
            if (!byId[orderedId] || seen[orderedId] || hidden.indexOf(orderedId) !== -1)
                continue;
            seen[orderedId] = true;
            result.push(byId[orderedId]);
        }

        for (i = 0; i < catalog.length; ++i) {
            var plugin = catalog[i];
            if (seen[plugin.id] || hidden.indexOf(plugin.id) !== -1)
                continue;
            seen[plugin.id] = true;
            result.push(plugin);
        }

        root._visibleControlCenterPlugins = result;
    }

    signal pluginCatalogUpdated
    signal pluginRuntimeUpdated

    // ── Status management ───────────────────────

    function _setPluginStatus(pluginId, state, code, message) {
        var id = String(pluginId || "");
        if (id === "")
            return;
        var current = pluginStatuses[id] || ({});
        var next = Object.assign({}, pluginStatuses);
        var hasCode = arguments.length >= 3;
        var hasMessage = arguments.length >= 4;
        next[id] = {
            state: String(state || current.state || "unknown"),
            code: hasCode ? String(code ?? "") : String(current.code || ""),
            message: hasMessage ? String(message ?? "") : String(current.message || ""),
            updatedAt: new Date().toISOString()
        };
        pluginStatuses = next;
    }

    function _removePluginStatus(pluginId) {
        var id = String(pluginId || "");
        if (id === "" || pluginStatuses[id] === undefined)
            return;
        var next = Object.assign({}, pluginStatuses);
        delete next[id];
        pluginStatuses = next;
    }

    function _errorEntry(code, message) {
        return ({
                code: String(code || ""),
                message: String(message || "")
            });
    }

    // ── Plugin lookup ───────────────────────────

    function scanPlugins() {
        scanProc.running = true;
    }

    function pluginById(pluginId) {
        return pluginIndex[String(pluginId || "")] || null;
    }

    function getPluginAPI(pluginId) {
        return _rt.pluginApis[String(pluginId || "")] || null;
    }

    function pluginSupportsSettings(pluginId) {
        var plugin = pluginById(pluginId);
        return !!(plugin && plugin.entryPoints && String(plugin.entryPoints.settings || "") !== "");
    }

    function pluginSupportsControlCenterDetail(pluginId) {
        var plugin = pluginById(pluginId);
        return !!(plugin && plugin.entryPoints && String(plugin.entryPoints.controlCenterDetail || "") !== "");
    }

    function pluginSettingsSource(pluginId) {
        var plugin = pluginById(pluginId);
        if (!plugin || !plugin.entryPoints)
            return "";
        var rel = String(plugin.entryPoints.settings || "");
        if (rel === "")
            return "";
        return "file://" + String(plugin.path || "") + rel;
    }

    function pluginControlCenterDetailSource(pluginId) {
        var plugin = pluginById(pluginId);
        if (!plugin || !plugin.entryPoints)
            return "";
        var rel = String(plugin.entryPoints.controlCenterDetail || "");
        if (rel === "")
            return "";
        return "file://" + String(plugin.path || "") + rel;
    }

    function pluginCanWriteSettings(pluginId) {
        var plugin = pluginById(pluginId);
        if (!plugin)
            return false;
        return _hasPermission(plugin, "settings_write");
    }

    // ── Enable / disable ───────────────────────

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

    // ── Permission helpers ──────────────────────

    function _isValidPermission(permission) {
        return permission === "settings_read" || permission === "settings_write" || permission === "state_read" || permission === "state_write" || permission === "process";
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
        Logger.w("PluginService", "Permission denied for", pluginId, "permission=", permission, "operation=", operation);
        return false;
    }

    // ── Manifest validation ─────────────────────

    function _typeValid(typeName) {
        return typeName === "bar-widget" || typeName === "desktop-widget" || typeName === "launcher-provider" || typeName === "control-center-widget" || typeName === "daemon" || typeName === "multi";
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
            return ({
                    ok: false,
                    error: "manifest must be an object"
                });

        var required = ["id", "name", "description", "author", "version", "type", "entryPoints", "permissions"];
        for (var i = 0; i < required.length; ++i) {
            var key = required[i];
            if (manifest[key] === undefined)
                return ({
                        ok: false,
                        error: "missing required field: " + key
                    });
        }

        var pluginId = String(manifest.id || "");
        if (!pluginId.match(/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/))
            return ({
                    ok: false,
                    error: "id must be filesystem-safe"
                });

        var typeName = String(manifest.type || "");
        if (!_typeValid(typeName))
            return ({
                    ok: false,
                    error: "invalid type: " + typeName
                });

        if (!manifest.entryPoints || typeof manifest.entryPoints !== "object")
            return ({
                    ok: false,
                    error: "entryPoints must be an object"
                });

        var ep = manifest.entryPoints;
        var hasBar = _entryPathValid(ep.barWidget);
        var hasDesktop = _entryPathValid(ep.desktopWidget);
        var hasLauncher = _entryPathValid(ep.launcherProvider);
        var hasControlCenter = _entryPathValid(ep.controlCenterWidget);
        var hasControlCenterDetail = ep.controlCenterDetail === undefined ? false : _entryPathValid(ep.controlCenterDetail);
        var hasDaemon = _entryPathValid(ep.daemon);
        var hasSettings = ep.settings === undefined ? false : _entryPathValid(ep.settings);

        if (ep.settings !== undefined && !hasSettings)
            return ({
                    ok: false,
                    error: "entryPoints.settings must be a .qml path"
                });
        if (ep.controlCenterDetail !== undefined && !hasControlCenterDetail)
            return ({
                    ok: false,
                    error: "entryPoints.controlCenterDetail must be a .qml path"
                });

        if (typeName === "bar-widget" && !hasBar)
            return ({
                    ok: false,
                    error: "bar-widget type requires entryPoints.barWidget"
                });
        if (typeName === "desktop-widget" && !hasDesktop)
            return ({
                    ok: false,
                    error: "desktop-widget type requires entryPoints.desktopWidget"
                });
        if (typeName === "launcher-provider" && !hasLauncher)
            return ({
                    ok: false,
                    error: "launcher-provider type requires entryPoints.launcherProvider"
                });
        if (typeName === "control-center-widget" && !hasControlCenter)
            return ({
                    ok: false,
                    error: "control-center-widget type requires entryPoints.controlCenterWidget"
                });
        if (typeName === "daemon" && !hasDaemon)
            return ({
                    ok: false,
                    error: "daemon type requires entryPoints.daemon"
                });
        if (typeName === "multi" && !hasBar && !hasDesktop && !hasLauncher && !hasControlCenter && !hasDaemon)
            return ({
                    ok: false,
                    error: "multi type requires at least one runtime entry point"
                });

        if (!Array.isArray(manifest.permissions))
            return ({
                    ok: false,
                    error: "permissions must be an array"
                });
        for (var pIdx = 0; pIdx < manifest.permissions.length; ++pIdx) {
            var pName = String(manifest.permissions[pIdx] || "").trim();
            if (pName === "" || !_isValidPermission(pName))
                return ({
                        ok: false,
                        error: "invalid permission: " + pName
                    });
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
            metadata: manifest.metadata && typeof manifest.metadata === "object" ? manifest.metadata : ({}),
            launcher: manifest.launcher && typeof manifest.launcher === "object" ? manifest.launcher : ({}),
            entryPoints: {
                barWidget: hasBar ? String(ep.barWidget) : "",
                desktopWidget: hasDesktop ? String(ep.desktopWidget) : "",
                launcherProvider: hasLauncher ? String(ep.launcherProvider) : "",
                controlCenterWidget: hasControlCenter ? String(ep.controlCenterWidget) : "",
                controlCenterDetail: hasControlCenterDetail ? String(ep.controlCenterDetail) : "",
                daemon: hasDaemon ? String(ep.daemon) : "",
                settings: hasSettings ? String(ep.settings) : ""
            }
        };

        return ({
                ok: true,
                manifest: normalized
            });
    }

    // ── Catalog management ──────────────────────

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
        _rt.refreshRuntime();
        pluginCatalogUpdated();
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
            _setPluginStatus(plugin.id, plugin.enabled ? "enabled" : "disabled", "", "");

            var previous = pluginFingerprints[plugin.id];
            var currentFingerprint = _pluginRuntimeFingerprint(plugin);
            nextFingerprints[plugin.id] = currentFingerprint;

            if (previous !== undefined && previous !== currentFingerprint) {
                _rt._destroyDaemon(plugin.id);
                _rt._destroyLauncherProvider(plugin.id);
            }
        }

        for (var existingId in pluginFingerprints) {
            if (!nextIndex[existingId]) {
                _rt._destroyDaemon(existingId);
                _rt._destroyLauncherProvider(existingId);
                delete nextFingerprints[existingId];
            }
        }

        for (var errorId in nextErrors) {
            var entry = nextErrors[errorId];
            _setPluginStatus(errorId, "failed", String(entry && entry.code || "E_SCAN"), String(entry && entry.message || "scan failure"));
        }

        var statusKeys = Object.keys(pluginStatuses || ({}));
        for (var k = 0; k < statusKeys.length; ++k) {
            var statusId = statusKeys[k];
            if (!nextIndex[statusId] && !nextErrors[statusId])
                _removePluginStatus(statusId);
        }

        plugins = nextList;
        pluginIndex = nextIndex;
        pluginErrors = nextErrors;
        pluginFingerprints = nextFingerprints;

        _rt.refreshRuntime();
        pluginCatalogUpdated();
    }

    // ── Runtime facade delegates ────────────────

    function launcherTriggerForPlugin(pluginId) {
        return _rt.launcherTriggerForPlugin(pluginId);
    }
    function launcherNoTriggerForPlugin(pluginId) {
        return _rt.launcherNoTriggerForPlugin(pluginId);
    }
    function shouldOpenPluginsModeForQuery(text) {
        return _rt.shouldOpenPluginsModeForQuery(text);
    }
    function getLauncherProviders() {
        return _rt.getLauncherProviders();
    }
    function queryLauncherItems(text, pluginsMode) {
        return _rt.queryLauncherItems(text, pluginsMode);
    }
    function executeLauncherItem(item, queryText) {
        return _rt.executeLauncherItem(item, queryText);
    }

    // ── Scan process ────────────────────────────

    property Process scanProc: Process {
        id: scanProc
        command: ["sh", "-c", "PLUGINS_DIR=\"$1\"; " + "for d in \"$PLUGINS_DIR\"/*/; do " + "[ -d \"$d\" ] || continue; " + "[ -f \"$d/manifest.json\" ] || continue; " + "manifest=$(jq -c . \"$d/manifest.json\" 2>/dev/null) || continue; " + "fingerprint=$(find \"$d\" -type f -printf '%P:%T@\\n' 2>/dev/null | sort | sha256sum | cut -d' ' -f1); " + "printf '{\"path\":%s,\"fingerprint\":%s,\"manifest\":%s}\\n' \"$(printf %s \"$d\" | jq -Rsa .)\" \"$(printf %s \"$fingerprint\" | jq -Rsa .)\" \"$manifest\"; " + "done 2>/dev/null", "sh", root.pluginsDir]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (this.text || "").trim().split("\n").filter(function (l) {
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
                        if (manifest && manifest.id)
                            root._setPluginStatus(String(manifest.id), "discovered", "", "");
                        var validation = root._validateManifest(manifest, pluginPath);
                        if (!validation.ok) {
                            var badId = manifest && manifest.id ? String(manifest.id) : "plugin-" + i;
                            errors[badId] = root._errorEntry("E_MANIFEST_VALIDATION", validation.error);
                            root._setPluginStatus(badId, "failed", "E_MANIFEST_VALIDATION", validation.error);
                            continue;
                        }

                        var normalized = validation.manifest;
                        root._setPluginStatus(normalized.id, "validated", "", "");
                        if (seen[normalized.id]) {
                            errors[normalized.id] = root._errorEntry("E_DUPLICATE_PLUGIN_ID", "duplicate plugin id");
                            root._setPluginStatus(normalized.id, "failed", "E_DUPLICATE_PLUGIN_ID", "duplicate plugin id");
                            continue;
                        }
                        seen[normalized.id] = true;
                        normalized.fingerprint = String(payload.fingerprint || "");
                        loaded.push(normalized);
                    } catch (e) {
                        errors["scan-line-" + i] = root._errorEntry("E_SCAN_LINE_PARSE", "malformed scan output");
                        root._setPluginStatus("scan-line-" + i, "failed", "E_SCAN_LINE_PARSE", "malformed scan output");
                    }
                }

                root._applyScannedPlugins(loaded, errors);
            }
        }
    }

    property Connections _configConn: Connections {
        target: Config
        function onDisabledPluginsChanged() {
            root._refreshEnabledStates();
        }
        function onPluginLauncherTriggersChanged() {
            root.pluginRuntimeUpdated();
        }
        function onPluginLauncherNoTriggerChanged() {
            root.pluginRuntimeUpdated();
        }
        function onControlCenterHiddenPluginsChanged() {
            root._refreshVisibleControlCenterPlugins();
        }
        function onControlCenterPluginOrderChanged() {
            root._refreshVisibleControlCenterPlugins();
        }
    }

    property Timer hotReloadTimer: Timer {
        id: hotReloadTimer
        interval: 2200
        repeat: true
        running: Config && Config.pluginHotReload === true
        onTriggered: root.scanPlugins()
    }

    Component.onCompleted: {
        Qt.callLater(function () {
            if (root._destroyed) return;
            root._refreshVisibleControlCenterPlugins();
            root.scanPlugins();
        });
    }
    Component.onDestruction: _destroyed = true
}
