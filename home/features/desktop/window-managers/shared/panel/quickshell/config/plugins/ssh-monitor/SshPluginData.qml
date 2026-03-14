import QtQuick
import Quickshell
import Quickshell.Io
import "SshConfigParser.js" as SshConfigParser

QtObject {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null

    property var manualHosts: []
    property bool enableSshConfigImport: true
    property string displayMode: "count"
    property string defaultAction: "connect"

    property var importedHosts: []
    property var skippedPatternEntries: []
    property var importErrors: []
    property var mergedHosts: []
    property bool importReady: false
    property bool importBusy: false
    property string importRootPath: _expandHome("~/.ssh/config")

    property var stateEnvelope: ({
        stateVersion: 1,
        updatedAt: "",
        payload: {
            lastConnectedId: "",
            lastConnectedLabel: "",
            lastConnectedAt: "",
            recentIds: [],
            lastImportSummary: {
                imported: 0,
                skippedPatterns: 0,
                errors: 0
            }
        }
    })

    signal refreshed

    property var _pendingFiles: []
    property var _seenFiles: ({})
    property int _pendingIncludeExpansions: 0
    property var _importedAliasMap: ({})
    property var _skippedMap: ({})
    property var _errorList: []

    onPluginApiChanged: refresh()

    function _expandHome(pathValue) {
        var text = String(pathValue || "");
        if (text.indexOf("~/") === 0)
            return String(Quickshell.env("HOME") || "") + text.slice(1);
        return text;
    }

    function _shellQuote(text) {
        var value = String(text || "");
        return "'" + value.replace(/'/g, "'\"'\"'") + "'";
    }

    function _normalizeId(text, fallbackValue) {
        var value = String(text || "").trim().toLowerCase();
        if (value === "")
            value = String(fallbackValue || "").trim().toLowerCase();
        value = value.replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "");
        return value === "" ? "host-" + String(Date.now()) : value;
    }

    function _arrayClone(list) {
        return JSON.parse(JSON.stringify(Array.isArray(list) ? list : []));
    }

    function _tagsFromValue(value) {
        if (Array.isArray(value))
            return value.map(function(tag) { return String(tag || "").trim(); }).filter(function(tag) { return tag !== ""; });
        return String(value || "").split(",").map(function(tag) {
            return String(tag || "").trim();
        }).filter(function(tag) {
            return tag !== "";
        });
    }

    function _normalizeManualHost(raw, index) {
        var input = raw && typeof raw === "object" ? raw : ({});
        var label = String(input.label || input.alias || input.host || ("SSH Host " + String(index + 1))).trim();
        var host = String(input.host || "").trim();
        var user = String(input.user || "").trim();
        var portNumber = Number(input.port || 22);
        var port = isFinite(portNumber) && portNumber > 0 ? Math.round(portNumber) : 22;
        var normalized = {
            id: _normalizeId(input.id, label || host),
            label: label,
            host: host,
            user: user,
            port: port,
            remoteCommand: String(input.remoteCommand || input.command || "").trim(),
            tags: _tagsFromValue(input.tags),
            group: String(input.group || "").trim(),
            icon: String(input.icon || "󰣀").trim(),
            source: "manual",
            searchText: ""
        };
        normalized.searchText = [normalized.label, normalized.host, normalized.user, normalized.group].concat(normalized.tags).join(" ").toLowerCase();
        return normalized;
    }

    function _normalizeImportedHost(raw) {
        var input = raw && typeof raw === "object" ? raw : ({});
        var alias = String(input.alias || "").trim();
        var hostName = String(input.hostName || "").trim();
        var user = String(input.user || "").trim();
        var portNumber = Number(input.port || 22);
        return {
            id: _normalizeId(alias, alias),
            alias: alias,
            label: String(input.label || alias),
            host: hostName,
            user: user,
            port: isFinite(portNumber) && portNumber > 0 ? Math.round(portNumber) : 22,
            remoteCommand: "",
            tags: ["imported"],
            group: "ssh-config",
            icon: "󰣀",
            source: "imported",
            sourcePath: String(input.sourcePath || ""),
            sourceLine: Math.max(0, Number(input.sourceLine || 0)),
            searchText: [alias, hostName, user, String(input.sourcePath || "")].join(" ").toLowerCase()
        };
    }

    function _normalizeManualHosts(raw) {
        var list = Array.isArray(raw) ? raw : [];
        var out = [];
        for (var i = 0; i < list.length; ++i) {
            var host = _normalizeManualHost(list[i], i);
            if (host.host === "")
                continue;
            out.push(host);
        }
        return out;
    }

    function _clonePayload() {
        var payload = stateEnvelope && stateEnvelope.payload ? stateEnvelope.payload : ({});
        return {
            lastConnectedId: String(payload.lastConnectedId || ""),
            lastConnectedLabel: String(payload.lastConnectedLabel || ""),
            lastConnectedAt: String(payload.lastConnectedAt || ""),
            recentIds: Array.isArray(payload.recentIds) ? payload.recentIds.slice() : [],
            lastImportSummary: payload.lastImportSummary && typeof payload.lastImportSummary === "object" ? {
                imported: Math.max(0, Number(payload.lastImportSummary.imported || 0)),
                skippedPatterns: Math.max(0, Number(payload.lastImportSummary.skippedPatterns || 0)),
                errors: Math.max(0, Number(payload.lastImportSummary.errors || 0))
            } : { imported: 0, skippedPatterns: 0, errors: 0 }
        };
    }

    function _payloadFromEnvelope(envelope) {
        var payload = envelope && envelope.payload && typeof envelope.payload === "object" ? envelope.payload : ({});
        return {
            lastConnectedId: String(payload.lastConnectedId || ""),
            lastConnectedLabel: String(payload.lastConnectedLabel || ""),
            lastConnectedAt: String(payload.lastConnectedAt || ""),
            recentIds: Array.isArray(payload.recentIds) ? payload.recentIds.slice() : [],
            lastImportSummary: payload.lastImportSummary && typeof payload.lastImportSummary === "object" ? {
                imported: Math.max(0, Number(payload.lastImportSummary.imported || 0)),
                skippedPatterns: Math.max(0, Number(payload.lastImportSummary.skippedPatterns || 0)),
                errors: Math.max(0, Number(payload.lastImportSummary.errors || 0))
            } : { imported: 0, skippedPatterns: 0, errors: 0 }
        };
    }

    function loadSettings() {
        if (!pluginApi)
            return;
        manualHosts = _normalizeManualHosts(pluginApi.loadSetting("manualHosts", []));
        enableSshConfigImport = pluginApi.loadSetting("enableSshConfigImport", true) !== false;
        var nextDisplay = String(pluginApi.loadSetting("displayMode", "count"));
        displayMode = nextDisplay === "recent" ? "recent" : "count";
        var nextAction = String(pluginApi.loadSetting("defaultAction", "connect"));
        defaultAction = nextAction === "copy" ? "copy" : "connect";
    }

    function loadState() {
        if (!pluginApi)
            return;
        var envelope = pluginApi.loadStateEnvelope ? pluginApi.loadStateEnvelope() : ({});
        if (!envelope || typeof envelope !== "object")
            envelope = ({});
        if (!envelope.payload || typeof envelope.payload !== "object")
            envelope.payload = ({});
        stateEnvelope = {
            stateVersion: Number(envelope.stateVersion || 1),
            updatedAt: String(envelope.updatedAt || ""),
            payload: _payloadFromEnvelope(envelope)
        };
    }

    function refresh() {
        if (!pluginApi)
            return;
        loadSettings();
        loadState();
        refreshImport();
    }

    function _notifyRefresh() {
        if (pluginService && pluginService.pluginRuntimeUpdated)
            pluginService.pluginRuntimeUpdated();
        refreshed();
    }

    function saveManualHosts(list) {
        if (!pluginApi)
            return false;
        var normalized = _normalizeManualHosts(list);
        var persistable = normalized.map(function(host) {
            return {
                id: host.id,
                label: host.label,
                host: host.host,
                user: host.user,
                port: host.port,
                remoteCommand: host.remoteCommand,
                tags: host.tags.slice(),
                group: host.group,
                icon: host.icon
            };
        });
        pluginApi.saveSetting("manualHosts", persistable);
        manualHosts = normalized;
        _recomputeMerged();
        _notifyRefresh();
        return true;
    }

    function setImportEnabled(enabled) {
        if (!pluginApi)
            return false;
        pluginApi.saveSetting("enableSshConfigImport", enabled === true);
        enableSshConfigImport = enabled === true;
        refreshImport();
        _notifyRefresh();
        return true;
    }

    function setDisplayMode(modeValue) {
        if (!pluginApi)
            return false;
        displayMode = String(modeValue || "") === "recent" ? "recent" : "count";
        pluginApi.saveSetting("displayMode", displayMode);
        _notifyRefresh();
        return true;
    }

    function setDefaultAction(modeValue) {
        if (!pluginApi)
            return false;
        defaultAction = String(modeValue || "") === "copy" ? "copy" : "connect";
        pluginApi.saveSetting("defaultAction", defaultAction);
        _notifyRefresh();
        return true;
    }

    function resetStateOnly() {
        if (!pluginApi)
            return false;
        pluginApi.saveStateEnvelope({
            stateVersion: 1,
            updatedAt: new Date().toISOString(),
            payload: {
                lastConnectedId: "",
                lastConnectedLabel: "",
                lastConnectedAt: "",
                recentIds: [],
                lastImportSummary: {
                    imported: importedHosts.length,
                    skippedPatterns: skippedPatternEntries.length,
                    errors: importErrors.length
                }
            }
        });
        loadState();
        _notifyRefresh();
        return true;
    }

    function resetAll() {
        if (!pluginApi)
            return false;
        pluginApi.saveSetting("manualHosts", []);
        pluginApi.saveSetting("enableSshConfigImport", true);
        pluginApi.saveSetting("displayMode", "count");
        pluginApi.saveSetting("defaultAction", "connect");
        loadSettings();
        resetStateOnly();
        refreshImport();
        return true;
    }

    function _recomputeMerged() {
        var manualById = ({});
        var merged = [];
        for (var i = 0; i < manualHosts.length; ++i) {
            var manual = manualHosts[i];
            manualById[manual.id] = true;
            merged.push(manual);
        }
        for (var j = 0; j < importedHosts.length; ++j) {
            var imported = importedHosts[j];
            if (manualById[imported.id])
                continue;
            merged.push(imported);
        }
        merged.sort(function(a, b) {
            var aRank = a.source === "manual" ? 0 : 1;
            var bRank = b.source === "manual" ? 0 : 1;
            var sourceOrder = aRank - bRank;
            if (sourceOrder !== 0)
                return sourceOrder;
            return String(a.label || "").localeCompare(String(b.label || ""));
        });
        mergedHosts = merged;
    }

    function _readTextFile(pathValue) {
        var reader = fileReaderComponent.createObject(root, { path: pathValue });
        var text = null;
        try {
            text = reader.text();
        } catch (err) {
            text = null;
        }
        reader.destroy();
        return text;
    }

    function _pathDir(pathValue) {
        var text = String(pathValue || "");
        var idx = text.lastIndexOf("/");
        return idx >= 0 ? text.slice(0, idx) : ".";
    }

    function _resolveIncludePattern(patternValue, sourcePath) {
        var pattern = _expandHome(patternValue);
        if (pattern === "")
            return "";
        if (pattern.indexOf("/") === 0)
            return pattern;
        return _pathDir(sourcePath) + "/" + pattern;
    }

    function _enqueueFile(pathValue, sourcePath, sourceLine) {
        var path = String(pathValue || "");
        if (path === "" || _seenFiles[path] === true)
            return;
        _pendingFiles.push({
            path: path,
            sourcePath: String(sourcePath || ""),
            sourceLine: Math.max(0, Number(sourceLine || 0))
        });
    }

    function _pushImportError(pathValue, lineNumber, message) {
        _errorList.push({
            path: String(pathValue || ""),
            line: Math.max(0, Number(lineNumber || 0)),
            message: String(message || "")
        });
    }

    function refreshImport() {
        importedHosts = [];
        skippedPatternEntries = [];
        importErrors = [];
        _importedAliasMap = ({});
        _skippedMap = ({});
        _errorList = [];
        _pendingFiles = [];
        _seenFiles = ({});
        _pendingIncludeExpansions = 0;
        importBusy = enableSshConfigImport;
        importReady = !enableSshConfigImport;

        if (!enableSshConfigImport) {
            _recomputeMerged();
            _writeImportSummaryState();
            refreshed();
            return;
        }

        _enqueueFile(importRootPath, "", 0);
        _drainImportQueue();
    }

    function _drainImportQueue() {
        while (_pendingFiles.length > 0) {
            var next = _pendingFiles.shift();
            if (!next || _seenFiles[next.path] === true)
                continue;
            _seenFiles[next.path] = true;
            var text = _readTextFile(next.path);
            if (text === null) {
                _pushImportError(next.path, next.sourceLine, "Failed to read ssh-config file.");
                continue;
            }
            var parsed = SshConfigParser.parseFile(text, next.path);
            for (var errorIdx = 0; errorIdx < parsed.errors.length; ++errorIdx) {
                var errorEntry = parsed.errors[errorIdx];
                _pushImportError(errorEntry.path, errorEntry.line, errorEntry.message);
            }
            for (var aliasIdx = 0; aliasIdx < parsed.aliases.length; ++aliasIdx) {
                var aliasEntry = _normalizeImportedHost(parsed.aliases[aliasIdx]);
                if (aliasEntry.alias === "")
                    continue;
                _importedAliasMap[aliasEntry.id] = aliasEntry;
            }
            for (var skipIdx = 0; skipIdx < parsed.skippedPatterns.length; ++skipIdx) {
                var skipEntry = parsed.skippedPatterns[skipIdx];
                var skipKey = String(skipEntry.sourcePath || "") + ":" + String(skipEntry.sourceLine || 0) + ":" + String(skipEntry.alias || "");
                _skippedMap[skipKey] = {
                    alias: String(skipEntry.alias || ""),
                    sourcePath: String(skipEntry.sourcePath || ""),
                    sourceLine: Math.max(0, Number(skipEntry.sourceLine || 0))
                };
            }
            for (var includeIdx = 0; includeIdx < parsed.includes.length; ++includeIdx) {
                var includeEntry = parsed.includes[includeIdx];
                var resolved = _resolveIncludePattern(includeEntry.pattern, next.path);
                if (resolved === "")
                    continue;
                if (SshConfigParser.hasWildcard(resolved)) {
                    _pendingIncludeExpansions += 1;
                    var proc = includeExpandProcComponent.createObject(root, {
                        owner: root,
                        includePattern: resolved,
                        includeSourcePath: next.path,
                        includeSourceLine: Math.max(0, Number(includeEntry.sourceLine || 0))
                    });
                    proc.command = [
                        "bash",
                        "-lc",
                        'pattern="$1"; shopt -s nullglob dotglob; for path in $pattern; do printf "%s\\n" "$path"; done',
                        "bash",
                        resolved
                    ];
                    proc.running = true;
                } else {
                    _enqueueFile(resolved, next.path, includeEntry.sourceLine);
                }
            }
        }

        if (_pendingIncludeExpansions === 0)
            _finishImportRefresh();
    }

    function _handleIncludeExpansion(proc, outputText) {
        var lines = String(outputText || "").split("\n").map(function(entry) {
            return String(entry || "").trim();
        }).filter(function(entry) {
            return entry !== "";
        });
        if (lines.length === 0)
            _pushImportError(proc.includeSourcePath, proc.includeSourceLine, "Include pattern had no matches: " + proc.includePattern);
        for (var i = 0; i < lines.length; ++i)
            _enqueueFile(lines[i], proc.includeSourcePath, proc.includeSourceLine);
        _pendingIncludeExpansions = Math.max(0, _pendingIncludeExpansions - 1);
        proc.destroy();
        _drainImportQueue();
    }

    function _finishImportRefresh() {
        var imported = [];
        for (var key in _importedAliasMap)
            imported.push(_importedAliasMap[key]);
        imported.sort(function(a, b) {
            return String(a.label || "").localeCompare(String(b.label || ""));
        });
        var skipped = [];
        for (var skipKey in _skippedMap)
            skipped.push(_skippedMap[skipKey]);
        skipped.sort(function(a, b) {
            return String(a.alias || "").localeCompare(String(b.alias || ""));
        });
        importedHosts = imported;
        skippedPatternEntries = skipped;
        importErrors = _errorList.slice();
        importBusy = false;
        importReady = true;
        _recomputeMerged();
        _writeImportSummaryState();
        refreshed();
    }

    function _writeImportSummaryState() {
        if (!pluginApi || !pluginApi.saveStateEnvelope)
            return;
        var payload = _clonePayload();
        payload.lastImportSummary = {
            imported: importedHosts.length,
            skippedPatterns: skippedPatternEntries.length,
            errors: importErrors.length
        };
        pluginApi.saveStateEnvelope({
            stateVersion: 1,
            updatedAt: new Date().toISOString(),
            payload: payload
        });
        loadState();
    }

    function _buildManualCommand(host) {
        var parts = ["ssh"];
        if (Number(host.port || 22) !== 22) {
            parts.push("-p");
            parts.push(String(host.port));
        }
        var target = String(host.user || "").trim() !== "" ? (String(host.user) + "@" + String(host.host)) : String(host.host || "");
        parts.push(target);
        if (String(host.remoteCommand || "").trim() !== "")
            parts.push(String(host.remoteCommand));
        var escaped = [];
        for (var i = 0; i < parts.length; ++i)
            escaped.push(_shellQuote(parts[i]));
        return "exec " + escaped.join(" ");
    }

    function buildDisplayCommand(host) {
        if (!host)
            return "";
        if (host.source === "imported")
            return "ssh " + String(host.alias || host.label || "");
        return _buildManualCommand(host).replace(/^exec\s+/, "");
    }

    function _rememberHost(host) {
        if (!pluginApi || !pluginApi.saveStateEnvelope)
            return;
        var payload = _clonePayload();
        payload.lastConnectedId = String(host.id || "");
        payload.lastConnectedLabel = String(host.label || host.alias || host.host || "");
        payload.lastConnectedAt = new Date().toISOString();
        var recent = [payload.lastConnectedId];
        var currentRecent = Array.isArray(payload.recentIds) ? payload.recentIds : [];
        for (var i = 0; i < currentRecent.length && recent.length < 8; ++i) {
            var item = String(currentRecent[i] || "");
            if (item !== "" && recent.indexOf(item) === -1)
                recent.push(item);
        }
        payload.recentIds = recent;
        payload.lastImportSummary = {
            imported: importedHosts.length,
            skippedPatterns: skippedPatternEntries.length,
            errors: importErrors.length
        };
        pluginApi.saveStateEnvelope({
            stateVersion: 1,
            updatedAt: new Date().toISOString(),
            payload: payload
        });
        loadState();
    }

    function connectHost(host) {
        if (!pluginApi || !host)
            return false;
        var terminalCommand = host.source === "imported"
            ? "exec ssh " + _shellQuote(String(host.alias || ""))
            : _buildManualCommand(host);
        var ok = pluginApi.runProcess(["kitty", "-e", "bash", "-lc", terminalCommand]);
        if (ok !== false) {
            _rememberHost(host);
            _notifyRefresh();
        }
        return ok !== false;
    }

    function copyHostCommand(host) {
        if (!pluginApi || !host)
            return false;
        var commandText = buildDisplayCommand(host);
        if (commandText === "")
            return false;
        var ok = pluginApi.runProcess([
            "bash",
            "-lc",
            "printf '%s' " + _shellQuote(commandText) + " | wl-copy"
        ]);
        if (ok !== false) {
            _rememberHost(host);
            _notifyRefresh();
        }
        return ok !== false;
    }

    function openLauncher() {
        if (!pluginApi)
            return false;
        return pluginApi.runProcess(["quickshell", "ipc", "call", "Launcher", "openPlugins"]) !== false;
    }

    function executeLauncherItem(item) {
        if (!item || !item.data)
            return false;
        var host = item.data.host || null;
        var action = String(item.data.action || defaultAction || "connect");
        if (action === "copy")
            return copyHostCommand(host);
        return connectHost(host);
    }

    function _scoreHost(host, query) {
        var q = String(query || "").trim().toLowerCase();
        if (q === "")
            return 100;
        var haystack = String(host.searchText || "");
        if (haystack.indexOf(q) === -1)
            return -1;
        if (String(host.label || "").toLowerCase().indexOf(q) === 0)
            return 120;
        if (String(host.alias || "").toLowerCase().indexOf(q) === 0)
            return 115;
        return 80;
    }

    function launcherItems(query) {
        var items = [];
        for (var i = 0; i < mergedHosts.length; ++i) {
            var host = mergedHosts[i];
            var score = _scoreHost(host, query);
            if (score < 0)
                continue;
            var description = host.source === "imported"
                ? ("Alias from " + String(host.sourcePath || "~/.ssh/config"))
                : ((String(host.user || "").trim() !== "" ? (host.user + "@") : "") + String(host.host || ""));
            items.push({
                name: String(host.label || host.alias || host.host || "SSH"),
                title: String(host.label || host.alias || host.host || "SSH"),
                description: description,
                icon: String(host.icon || "󰣀"),
                score: score,
                data: {
                    action: "connect",
                    host: host
                }
            });
            items.push({
                name: "Copy " + String(host.label || host.alias || host.host || "SSH"),
                title: "Copy " + String(host.label || host.alias || host.host || "SSH"),
                description: "Copy `" + buildDisplayCommand(host) + "` to the clipboard.",
                icon: "󰅍",
                score: score - 10,
                data: {
                    action: "copy",
                    host: host
                }
            });
        }
        return items;
    }

    function recentHostLabel() {
        var payload = _clonePayload();
        return String(payload.lastConnectedLabel || "");
    }

    function summaryLabel() {
        if (displayMode === "recent" && recentHostLabel() !== "")
            return recentHostLabel();
        return String(mergedHosts.length) + " host" + (mergedHosts.length === 1 ? "" : "s");
    }

    function summaryTooltip() {
        var payload = _clonePayload();
        var lines = [
            "Manual hosts: " + String(manualHosts.length),
            "Imported aliases: " + String(importedHosts.length),
            "Skipped patterns: " + String(skippedPatternEntries.length)
        ];
        if (payload.lastConnectedLabel)
            lines.push("Last connected: " + payload.lastConnectedLabel + (payload.lastConnectedAt ? (" at " + payload.lastConnectedAt) : ""));
        if (importErrors.length > 0)
            lines.push("Import errors: " + String(importErrors.length));
        return lines.join("\n");
    }

    property Component fileReaderComponent: Component {
        FileView {
            blockLoading: true
            printErrors: false
        }
    }

    property Component includeExpandProcComponent: Component {
        Process {
            id: includeProc
            property var owner: null
            property string includePattern: ""
            property string includeSourcePath: ""
            property int includeSourceLine: 0
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    if (includeProc.owner)
                        includeProc.owner._handleIncludeExpansion(includeProc, this.text || "");
                }
            }
        }
    }
}
