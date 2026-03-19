import QtQuick
import Quickshell
import Quickshell.Io
import "DockerUtils.js" as DU

QtObject {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null

    readonly property string pluginId: pluginManifest && pluginManifest.id ? String(pluginManifest.id) : "docker.manager"
    readonly property var defaults: ({
            dockerBinary: "auto",
            debounceDelay: 300,
            fallbackRefreshInterval: 30000,
            resourceRefreshInterval: 60000,
            statsInterval: 10000,
            logPreviewLines: 10,
            terminalCommand: "auto",
            shellPath: "/bin/sh",
            showPorts: true,
            autoScrollOnExpand: true,
            groupByCompose: false,
            showImages: true,
            showVolumes: true,
            showNetworks: true,
            confirmPrune: true,
            toastEnabled: true
        })

    property bool active: false
    property bool busy: false
    property bool runtimeAvailable: false
    property bool eventStreamRunning: false
    property bool actionBusy: actionProc.running
    property string runtimeName: "Docker"
    property string statusMessage: "Waiting for runtime check."
    property string lastError: ""
    property string lastRefreshAt: ""
    property string noticeMessage: ""
    property string noticeKind: "info"
    property string dockerBinary: defaults.dockerBinary
    property int debounceDelay: defaults.debounceDelay
    property int fallbackRefreshInterval: defaults.fallbackRefreshInterval
    property int resourceRefreshInterval: defaults.resourceRefreshInterval
    property int statsInterval: defaults.statsInterval
    property int logPreviewLines: defaults.logPreviewLines
    property string terminalCommand: defaults.terminalCommand
    property string shellPath: defaults.shellPath
    property bool showPorts: defaults.showPorts
    property bool autoScrollOnExpand: defaults.autoScrollOnExpand
    property bool groupByCompose: defaults.groupByCompose
    property int runningContainers: 0
    property alias containers: _containerModel.values
    property alias composeProjects: _composeModel.values
    property alias images: _imageModel.values
    property alias volumes: _volumeModel.values
    property alias networks: _networkModel.values
    property int imageCount: 0
    property int volumeCount: 0
    property int networkCount: 0
    property bool showImages: defaults.showImages
    property bool showVolumes: defaults.showVolumes
    property bool showNetworks: defaults.showNetworks
    property bool confirmPrune: defaults.confirmPrune
    property bool toastEnabled: defaults.toastEnabled

    // F4: Volume/Network cross-reference maps
    property var volumeUsageMap: ({})
    property var networkUsageMap: ({})

    // F1: Container resource stats
    property var containerStats: ({})
    property bool statsPollingActive: false

    // F3: Inline log preview
    property var containerLogs: ({})
    property string _logRequestId: ""

    // F2: Image pull progress
    property string pullStatus: ""
    property bool pullInProgress: false
    property var _pendingRunArgs: null

    // F10: Toast bridge signal
    signal toastRequested(string kind, string title, string description)

    property bool _refreshQueued: false
    property bool _resourceRefreshQueued: false
    property int _refreshExitCode: 0
    property int _refreshOutputOffset: 0
    property int _resourceRefreshExitCode: 0
    property int _resourceRefreshOutputOffset: 0
    property bool _isPodman: runtimeName === "Podman"

    // F8: ScriptModel instances for efficient list diffing
    property ScriptModel _containerModel: ScriptModel { id: _containerModel; values: [] }
    property ScriptModel _composeModel: ScriptModel { id: _composeModel; values: [] }
    property ScriptModel _imageModel: ScriptModel { id: _imageModel; values: [] }
    property ScriptModel _volumeModel: ScriptModel { id: _volumeModel; values: [] }
    property ScriptModel _networkModel: ScriptModel { id: _networkModel; values: [] }

    function _stringSetting(key, fallback) {
        if (!pluginApi || !pluginApi.loadSetting)
            return String(fallback);
        return String(pluginApi.loadSetting(key, fallback));
    }

    function _intSetting(key, fallback, minValue, maxValue) {
        var value = fallback;
        if (pluginApi && pluginApi.loadSetting)
            value = Number(pluginApi.loadSetting(key, fallback));
        if (!isFinite(value))
            value = fallback;
        value = Math.round(value);
        return Math.max(minValue, Math.min(maxValue, value));
    }

    function _boolSetting(key, fallback) {
        if (!pluginApi || !pluginApi.loadSetting)
            return fallback === true;
        return pluginApi.loadSetting(key, fallback) === true;
    }

    function loadSettings() {
        dockerBinary = _stringSetting("dockerBinary", defaults.dockerBinary).trim() || defaults.dockerBinary;
        debounceDelay = _intSetting("debounceDelay", defaults.debounceDelay, 100, 5000);
        fallbackRefreshInterval = _intSetting("fallbackRefreshInterval", defaults.fallbackRefreshInterval, 5000, 300000);
        resourceRefreshInterval = _intSetting("resourceRefreshInterval", defaults.resourceRefreshInterval, 10000, 600000);
        statsInterval = _intSetting("statsInterval", defaults.statsInterval, 5000, 60000);
        logPreviewLines = _intSetting("logPreviewLines", defaults.logPreviewLines, 5, 50);
        terminalCommand = _stringSetting("terminalCommand", defaults.terminalCommand).trim() || defaults.terminalCommand;
        shellPath = _stringSetting("shellPath", defaults.shellPath).trim() || defaults.shellPath;
        showPorts = _boolSetting("showPorts", defaults.showPorts);
        autoScrollOnExpand = _boolSetting("autoScrollOnExpand", defaults.autoScrollOnExpand);
        groupByCompose = _boolSetting("groupByCompose", defaults.groupByCompose);
        showImages = _boolSetting("showImages", defaults.showImages);
        showVolumes = _boolSetting("showVolumes", defaults.showVolumes);
        showNetworks = _boolSetting("showNetworks", defaults.showNetworks);
        confirmPrune = _boolSetting("confirmPrune", defaults.confirmPrune);
        toastEnabled = _boolSetting("toastEnabled", defaults.toastEnabled);
    }

    function reloadFromSettings() {
        loadSettings();
        _restartEventStream();
        scheduleRefresh(0);
        scheduleResourceRefresh(0);
        _emitRuntimeUpdated();
    }

    function start() {
        if (active)
            return;
        active = true;
        loadSettings();
        fallbackTimer.interval = fallbackRefreshInterval;
        debounceTimer.interval = debounceDelay;
        resourceFallbackTimer.interval = resourceRefreshInterval;
        fallbackTimer.restart();
        resourceFallbackTimer.restart();
        scheduleRefresh(0);
    }

    function stop() {
        active = false;
        busy = false;
        _refreshQueued = false;
        _resourceRefreshQueued = false;
        statsPollingActive = false;
        pullInProgress = false;
        _actionQueue = [];
        debounceTimer.stop();
        fallbackTimer.stop();
        resourceFallbackTimer.stop();
        resourceDebounceTimer.stop();
        statsTimer.stop();
        eventRestartTimer.stop();
        noticeTimer.stop();
        if (refreshProc.running)
            refreshProc.running = false;
        if (resourceRefreshProc.running)
            resourceRefreshProc.running = false;
        if (eventProc.running)
            eventProc.running = false;
        if (actionProc.running)
            actionProc.running = false;
        if (statsProc.running)
            statsProc.running = false;
        if (logProc.running)
            logProc.running = false;
        if (pullProc.running)
            pullProc.running = false;
        eventStreamRunning = false;
    }

    function _emitRuntimeUpdated() {
        if (pluginService && pluginService.pluginRuntimeUpdated)
            pluginService.pluginRuntimeUpdated();
    }

    function _setRuntimeStatus(state, code, message) {
        if (pluginService && pluginService._setPluginStatus)
            pluginService._setPluginStatus(pluginId, state, String(code ?? ""), String(message ?? ""));
        _emitRuntimeUpdated();
    }

    function _setNotice(kind, message) {
        noticeKind = String(kind || "info");
        noticeMessage = String(message || "");
        if (noticeMessage !== "")
            noticeTimer.restart();
        else
            noticeTimer.stop();
        if (toastEnabled && noticeMessage !== "")
            root.toastRequested(noticeKind, runtimeName, noticeMessage);
        _emitRuntimeUpdated();
    }

    function _capitalize(text) {
        var value = String(text || "");
        if (value === "")
            return "";
        return value.charAt(0).toUpperCase() + value.slice(1);
    }

    function _runtimeNameForBinary(binary) {
        var value = String(binary || "").toLowerCase();
        if (value.indexOf("podman") !== -1)
            return "Podman";
        return "Docker";
    }

    function _shellQuote(text) {
        return "'" + String(text || "").replace(/'/g, "'\"'\"'") + "'";
    }

    function _joinWords(text) {
        var raw = String(text || "").trim();
        return raw === "" ? [] : raw.split(/\s+/).filter(Boolean);
    }

    function _composeFileArgs(configValue) {
        var raw = String(configValue || "").trim();
        if (raw === "")
            return "";
        var values = raw.split(",");
        var out = [];
        for (var i = 0; i < values.length; ++i) {
            var item = String(values[i] || "").trim();
            if (item !== "")
                out.push("-f " + _shellQuote(item));
        }
        return out.join(" ");
    }

    // F7: Split polling — container-only refresh
    function _containerRefreshCommand() {
        var runtime = dockerBinary === "auto" ? "" : _shellQuote(dockerBinary);
        return ["sh", "-lc",
            (runtime !== "" ? "runtime=" + runtime + "; " : "if command -v docker >/dev/null 2>&1; then runtime='docker'; elif command -v podman >/dev/null 2>&1; then runtime='podman'; else runtime=''; fi; ")
            + "if [ -z \"$runtime\" ]; then "
            + "printf '{\"available\":false,\"message\":\"Runtime binary not found\"}\\n'; "
            + "exit 0; "
            + "fi; "
            + "if ! \"$runtime\" info >/dev/null 2>&1; then "
            + "printf '{\"available\":false,\"message\":\"Unable to reach %s container runtime\"}\\n' \"$runtime\"; "
            + "exit 0; "
            + "fi; "
            + "ids=$(\"$runtime\" container ls -aq 2>/dev/null | tr '\\n' ' '); "
            + "if [ -z \"${ids// }\" ]; then "
            + "printf '{\"available\":true,\"containers\":[]}\\n'; "
            + "exit 0; "
            + "fi; "
            + "json=$(\"$runtime\" container inspect $ids 2>/dev/null) || { "
            + "printf '{\"available\":false,\"message\":\"Failed to inspect containers\"}\\n'; "
            + "exit 0; "
            + "}; "
            + "printf '{\"available\":true,\"containers\":%s}\\n' \"$json\""
        ];
    }

    // F7: Split polling — resource-only refresh (images, volumes, networks)
    function _resourceRefreshCommand() {
        var runtime = dockerBinary === "auto" ? "" : _shellQuote(dockerBinary);
        return ["sh", "-lc",
            (runtime !== "" ? "runtime=" + runtime + "; " : "if command -v docker >/dev/null 2>&1; then runtime='docker'; elif command -v podman >/dev/null 2>&1; then runtime='podman'; else runtime=''; fi; ")
            + "if [ -z \"$runtime\" ]; then exit 0; fi; "
            + "imgs=$(\"$runtime\" image ls --format json 2>/dev/null | jq -s . 2>/dev/null) || imgs='[]'; "
            + "vols=$(\"$runtime\" volume ls --format json 2>/dev/null | jq -s . 2>/dev/null) || vols='[]'; "
            + "nets=$(\"$runtime\" network ls --format json 2>/dev/null | jq -s . 2>/dev/null) || nets='[]'; "
            + "printf '{\"images\":%s,\"volumes\":%s,\"networks\":%s}\\n' \"$imgs\" \"$vols\" \"$nets\""
        ];
    }

    // Keep legacy combined command for initial bootstrap
    function _refreshCommand() {
        var runtime = dockerBinary === "auto" ? "" : _shellQuote(dockerBinary);
        return ["sh", "-lc",
            (runtime !== "" ? "runtime=" + runtime + "; " : "if command -v docker >/dev/null 2>&1; then runtime='docker'; elif command -v podman >/dev/null 2>&1; then runtime='podman'; else runtime=''; fi; ")
            + "if [ -z \"$runtime\" ]; then "
            + "printf '{\"available\":false,\"message\":\"Runtime binary not found\"}\\n'; "
            + "exit 0; "
            + "fi; "
            + "if ! \"$runtime\" info >/dev/null 2>&1; then "
            + "printf '{\"available\":false,\"message\":\"Unable to reach %s container runtime\"}\\n' \"$runtime\"; "
            + "exit 0; "
            + "fi; "
            + "imgs=$(\"$runtime\" image ls --format json 2>/dev/null | jq -s . 2>/dev/null) || imgs='[]'; "
            + "vols=$(\"$runtime\" volume ls --format json 2>/dev/null | jq -s . 2>/dev/null) || vols='[]'; "
            + "nets=$(\"$runtime\" network ls --format json 2>/dev/null | jq -s . 2>/dev/null) || nets='[]'; "
            + "ids=$(\"$runtime\" container ls -aq 2>/dev/null | tr '\\n' ' '); "
            + "if [ -z \"${ids// }\" ]; then "
            + "printf '{\"available\":true,\"containers\":[],\"images\":%s,\"volumes\":%s,\"networks\":%s}\\n' \"$imgs\" \"$vols\" \"$nets\"; "
            + "exit 0; "
            + "fi; "
            + "json=$(\"$runtime\" container inspect $ids 2>/dev/null) || { "
            + "printf '{\"available\":false,\"message\":\"Failed to inspect containers\"}\\n'; "
            + "exit 0; "
            + "}; "
            + "printf '{\"available\":true,\"containers\":%s,\"images\":%s,\"volumes\":%s,\"networks\":%s}\\n' \"$json\" \"$imgs\" \"$vols\" \"$nets\""
        ];
    }

    function _eventCommand() {
        var filters = "--filter type=container";
        if (_isPodman)
            filters += " --filter type=image --filter type=volume --filter type=network";
        if (dockerBinary !== "auto")
            return [dockerBinary, "events", "--format", "json"].concat(filters.split(" "));
        return ["sh", "-c", "runtime=$(command -v docker || command -v podman); if [ -n \"$runtime\" ]; then exec \"$runtime\" events --format json " + filters + "; else exit 1; fi"];
    }

    // F1: Stats command
    function _statsCommand() {
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return ["sh", "-c", "runtime=" + runtime + "; \"$runtime\" stats --no-stream --format '{{json .}}' 2>/dev/null | jq -s . 2>/dev/null || echo '[]'"];
    }

    function scheduleRefresh(delayMs) {
        if (!active)
            return;
        if (busy || refreshProc.running) {
            _refreshQueued = true;
            return;
        }
        var delay = Math.max(0, Number(delayMs) || 0);
        if (delay === 0) {
            Qt.callLater(refresh);
            return;
        }
        debounceTimer.interval = delay;
        debounceTimer.restart();
    }

    function scheduleResourceRefresh(delayMs) {
        if (!active)
            return;
        if (resourceRefreshProc.running) {
            _resourceRefreshQueued = true;
            return;
        }
        var delay = Math.max(0, Number(delayMs) || 0);
        if (delay === 0) {
            Qt.callLater(_refreshResources);
            return;
        }
        resourceDebounceTimer.interval = delay;
        resourceDebounceTimer.restart();
    }

    function refresh() {
        if (!active) {
            _refreshQueued = false;
            return;
        }
        if (busy || refreshProc.running) {
            _refreshQueued = true;
            return;
        }
        _refreshQueued = false;
        busy = true;
        _refreshExitCode = 0;
        _refreshOutputOffset = String(refreshCollector.text || "").length;
        refreshProc.command = _refreshCommand();
        refreshProc.running = true;
        _emitRuntimeUpdated();
    }

    function _refreshResources() {
        if (!active || !runtimeAvailable) {
            _resourceRefreshQueued = false;
            return;
        }
        if (resourceRefreshProc.running) {
            _resourceRefreshQueued = true;
            return;
        }
        _resourceRefreshQueued = false;
        _resourceRefreshExitCode = 0;
        _resourceRefreshOutputOffset = String(resourceRefreshCollector.text || "").length;
        resourceRefreshProc.command = _resourceRefreshCommand();
        resourceRefreshProc.running = true;
    }

    function _clearSnapshot() {
        _containerModel.values = [];
        _composeModel.values = [];
        runningContainers = 0;
        _imageModel.values = [];
        _volumeModel.values = [];
        _networkModel.values = [];
        imageCount = 0;
        volumeCount = 0;
        networkCount = 0;
        volumeUsageMap = ({});
        networkUsageMap = ({});
        containerStats = ({});
        containerLogs = ({});
    }

    function _normalizePorts(rawPorts) {
        var output = [];
        if (!rawPorts || typeof rawPorts !== "object")
            return output;
        for (var portKey in rawPorts) {
            var bindings = rawPorts[portKey];
            if (!bindings || !bindings.length)
                continue;
            for (var i = 0; i < bindings.length; ++i) {
                var binding = bindings[i];
                if (!binding || binding.HostPort === undefined)
                    continue;
                output.push({
                    containerPort: String(portKey || ""),
                    hostPort: String(binding.HostPort || ""),
                    hostIp: String(binding.HostIp || "")
                });
            }
        }
        return output;
    }

    function _lastActivity(rawState) {
        var startedAt = rawState && rawState.StartedAt ? Date.parse(rawState.StartedAt) : 0;
        var finishedAt = rawState && rawState.FinishedAt ? Date.parse(rawState.FinishedAt) : 0;
        var value = Math.max(isFinite(startedAt) ? startedAt : 0, isFinite(finishedAt) ? finishedAt : 0);
        return isFinite(value) ? value : 0;
    }

    // F4: Extract volume mounts from container inspect
    function _normalizeMounts(rawMounts) {
        var output = [];
        if (!rawMounts || !Array.isArray(rawMounts))
            return output;
        for (var i = 0; i < rawMounts.length; ++i) {
            var m = rawMounts[i];
            if (m && String(m.Type || "") === "volume" && m.Name)
                output.push({ name: String(m.Name), destination: String(m.Destination || "") });
        }
        return output;
    }

    // F4: Extract network names from container inspect
    function _extractNetworkNames(networkSettings) {
        if (!networkSettings || !networkSettings.Networks || typeof networkSettings.Networks !== "object")
            return [];
        return Object.keys(networkSettings.Networks);
    }

    function _normalizeContainer(raw) {
        if (!raw || typeof raw !== "object")
            return null;
        var labels = raw.Config && raw.Config.Labels && typeof raw.Config.Labels === "object" ? raw.Config.Labels : ({});
        var state = raw.State && raw.State.Status ? String(raw.State.Status) : "";
        return {
            id: String(raw.Id || ""),
            name: String(raw.Name || "").replace(/^\//, ""),
            image: String((raw.Config && raw.Config.Image) || raw.Image || ""),
            state: state,
            status: _capitalize(state),
            isRunning: raw.State && raw.State.Running === true,
            isPaused: raw.State && raw.State.Paused === true,
            createdAt: String(raw.Created || ""),
            lastActivity: _lastActivity(raw.State),
            ports: _normalizePorts(raw.NetworkSettings && raw.NetworkSettings.Ports),
            composeProject: String(labels["com.docker.compose.project"] || labels["io.podman.compose.project"] || ""),
            composeService: String(labels["com.docker.compose.service"] || labels["io.podman.compose.service"] || ""),
            composeWorkingDir: String(labels["com.docker.compose.project.working_dir"] || labels["io.podman.compose.project.working_dir"] || ""),
            composeConfigFiles: String(labels["com.docker.compose.project.config_files"] || labels["io.podman.compose.project.config_files"] || "compose.yaml"),
            healthStatus: String((raw.State && raw.State.Health && raw.State.Health.Status) || ""),
            mounts: _normalizeMounts(raw.Mounts),
            networkNames: _extractNetworkNames(raw.NetworkSettings)
        };
    }

    function _sortContainers(left, right) {
        var order = ({ running: 0, paused: 1 });
        var leftRank = order[left.state] !== undefined ? order[left.state] : 2;
        var rightRank = order[right.state] !== undefined ? order[right.state] : 2;
        if (leftRank !== rightRank)
            return leftRank - rightRank;
        if (left.lastActivity !== right.lastActivity)
            return right.lastActivity - left.lastActivity;
        return String(left.name || "").localeCompare(String(right.name || ""));
    }

    // F7: Split container snapshot application
    function _applyContainerSnapshot(payload) {
        var available = payload && payload.available === true;
        runtimeName = _runtimeNameForBinary(dockerBinary === "auto" ? "docker" : dockerBinary);
        if (!available) {
            runtimeAvailable = false;
            statusMessage = payload && payload.message ? String(payload.message) : "Runtime unavailable.";
            lastError = statusMessage;
            _clearSnapshot();
            if (eventProc.running)
                eventProc.running = false;
            _setRuntimeStatus("degraded", "E_DOCKER_RUNTIME_UNAVAILABLE", statusMessage);
            return;
        }

        var rawContainers = Array.isArray(payload.containers) ? payload.containers : [];
        var normalized = [];
        var projectMap = ({});
        var running = 0;
        var i;

        for (i = 0; i < rawContainers.length; ++i) {
            var container = _normalizeContainer(rawContainers[i]);
            if (!container)
                continue;
            normalized.push(container);
            if (container.isRunning)
                running += 1;
            if (container.composeProject !== "") {
                if (!projectMap[container.composeProject]) {
                    projectMap[container.composeProject] = {
                        name: container.composeProject,
                        containers: [],
                        runningCount: 0,
                        totalCount: 0,
                        workingDir: container.composeWorkingDir,
                        configFiles: container.composeConfigFiles
                    };
                }
                projectMap[container.composeProject].containers.push(container);
                projectMap[container.composeProject].totalCount += 1;
                if (container.isRunning)
                    projectMap[container.composeProject].runningCount += 1;
            }
        }

        normalized.sort(_sortContainers);

        var projects = [];
        for (var projectName in projectMap) {
            projectMap[projectName].containers.sort(_sortContainers);
            projects.push(projectMap[projectName]);
        }
        projects.sort(function(left, right) {
            if (left.runningCount !== right.runningCount)
                return right.runningCount - left.runningCount;
            return String(left.name || "").localeCompare(String(right.name || ""));
        });

        // F4: Build volume and network usage reverse maps
        var volMap = ({});
        var netMap = ({});
        for (i = 0; i < normalized.length; i++) {
            var c = normalized[i];
            if (c.mounts) {
                for (var mi = 0; mi < c.mounts.length; mi++) {
                    var volName = c.mounts[mi].name;
                    if (!volMap[volName]) volMap[volName] = [];
                    volMap[volName].push(c.name);
                }
            }
            if (c.networkNames) {
                for (var ni = 0; ni < c.networkNames.length; ni++) {
                    var netName = c.networkNames[ni];
                    if (!netMap[netName]) netMap[netName] = [];
                    netMap[netName].push(c.name);
                }
            }
        }
        volumeUsageMap = volMap;
        networkUsageMap = netMap;

        _containerModel.values = normalized;
        _composeModel.values = projects;
        runningContainers = running;
        runtimeAvailable = true;
        lastError = "";
        lastRefreshAt = new Date().toISOString();
        statusMessage = normalized.length === 0
            ? runtimeName + " is available with no containers."
            : runtimeName + " is available with " + running + " running container" + (running === 1 ? "" : "s") + ".";
        _restartEventStream();
        _setRuntimeStatus("active", "", "");
    }

    // F7: Split resource snapshot application
    function _applyResourceSnapshot(payload) {
        if (!payload || typeof payload !== "object")
            return;

        // Build set of running image references for cross-reference
        var runningImageIds = {};
        var currentContainers = _containerModel.values;
        for (var ci = 0; ci < currentContainers.length; ci++) {
            if (currentContainers[ci].isRunning)
                runningImageIds[currentContainers[ci].image] = true;
        }

        var i;
        var rawImages = Array.isArray(payload.images) ? payload.images : [];
        var normalizedImages = [];
        for (i = 0; i < rawImages.length; i++) {
            var img = DU.normalizeImage(rawImages[i], runningImageIds);
            if (img) normalizedImages.push(img);
        }
        normalizedImages.sort(DU.sortImages);

        var rawVolumes = Array.isArray(payload.volumes) ? payload.volumes : [];
        var normalizedVolumes = [];
        for (i = 0; i < rawVolumes.length; i++) {
            var vol = DU.normalizeVolume(rawVolumes[i]);
            if (vol) normalizedVolumes.push(vol);
        }
        normalizedVolumes.sort(DU.sortVolumes);

        var rawNetworks = Array.isArray(payload.networks) ? payload.networks : [];
        var normalizedNetworks = [];
        for (i = 0; i < rawNetworks.length; i++) {
            var net = DU.normalizeNetwork(rawNetworks[i]);
            if (net) normalizedNetworks.push(net);
        }
        normalizedNetworks.sort(DU.sortNetworks);

        _imageModel.values = normalizedImages;
        _volumeModel.values = normalizedVolumes;
        _networkModel.values = normalizedNetworks;
        imageCount = normalizedImages.length;
        volumeCount = normalizedVolumes.length;
        networkCount = normalizedNetworks.length;
    }

    function _applySnapshot(payload) {
        _applyContainerSnapshot(payload);
        if (payload && payload.available === true)
            _applyResourceSnapshot(payload);
    }

    function _restartEventStream() {
        eventRestartTimer.stop();
        if (eventProc.running)
            eventProc.running = false;
        if (!active || !runtimeAvailable)
            return;
        eventProc.command = _eventCommand();
        eventProc.running = true;
    }

    function _handleRefreshFinished(stdoutText, exitCode) {
        busy = false;
        if (!active)
            return;
        if (exitCode !== 0) {
            runtimeAvailable = false;
            statusMessage = "Refresh failed.";
            lastError = statusMessage;
            _clearSnapshot();
            _setRuntimeStatus("degraded", "E_DOCKER_RUNTIME_UNAVAILABLE", statusMessage);
        } else {
            try {
                var payload = JSON.parse(String(stdoutText || "").trim() || "{}");
                _applySnapshot(payload);
            } catch (e) {
                runtimeAvailable = false;
                statusMessage = "Failed to parse runtime snapshot.";
                lastError = String(e);
                _clearSnapshot();
                _setRuntimeStatus("degraded", "E_DOCKER_SNAPSHOT_PARSE", statusMessage);
            }
        }

        if (_refreshQueued) {
            _refreshQueued = false;
            scheduleRefresh(0);
        }
        _emitRuntimeUpdated();
    }

    function _handleResourceRefreshFinished(stdoutText, exitCode) {
        if (!active || !runtimeAvailable)
            return;
        if (exitCode === 0) {
            try {
                var payload = JSON.parse(String(stdoutText || "").trim() || "{}");
                _applyResourceSnapshot(payload);
            } catch (e) {
                // silently ignore resource parse errors
            }
        }
        if (_resourceRefreshQueued) {
            _resourceRefreshQueued = false;
            scheduleResourceRefresh(0);
        }
        _emitRuntimeUpdated();
    }

    // F1: Handle stats response
    function _handleStatsFinished(stdoutText) {
        if (!active || !runtimeAvailable)
            return;
        try {
            var arr = JSON.parse(String(stdoutText || "").trim() || "[]");
            var map = ({});
            for (var i = 0; i < arr.length; i++) {
                var entry = arr[i];
                var id = String(entry.ID || entry.Container || "");
                if (id !== "") {
                    map[id] = {
                        cpuPercent: String(entry.CPUPerc || "0%"),
                        memUsage: String(entry.MemUsage || ""),
                        memPercent: String(entry.MemPerc || "0%")
                    };
                }
            }
            containerStats = map;
        } catch (e) {
            // silently ignore stats parse errors
        }
        _emitRuntimeUpdated();
    }

    // F3: Fetch inline log preview
    function fetchLogs(containerId) {
        var id = String(containerId || "").trim();
        if (id === "" || logProc.running)
            return;
        _logRequestId = id;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        logProc.command = ["sh", "-c", "runtime=" + runtime + "; \"$runtime\" logs --tail " + logPreviewLines + " " + _shellQuote(id) + " 2>&1"];
        logProc.running = true;
    }

    function _runAction(command, successMessage, failureMessage) {
        if (!Array.isArray(command) || command.length === 0)
            return false;
        if (actionProc.running) {
            _actionQueue = _actionQueue.concat([{
                command: command,
                successMessage: String(successMessage || "Action completed."),
                failureMessage: String(failureMessage || "Action failed.")
            }]);
            return true;
        }
        actionSuccessMessage = String(successMessage || "Action completed.");
        actionFailureMessage = String(failureMessage || "Action failed.");
        actionProc.command = command;
        actionProc.running = true;
        return true;
    }

    function _drainActionQueue() {
        if (_actionQueue.length === 0 || actionProc.running)
            return;
        var next = _actionQueue[0];
        _actionQueue = _actionQueue.slice(1);
        actionSuccessMessage = next.successMessage;
        actionFailureMessage = next.failureMessage;
        actionProc.command = next.command;
        actionProc.running = true;
    }

    function executeContainerAction(containerId, action) {
        var identifier = String(containerId || "").trim();
        if (identifier === "")
            return false;

        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        var cmd = ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" " + action + " " + _shellQuote(identifier) + "; else exit 1; fi"];

        return _runAction(
            cmd,
            _capitalize(action) + " requested for " + identifier + ".",
            "Failed to " + action + " " + identifier + "."
        );
    }

    function removeContainer(containerId) {
        var identifier = String(containerId || "").trim();
        if (identifier === "")
            return false;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" rm " + _shellQuote(identifier) + "; else exit 1; fi"],
            "Container " + identifier.slice(0, 12) + " removed.",
            "Failed to remove container " + identifier.slice(0, 12) + "."
        );
    }

    function executeComposeAction(project, action) {
        var workingDir = project && project.workingDir ? String(project.workingDir) : "";
        var configFiles = project && project.configFiles ? String(project.configFiles) : "";
        if (workingDir === "") {
            _setNotice("error", "Compose project is missing a working directory.");
            return false;
        }

        var composeArgs = _composeFileArgs(configFiles);
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        var shellCommand = "cd " + _shellQuote(workingDir) + " && runtime=" + runtime + "; \"$runtime\" compose "
            + (composeArgs !== "" ? composeArgs + " " : "");

        if (action === "logs") {
            return _openInTerminal(shellCommand + "logs -f");
        }

        var supported = ({
                up: "up -d",
                down: "down",
                restart: "restart",
                stop: "stop",
                start: "start",
                pull: "pull"
            });
        if (!supported[action])
            return false;

        return _runAction(
            ["sh", "-lc", shellCommand + supported[action]],
            _capitalize(action) + " requested for compose project " + String(project.name || "") + ".",
            "Failed to " + action + " compose project " + String(project.name || "") + "."
        );
    }

    function _openInTerminal(innerCommand) {
        var command = String(innerCommand || "").trim();
        if (command === "")
            return false;

        var termCmd = terminalCommand;
        if (termCmd === "auto") {
            termCmd = "for t in ghostty kitty foot alacritty wezterm; do if command -v $t >/dev/null 2>&1; then exec $t -e bash -lc " + _shellQuote(command) + "; fi; done";
            Quickshell.execDetached(["sh", "-c", termCmd]);
        } else {
             Quickshell.execDetached(["sh", "-lc", termCmd + " " + _shellQuote(command)]);
        }
        return true;
    }

    function openLogs(containerId) {
        var identifier = String(containerId || "").trim();
        if (identifier === "")
            return false;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _openInTerminal("runtime=" + runtime + "; \"$runtime\" logs -f " + _shellQuote(identifier));
    }

    function removeImage(imageId) {
        var id = String(imageId || "").trim();
        if (id === "") return false;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" rmi " + _shellQuote(id) + "; else exit 1; fi"],
            "Image " + id.slice(0, 12) + " removed.",
            "Failed to remove image " + id.slice(0, 12) + "."
        );
    }

    function removeVolume(volumeName) {
        var name = String(volumeName || "").trim();
        if (name === "") return false;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" volume rm " + _shellQuote(name) + "; else exit 1; fi"],
            "Volume " + name + " removed.",
            "Failed to remove volume " + name + "."
        );
    }

    function removeNetwork(networkName) {
        var name = String(networkName || "").trim();
        if (name === "") return false;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" network rm " + _shellQuote(name) + "; else exit 1; fi"],
            "Network " + name + " removed.",
            "Failed to remove network " + name + "."
        );
    }

    function pruneImages() {
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" image prune -f; else exit 1; fi"],
            "Dangling images pruned.",
            "Failed to prune images."
        );
    }

    function pruneVolumes() {
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" volume prune -f; else exit 1; fi"],
            "Unused volumes pruned.",
            "Failed to prune volumes."
        );
    }

    function pruneNetworks() {
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" network prune -f; else exit 1; fi"],
            "Unused networks pruned.",
            "Failed to prune networks."
        );
    }

    function systemPrune() {
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" system prune -f; else exit 1; fi"],
            "System prune completed.",
            "System prune failed."
        );
    }

    // F2: Image pull + run with progress
    function runImage(imageName, containerName, hostPort, containerPort) {
        var image = String(imageName || "").trim();
        if (image === "") return false;
        if (pullInProgress) return false;

        _pendingRunArgs = {
            image: image,
            containerName: String(containerName || "").trim(),
            hostPort: String(hostPort || "").trim(),
            containerPort: String(containerPort || "").trim()
        };
        pullStatus = "Pulling " + image + "...";
        pullInProgress = true;
        _emitRuntimeUpdated();

        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        pullProc.command = ["sh", "-c", "runtime=" + runtime + "; \"$runtime\" pull " + _shellQuote(image) + " 2>&1"];
        pullProc.running = true;
        return true;
    }

    function _executeRun(args) {
        if (!args) return false;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        var cmdArgs = "run -d";
        if (args.containerName !== "")
            cmdArgs += " --name " + _shellQuote(args.containerName);
        if (args.hostPort !== "" && args.containerPort !== "")
            cmdArgs += " -p " + _shellQuote(args.hostPort + ":" + args.containerPort);
        cmdArgs += " " + _shellQuote(args.image);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" " + cmdArgs + "; else exit 1; fi"],
            "Container started from " + args.image + ".",
            "Failed to run " + args.image + "."
        );
    }

    function checkPortAvailable(port, callback) {
        if (portCheckProc.running) {
            if (callback) callback(false);
            return;
        }
        _portCheckCallback = callback || null;
        portCheckProc.command = ["sh", "-c", "ss -tlnH sport = :" + String(Number(port) || 0)];
        portCheckProc.running = true;
    }
    property var _portCheckCallback: null

    function openShell(containerId) {
        var identifier = String(containerId || "").trim();
        if (identifier === "")
            return false;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        return _openInTerminal(
            "runtime=" + runtime + "; \"$runtime\" exec -it " + _shellQuote(identifier) + " " + _shellQuote(shellPath)
        );
    }

    onDockerBinaryChanged: {
        runtimeName = _runtimeNameForBinary(dockerBinary === "auto" ? "docker" : dockerBinary);
        if (active)
            reloadFromSettings();
    }

    onDebounceDelayChanged: debounceTimer.interval = debounceDelay
    onFallbackRefreshIntervalChanged: fallbackTimer.interval = fallbackRefreshInterval
    onResourceRefreshIntervalChanged: resourceFallbackTimer.interval = resourceRefreshInterval

    // F1: Start/stop stats polling based on active flag
    onStatsPollingActiveChanged: {
        if (statsPollingActive && runtimeAvailable) {
            statsTimer.restart();
            // Fetch immediately
            if (!statsProc.running) {
                statsProc.command = _statsCommand();
                statsProc.running = true;
            }
        } else {
            statsTimer.stop();
        }
    }

    property string actionSuccessMessage: ""
    property string actionFailureMessage: ""
    property var _actionQueue: []

    property Timer debounceTimer: Timer {
        id: debounceTimer
        interval: root.debounceDelay
        repeat: false
        onTriggered: root.refresh()
    }

    property Timer fallbackTimer: Timer {
        id: fallbackTimer
        interval: root.fallbackRefreshInterval
        repeat: true
        onTriggered: root.scheduleRefresh(0)
    }

    // F7: Resource-tier debounce timer
    property Timer resourceDebounceTimer: Timer {
        id: resourceDebounceTimer
        interval: root.debounceDelay
        repeat: false
        onTriggered: root._refreshResources()
    }

    // F7: Resource-tier fallback timer
    property Timer resourceFallbackTimer: Timer {
        id: resourceFallbackTimer
        interval: root.resourceRefreshInterval
        repeat: true
        onTriggered: root.scheduleResourceRefresh(0)
    }

    // F1: Stats polling timer
    property Timer statsTimer: Timer {
        id: statsTimer
        interval: root.statsInterval
        repeat: true
        onTriggered: {
            if (root.statsPollingActive && root.runtimeAvailable && !statsProc.running) {
                statsProc.command = root._statsCommand();
                statsProc.running = true;
            }
        }
    }

    property Timer eventRestartTimer: Timer {
        id: eventRestartTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (root.active && root.runtimeAvailable)
                root._restartEventStream();
        }
    }

    property Timer noticeTimer: Timer {
        id: noticeTimer
        interval: 4500
        repeat: false
        onTriggered: root.noticeMessage = ""
    }

    property Process refreshProc: Process {
        id: refreshProc
        running: false
        stdout: StdioCollector {
            id: refreshCollector
            onStreamFinished: {
                var fullText = String(text || "");
                root._handleRefreshFinished(fullText.slice(root._refreshOutputOffset), root._refreshExitCode);
            }
        }
        onExited: (exitCode, exitStatus) => {
            root._refreshExitCode = exitCode;
            if (exitCode !== 0 && String(refreshCollector.text || "").slice(root._refreshOutputOffset) === "")
                root._handleRefreshFinished("", exitCode);
        }
    }

    // F7: Resource-tier refresh process
    property Process resourceRefreshProc: Process {
        id: resourceRefreshProc
        running: false
        stdout: StdioCollector {
            id: resourceRefreshCollector
            onStreamFinished: {
                var fullText = String(text || "");
                root._handleResourceRefreshFinished(fullText.slice(root._resourceRefreshOutputOffset), root._resourceRefreshExitCode);
            }
        }
        onExited: (exitCode, exitStatus) => {
            root._resourceRefreshExitCode = exitCode;
            if (exitCode !== 0 && String(resourceRefreshCollector.text || "").slice(root._resourceRefreshOutputOffset) === "")
                root._handleResourceRefreshFinished("", exitCode);
        }
    }

    property Process eventProc: Process {
        id: eventProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    var payload = JSON.parse(String(data || ""));
                    var action = String(payload.status || payload.Status || payload.Action || "");
                    var eventType = String(payload.Type || payload.type || "container");
                    if (action !== "") {
                        // F9: Route Podman event types to appropriate refresh tier
                        if (eventType === "container")
                            root.scheduleRefresh(root.debounceDelay);
                        else
                            root.scheduleResourceRefresh(root.debounceDelay);
                    }
                } catch (e) {
                    root.scheduleRefresh(root.debounceDelay);
                }
            }
        }
        onRunningChanged: {
            root.eventStreamRunning = running;
            if (!running && root.active && root.runtimeAvailable)
                eventRestartTimer.restart();
            root._emitRuntimeUpdated();
        }
    }

    property Process actionProc: Process {
        id: actionProc
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root._setNotice("ok", root.actionSuccessMessage);
            else {
                root.lastError = root.actionFailureMessage;
                root._setNotice("error", root.actionFailureMessage);
                root._setRuntimeStatus("degraded", "E_DOCKER_ACTION_FAILED", root.actionFailureMessage);
            }
            root.scheduleRefresh(250);
            root.scheduleResourceRefresh(250);
            Qt.callLater(root._drainActionQueue);
        }
    }

    // F1: Stats polling process
    property Process statsProc: Process {
        id: statsProc
        running: false
        stdout: StdioCollector {
            id: statsCollector
            onStreamFinished: {
                root._handleStatsFinished(String(text || ""));
            }
        }
    }

    // F3: Log preview process
    property Process logProc: Process {
        id: logProc
        running: false
        stdout: StdioCollector {
            id: logCollector
            onStreamFinished: {
                var logText = String(text || "");
                if (root._logRequestId !== "") {
                    var next = Object.assign({}, root.containerLogs);
                    next[root._logRequestId] = logText;
                    root.containerLogs = next;
                }
                root._emitRuntimeUpdated();
            }
        }
    }

    // F2: Image pull process with streaming progress
    property Process pullProc: Process {
        id: pullProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                var line = String(data || "").trim();
                if (line !== "")
                    root.pullStatus = line;
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.pullInProgress = false;
            if (exitCode === 0) {
                root.pullStatus = "Pull complete. Starting container...";
                root._executeRun(root._pendingRunArgs);
            } else {
                root.pullStatus = "Pull failed (exit " + exitCode + ").";
                root._setNotice("error", "Failed to pull image.");
            }
            root._pendingRunArgs = null;
            root._emitRuntimeUpdated();
        }
    }

    property Process portCheckProc: Process {
        id: portCheckProc
        running: false
        stdout: StdioCollector {
            id: portCheckCollector
            onStreamFinished: {
                var output = String(text || "").trim();
                var available = output === "";
                if (root._portCheckCallback)
                    root._portCheckCallback(available);
                root._portCheckCallback = null;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                if (root._portCheckCallback)
                    root._portCheckCallback(true);
                root._portCheckCallback = null;
            }
        }
    }
}
