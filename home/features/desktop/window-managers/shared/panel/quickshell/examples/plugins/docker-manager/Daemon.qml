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
            terminalCommand: "auto",
            shellPath: "/bin/sh",
            showPorts: true,
            autoScrollOnExpand: true,
            groupByCompose: false,
            showImages: true,
            showVolumes: true,
            showNetworks: true,
            confirmPrune: true
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
    property string terminalCommand: defaults.terminalCommand
    property string shellPath: defaults.shellPath
    property bool showPorts: defaults.showPorts
    property bool autoScrollOnExpand: defaults.autoScrollOnExpand
    property bool groupByCompose: defaults.groupByCompose
    property int runningContainers: 0
    property var containers: []
    property var composeProjects: []
    property var images: []
    property var volumes: []
    property var networks: []
    property int imageCount: 0
    property int volumeCount: 0
    property int networkCount: 0
    property bool showImages: defaults.showImages
    property bool showVolumes: defaults.showVolumes
    property bool showNetworks: defaults.showNetworks
    property bool confirmPrune: defaults.confirmPrune

    property bool _refreshQueued: false
    property int _refreshExitCode: 0
    property int _refreshOutputOffset: 0

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
        terminalCommand = _stringSetting("terminalCommand", defaults.terminalCommand).trim() || defaults.terminalCommand;
        shellPath = _stringSetting("shellPath", defaults.shellPath).trim() || defaults.shellPath;
        showPorts = _boolSetting("showPorts", defaults.showPorts);
        autoScrollOnExpand = _boolSetting("autoScrollOnExpand", defaults.autoScrollOnExpand);
        groupByCompose = _boolSetting("groupByCompose", defaults.groupByCompose);
        showImages = _boolSetting("showImages", defaults.showImages);
        showVolumes = _boolSetting("showVolumes", defaults.showVolumes);
        showNetworks = _boolSetting("showNetworks", defaults.showNetworks);
        confirmPrune = _boolSetting("confirmPrune", defaults.confirmPrune);
    }

    function reloadFromSettings() {
        loadSettings();
        _restartEventStream();
        scheduleRefresh(0);
        _emitRuntimeUpdated();
    }

    function start() {
        if (active)
            return;
        active = true;
        loadSettings();
        fallbackTimer.interval = fallbackRefreshInterval;
        debounceTimer.interval = debounceDelay;
        fallbackTimer.restart();
        scheduleRefresh(0);
    }

    function stop() {
        active = false;
        busy = false;
        _refreshQueued = false;
        debounceTimer.stop();
        fallbackTimer.stop();
        eventRestartTimer.stop();
        noticeTimer.stop();
        if (refreshProc.running)
            refreshProc.running = false;
        if (eventProc.running)
            eventProc.running = false;
        if (actionProc.running)
            actionProc.running = false;
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
        if (dockerBinary !== "auto")
            return [dockerBinary, "events", "--format", "json", "--filter", "type=container"];
        return ["sh", "-c", "runtime=$(command -v docker || command -v podman); if [ -n \"$runtime\" ]; then exec \"$runtime\" events --format json --filter type=container; else exit 1; fi"];
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

    function _clearSnapshot() {
        containers = [];
        composeProjects = [];
        runningContainers = 0;
        images = [];
        volumes = [];
        networks = [];
        imageCount = 0;
        volumeCount = 0;
        networkCount = 0;
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
            healthStatus: String((raw.State && raw.State.Health && raw.State.Health.Status) || "")
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

    function _applySnapshot(payload) {
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

        // Build set of running image references for cross-reference
        var runningImageIds = {};
        for (i = 0; i < normalized.length; i++) {
            if (normalized[i].isRunning)
                runningImageIds[normalized[i].image] = true;
        }

        // Normalize images
        var rawImages = Array.isArray(payload.images) ? payload.images : [];
        var normalizedImages = [];
        for (i = 0; i < rawImages.length; i++) {
            var img = DU.normalizeImage(rawImages[i], runningImageIds);
            if (img) normalizedImages.push(img);
        }
        normalizedImages.sort(DU.sortImages);

        // Normalize volumes
        var rawVolumes = Array.isArray(payload.volumes) ? payload.volumes : [];
        var normalizedVolumes = [];
        for (i = 0; i < rawVolumes.length; i++) {
            var vol = DU.normalizeVolume(rawVolumes[i]);
            if (vol) normalizedVolumes.push(vol);
        }
        normalizedVolumes.sort(DU.sortVolumes);

        // Normalize networks
        var rawNetworks = Array.isArray(payload.networks) ? payload.networks : [];
        var normalizedNetworks = [];
        for (i = 0; i < rawNetworks.length; i++) {
            var net = DU.normalizeNetwork(rawNetworks[i]);
            if (net) normalizedNetworks.push(net);
        }
        normalizedNetworks.sort(DU.sortNetworks);

        containers = normalized;
        composeProjects = projects;
        runningContainers = running;
        images = normalizedImages;
        volumes = normalizedVolumes;
        networks = normalizedNetworks;
        imageCount = normalizedImages.length;
        volumeCount = normalizedVolumes.length;
        networkCount = normalizedNetworks.length;
        runtimeAvailable = true;
        lastError = "";
        lastRefreshAt = new Date().toISOString();
        statusMessage = normalized.length === 0
            ? runtimeName + " is available with no containers."
            : runtimeName + " is available with " + running + " running container" + (running === 1 ? "" : "s") + ".";
        _restartEventStream();
        _setRuntimeStatus("active", "", "");
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

    function _runAction(command, successMessage, failureMessage) {
        if (!Array.isArray(command) || command.length === 0)
            return false;
        if (actionProc.running) {
            _setNotice("warn", "Wait for the current action to finish.");
            return false;
        }
        actionSuccessMessage = String(successMessage || "Action completed.");
        actionFailureMessage = String(failureMessage || "Action failed.");
        actionProc.command = command;
        actionProc.running = true;
        return true;
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

    function runImage(imageName, containerName, hostPort, containerPort) {
        var image = String(imageName || "").trim();
        if (image === "") return false;
        var runtime = dockerBinary === "auto" ? "$(command -v docker || command -v podman)" : _shellQuote(dockerBinary);
        var args = "run -d";
        var name = String(containerName || "").trim();
        if (name !== "")
            args += " --name " + _shellQuote(name);
        var hp = String(hostPort || "").trim();
        var cp = String(containerPort || "").trim();
        if (hp !== "" && cp !== "")
            args += " -p " + _shellQuote(hp + ":" + cp);
        args += " " + _shellQuote(image);
        return _runAction(
            ["sh", "-c", "runtime=" + runtime + "; if [ -n \"$runtime\" ]; then \"$runtime\" " + args + "; else exit 1; fi"],
            "Container started from " + image + ".",
            "Failed to run " + image + "."
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

    property string actionSuccessMessage: ""
    property string actionFailureMessage: ""

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

    property Process eventProc: Process {
        id: eventProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    var payload = JSON.parse(String(data || ""));
                    var action = String(payload.status || payload.Status || payload.Action || "");
                    if (action !== "")
                        root.scheduleRefresh(root.debounceDelay);
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
