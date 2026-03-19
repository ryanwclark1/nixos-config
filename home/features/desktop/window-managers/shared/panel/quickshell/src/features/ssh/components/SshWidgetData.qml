import QtQuick
import Quickshell
import Quickshell.Io
import "../../../services"
import "../../../services/ShellUtils.js" as ShellUtils
import "../../settings/components/SettingsReorderHelpers.js" as SettingsReorderHelpers
import "SshConfigParser.js" as SshConfigParser

QtObject {
    id: root

    property var widgetInstance: null

    readonly property var rawSettings: widgetInstance && widgetInstance.settings ? widgetInstance.settings : ({})
    readonly property var manualHosts: _normalizeManualHosts(rawSettings.manualHosts || [])
    readonly property bool enableSshConfigImport: rawSettings.enableSshConfigImport !== false
    readonly property string displayMode: String(rawSettings.displayMode || "count") === "recent" ? "recent" : "count"
    readonly property string defaultAction: String(rawSettings.defaultAction || "connect") === "copy" ? "copy" : "connect"
    readonly property bool showWhenEmpty: rawSettings.showWhenEmpty === true
    readonly property string emptyClickAction: String(rawSettings.emptyClickAction || "menu") === "refresh" ? "refresh" : "menu"
    readonly property string sshCommand: {
        var cmd = String(rawSettings.sshCommand || "ssh").trim();
        return cmd !== "" ? cmd : "ssh";
    }
    readonly property string emptyLabel: {
        var text = String(rawSettings.emptyLabel || "SSH").trim();
        return text !== "" ? text : "SSH";
    }
    readonly property var stateInfo: _normalizedState(rawSettings.state)

    property var importedHosts: []
    property var skippedPatternEntries: []
    property var importErrors: []
    property var mergedHosts: []
    property bool importReady: false
    property bool importBusy: false
    property string importRootPath: _expandHome("~/.ssh/config")

    property var _pendingFiles: []
    property var _seenFiles: ({})
    property int _pendingIncludeExpansions: 0
    property int _importGeneration: 0
    property var _importedAliasMap: ({})
    property var _skippedMap: ({})
    property var _errorList: []

    onWidgetInstanceChanged: refreshImport()
    onManualHostsChanged: _recomputeMerged()
    onEnableSshConfigImportChanged: refreshImport()

    function _expandHome(pathValue) {
        var text = String(pathValue || "");
        if (text.indexOf("~/") === 0)
            return String(Quickshell.env("HOME") || "") + text.slice(1);
        return text;
    }

    function _clone(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function _normalizeId(text, fallbackValue) {
        var value = String(text || "").trim().toLowerCase();
        if (value === "")
            value = String(fallbackValue || "").trim().toLowerCase();
        value = value.replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "");
        return value === "" ? "host-" + String(Date.now()) : value;
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

    function _normalizedState(raw) {
        var input = raw && typeof raw === "object" ? raw : ({});
        return {
            lastConnectedId: String(input.lastConnectedId || ""),
            lastConnectedLabel: String(input.lastConnectedLabel || ""),
            lastConnectedAt: String(input.lastConnectedAt || ""),
            recentIds: Array.isArray(input.recentIds) ? input.recentIds.slice() : []
        };
    }

    function _settingsSnapshot() {
        return {
            manualHosts: _clone(rawSettings.manualHosts || []),
            enableSshConfigImport: enableSshConfigImport,
            displayMode: displayMode,
            defaultAction: defaultAction,
            sshCommand: sshCommand,
            state: _clone(stateInfo)
        };
    }

    function _persistSettings(nextSettings) {
        if (!widgetInstance || !widgetInstance.instanceId)
            return false;
        return Config.updateBarWidgetByInstance(widgetInstance.instanceId, {
            settings: _clone(nextSettings)
        });
    }

    function saveManualHosts(list) {
        var next = _settingsSnapshot();
        next.manualHosts = _normalizeManualHosts(list).map(function(host) {
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
        return _persistSettings(next);
    }

    function moveManualHost(hostId, targetIndex) {
        var normalizedId = String(hostId || "");
        if (normalizedId === "")
            return false;

        var next = _clone(manualHosts);
        var fromIndex = -1;
        for (var i = 0; i < next.length; ++i) {
            if (String(next[i].id || "") === normalizedId) {
                fromIndex = i;
                break;
            }
        }

        var result = SettingsReorderHelpers.moveArrayItem(next, fromIndex, targetIndex);
        if (!result.changed)
            return false;
        return saveManualHosts(result.items);
    }

    function setImportEnabled(enabled) {
        var next = _settingsSnapshot();
        next.enableSshConfigImport = enabled === true;
        return _persistSettings(next);
    }

    function setDisplayMode(modeValue) {
        var next = _settingsSnapshot();
        next.displayMode = String(modeValue || "") === "recent" ? "recent" : "count";
        return _persistSettings(next);
    }

    function setDefaultAction(modeValue) {
        var next = _settingsSnapshot();
        next.defaultAction = String(modeValue || "") === "copy" ? "copy" : "connect";
        return _persistSettings(next);
    }

    function resetStateOnly() {
        var next = _settingsSnapshot();
        next.state = {
            lastConnectedId: "",
            lastConnectedLabel: "",
            lastConnectedAt: "",
            recentIds: []
        };
        return _persistSettings(next);
    }

    function resetAll() {
        return _persistSettings({
            manualHosts: [],
            enableSshConfigImport: true,
            displayMode: "count",
            defaultAction: "connect",
            sshCommand: "ssh",
            state: {
                lastConnectedId: "",
                lastConnectedLabel: "",
                lastConnectedAt: "",
                recentIds: []
            }
        });
    }

    function refreshImport() {
        _importGeneration += 1;
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
            return;
        }

        _enqueueFile(importRootPath, "", 0);
        _drainImportQueue();
    }

    function _recomputeMerged() {
        var manualList = Array.isArray(manualHosts) ? manualHosts : [];
        var importedList = Array.isArray(importedHosts) ? importedHosts : [];
        var manualById = ({});
        var merged = [];
        for (var i = 0; i < manualList.length; ++i) {
            var manual = manualList[i];
            manualById[manual.id] = true;
            merged.push(manual);
        }
        for (var j = 0; j < importedList.length; ++j) {
            var imported = importedList[j];
            if (manualById[imported.id])
                continue;
            merged.push(imported);
        }
        merged.sort(function(a, b) {
            var aRank = a.source === "manual" ? 0 : 1;
            var bRank = b.source === "manual" ? 0 : 1;
            if (aRank !== bRank)
                return aRank - bRank;
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
                        importGeneration: _importGeneration,
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
        if (!proc || Number(proc.importGeneration || 0) !== _importGeneration) {
            if (proc)
                proc.destroy();
            return;
        }
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
    }

    function _buildManualSshArgs(host) {
        var parts = [];
        if (Number(host.port || 22) !== 22) {
            parts.push("-p");
            parts.push(String(host.port));
        }
        var target = String(host.user || "").trim() !== "" ? (String(host.user) + "@" + String(host.host)) : String(host.host || "");
        parts.push(target);
        if (String(host.remoteCommand || "").trim() !== "")
            parts.push(String(host.remoteCommand));
        return parts;
    }

    function _buildManualCommand(host) {
        var parts = _buildManualSshArgs(host);
        var escaped = [];
        for (var i = 0; i < parts.length; ++i)
            escaped.push(ShellUtils.shellQuote(parts[i]));
        return "exec " + root.sshCommand + " " + escaped.join(" ");
    }

    function _copyText(text) {
        var value = String(text || "");
        if (value === "")
            return false;
        Quickshell.execDetached([
            "sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", value
        ]);
        return true;
    }

    function buildDisplayCommand(host) {
        if (!host)
            return "";
        if (host.source === "imported")
            return root.sshCommand + " " + String(host.alias || host.label || "");
        return _buildManualCommand(host).replace(/^exec\s+/, "");
    }

    function hostAliasText(host) {
        if (!host || host.source !== "imported")
            return "";
        return String(host.alias || host.label || "").trim();
    }

    function hostNameText(host) {
        if (!host)
            return "";
        return String(host.host || "").trim();
    }

    function hostUserHostText(host) {
        if (!host)
            return "";
        var hostName = hostNameText(host);
        if (hostName === "")
            return "";
        var userName = String(host.user || "").trim();
        return userName !== "" ? (userName + "@" + hostName) : hostName;
    }

    function hostSourceLabel(host) {
        if (!host || host.source !== "imported")
            return "";
        var path = String(host.sourcePath || "").trim();
        if (path === "")
            return "";
        var line = Math.max(0, Number(host.sourceLine || 0));
        return line > 0 ? (path + ":" + String(line)) : path;
    }

    function _rememberHost(host) {
        var next = _settingsSnapshot();
        var recent = [String(host.id || "")];
        for (var i = 0; i < stateInfo.recentIds.length && recent.length < 8; ++i) {
            var item = String(stateInfo.recentIds[i] || "");
            if (item !== "" && recent.indexOf(item) === -1)
                recent.push(item);
        }
        next.state = {
            lastConnectedId: String(host.id || ""),
            lastConnectedLabel: String(host.label || host.alias || host.host || ""),
            lastConnectedAt: new Date().toISOString(),
            recentIds: recent
        };
        _persistSettings(next);
    }

    function connectHost(host) {
        if (!host)
            return false;
        if (host.source === "imported") {
            Quickshell.execDetached(ShellUtils.terminalCommand("exec " + root.sshCommand + " \"$1\"", String(host.alias || "")));
        } else {
            var sshArgs = _buildManualSshArgs(host);
            Quickshell.execDetached(ShellUtils.terminalCommand.apply(null, ["exec " + root.sshCommand + " \"$@\""].concat(sshArgs)));
        }
        _rememberHost(host);
        return true;
    }


    function copyHostCommand(host) {
        if (!host)
            return false;
        var commandText = buildDisplayCommand(host);
        if (commandText === "")
            return false;
        _copyText(commandText);
        _rememberHost(host);
        return true;
    }

    function copyHostAlias(host) {
        return _copyText(hostAliasText(host));
    }

    function copyHostName(host) {
        return _copyText(hostNameText(host));
    }

    function copyHostUserHost(host) {
        return _copyText(hostUserHostText(host));
    }

    function copyHostSourcePath(host) {
        return _copyText(hostSourceLabel(host));
    }

    function executeDefault(host) {
        var action = defaultAction;
        if (action === "copy")
            return copyHostCommand(host);
        return connectHost(host);
    }

    function recentHostLabel() {
        return String(stateInfo.lastConnectedLabel || "");
    }

    function summaryLabel() {
        if (displayMode === "recent" && recentHostLabel() !== "")
            return recentHostLabel();
        if (mergedHosts.length === 0)
            return emptyLabel;
        return String(mergedHosts.length) + " host" + (mergedHosts.length === 1 ? "" : "s");
    }

    function summaryTooltip() {
        var lines = [
            "Manual hosts: " + String(manualHosts.length),
            "Imported aliases: " + String(importedHosts.length),
            "Skipped patterns: " + String(skippedPatternEntries.length)
        ];
        if (stateInfo.lastConnectedLabel)
            lines.push("Last connected: " + stateInfo.lastConnectedLabel + (stateInfo.lastConnectedAt ? (" at " + stateInfo.lastConnectedAt) : ""));
        if (importErrors.length > 0)
            lines.push("Import errors: " + String(importErrors.length));
        if (mergedHosts.length === 0 && showWhenEmpty)
            lines.push("Empty click: " + (emptyClickAction === "refresh" ? "refresh import" : "open menu"));
        return lines.join("\n");
    }

    function handleEmptyClick() {
        if (emptyClickAction === "refresh" && enableSshConfigImport && !importBusy) {
            refreshImport();
            return "refresh";
        }
        return "menu";
    }

    function contextActions(limit) {
        var count = Math.max(1, Number(limit || 6));
        var actions = [];
        if (mergedHosts.length === 0) {
            actions.push({
                label: "No SSH hosts configured",
                icon: "󰅚",
                enabled: false
            });
            if (!enableSshConfigImport) {
                actions.push({
                    label: "Enable SSH config import",
                    icon: "󰑐",
                    action: function() {
                        root.setImportEnabled(true);
                    }
                });
            }
        }
        for (var i = 0; i < mergedHosts.length && i < count; ++i) {
            var host = mergedHosts[i];
            actions.push({
                label: "Connect " + String(host.label || host.alias || host.host || "SSH"),
                icon: "󰆍",
                action: (function(selectedHost) {
                    return function() {
                        root.connectHost(selectedHost);
                    };
                })(host)
            });
            actions.push({
                label: "Copy " + String(host.label || host.alias || host.host || "SSH"),
                icon: "󰅍",
                action: (function(selectedHost) {
                    return function() {
                        root.copyHostCommand(selectedHost);
                    };
                })(host)
            });
        }
        if (enableSshConfigImport) {
            actions.push({
                label: importBusy ? "Refreshing import..." : "Refresh SSH config import",
                icon: "󰑐",
                enabled: !importBusy,
                action: function() {
                    root.refreshImport();
                }
            });
        }
        return actions;
    }

    Component.onCompleted: refreshImport()

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
            property int importGeneration: 0
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
