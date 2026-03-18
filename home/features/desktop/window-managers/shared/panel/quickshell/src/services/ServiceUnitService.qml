pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "ShellUtils.js" as SU

QtObject {
    id: root

    property int subscriberCount: 0
    property int pollIntervalMs: 10000
    property var userUnits: []
    property var systemUnits: []
    property var dockerContainers: []
    property string userStatus: "loading"
    property string userMessage: "Loading user services..."
    property string systemStatus: "loading"
    property string systemMessage: "Loading system services..."
    property string dockerStatus: "loading"
    property string dockerMessage: "Loading containers..."
    property bool userBusy: userPoll.busy
    property bool systemBusy: systemPoll.busy
    property bool dockerBusy: dockerPoll.busy
    property int detailPollIntervalMs: 3000
    property string detailScope: ""
    property string detailUnitName: ""
    property string detailStatus: "idle"
    property string detailMessage: ""
    property var unitDetail: ({})
    readonly property bool detailBusy: detailPoll.busy
    property double detailLastUpdatedMs: 0
    property bool detailPermissionLimited: false
    property bool detailDegraded: false
    property var lastGoodUnitDetail: ({})
    property var pendingActions: ({})
    property string lastActionScope: ""
    property string lastActionUnitName: ""
    property string lastActionState: "idle"
    property string lastActionMessage: ""
    property double lastActionAt: 0

    function _dockerCommand() {
        return ["sh", "-c", "if command -v docker >/dev/null 2>&1; then " +
                              "  runtime='docker'; " +
                              "elif command -v podman >/dev/null 2>&1; then " +
                              "  runtime='podman'; " +
                              "else " +
                              "  printf '__STATUS__\\tmissing\\tDocker or Podman not found\\n'; exit 0; " +
                              "fi; " +
                              "if ! output=$($runtime ps -a --format '{{.ID}}\\t{{.Names}}\\t{{.Status}}\\t{{.Image}}\\t{{.State}}' 2>/dev/null); then " +
                              "  printf '__STATUS__\\terror\\tUnable to query %s containers\\n' \"$runtime\"; exit 0; " +
                              "fi; " +
                              "printf '__STATUS__\\tready\\t\\n'; " +
                              "printf '%s\\n' \"$output\""];
    }

    function _parseDockerSnapshot(out) {
        var text = String(out || "").trim();
        if (text === "") return { status: "ready", message: "", containers: [] };
        var lines = text.split("\n");
        var first = String(lines[0] || "");
        var status = "ready";
        var message = "";
        if (first.indexOf("__STATUS__\t") === 0) {
            var meta = first.split("\t");
            status = String(meta[1] || "ready");
            message = String(meta[2] || "");
            lines.shift();
        }
        var containers = [];
        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i] || "").trim();
            if (line === "") continue;
            var parts = line.split("\t");
            if (parts.length < 5) continue;
            containers.push({
                id: parts[0], name: parts[1], status: parts[2], image: parts[3], state: parts[4]
            });
        }
        return { status: status, message: message, containers: containers };
    }

    function runDockerAction(containerId, action) {
        _actionScope = "docker";
        _actionUnitName = containerId;
        _actionTitle = "Container " + action;
        _actionSuccessMessage = "Container " + containerId + " " + action + " successful.";
        _actionFailureMessage = "Failed to " + action + " container " + containerId;
        _actionCommand = ["sh", "-c", "runtime=$(command -v docker || command -v podman); if [ -n \"$runtime\" ]; then \"$runtime\" " + action + " " + containerId + "; else exit 1; fi"];
        _setPending(_actionScope, _actionUnitName, action);
        actionProc.command = _actionCommand;
        actionProc.running = true;
    }

    property var dockerPoll: CommandPoll {
        id: dockerPoll
        interval: Math.max(3000, root.pollIntervalMs)
        running: root.subscriberCount > 0
        command: root._dockerCommand()
        parse: function(out) { return root._parseDockerSnapshot(out); }
        onUpdated: {
            var snapshot = dockerPoll.value || {};
            root.dockerStatus = snapshot.status;
            root.dockerMessage = snapshot.message;
            root.dockerContainers = snapshot.containers || [];
        }
    }

    property string _actionScope: "user"
    property string _actionUnitName: ""
    property string _actionTitle: ""
    property string _actionSuccessMessage: ""
    property string _actionFailureMessage: ""
    property var _actionCommand: []
    property bool _actionNeedsStdin: false
    property string _actionStdin: ""

    function _unitsCommand(scope) {
        var prefix = scope === "system" ? "systemctl" : "systemctl --user";
        var label = scope === "system" ? "system" : "user";
        return ["sh", "-c", "if ! command -v systemctl >/dev/null 2>&1; then printf '__STATUS__\\tmissing\\tsystemctl is not installed\\n'; exit 0; fi; " + "if ! output=$(" + prefix + " list-units --type=service --all --plain --no-legend --no-pager 2>/dev/null); then " + "printf '__STATUS__\\terror\\tUnable to query " + label + " services\\n'; exit 0; fi; " + "printf '__STATUS__\\tready\\t\\n'; " + "printf '%s\\n' \"$output\" | awk 'BEGIN{OFS=\"\\t\"} NF >= 4 {unit=$1; load=$2; active=$3; substate=$4; $1=$2=$3=$4=\"\"; sub(/^[ \\t]+/, \"\", $0); print unit,load,active,substate,$0}'"];
    }

    function _parseUnitSnapshot(out) {
        var text = String(out || "").trim();
        if (text === "")
            return {
                status: "error",
                message: "No service data returned.",
                units: []
            };

        var lines = text.split("\n");
        var first = String(lines[0] || "");
        var status = "ready";
        var message = "";
        if (first.indexOf("__STATUS__\t") === 0) {
            var meta = first.split("\t");
            status = String(meta[1] || "ready");
            message = String(meta[2] || "");
            lines.shift();
        }

        var units = [];
        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i] || "").trim();
            if (line === "")
                continue;
            var parts = line.split("\t");
            if (parts.length < 5)
                continue;
            units.push({
                name: String(parts[0] || ""),
                load: String(parts[1] || ""),
                active: String(parts[2] || ""),
                sub: String(parts[3] || ""),
                description: String(parts.slice(4).join("\t") || "")
            });
        }

        return {
            status: status,
            message: message,
            units: units
        };
    }

    property var sshSessions: []
    property string sshStatus: "ready"
    property string sshMessage: ""
    property int sshActiveCount: sshSessions.length

    function _sshCommand() {
        return ["sh", "-c", "if ! command -v who >/dev/null 2>&1; then printf '__STATUS__\\tmissing\\twho command not found\\n'; exit 0; fi; " +
                              "output=$(who | grep 'pts/' | awk '{print $1 \"@\" $5}' | sed 's/[()]//g' 2>/dev/null); " +
                              "printf '__STATUS__\\tready\\t\\n'; printf '%s\\n' \"$output\""];
    }

    function _parseSshSnapshot(out) {
        var text = String(out || "").trim();
        if (text === "") return { status: "ready", message: "", sessions: [] };
        var lines = text.split("\n");
        var first = String(lines[0] || "");
        var status = "ready";
        var message = "";
        if (first.indexOf("__STATUS__\t") === 0) {
            var meta = first.split("\t");
            status = String(meta[1] || "ready");
            message = String(meta[2] || "");
            lines.shift();
        }
        var sessions = [];
        for (var i = 0; i < lines.length; i++) {
            var s = String(lines[i] || "").trim();
            if (s !== "") sessions.push(s);
        }
        return { status: status, message: message, sessions: sessions };
    }

    property var sshPoll: CommandPoll {
        id: sshPoll
        interval: 10000
        running: root.subscriberCount > 0
        command: root._sshCommand()
        parse: function(out) { return root._parseSshSnapshot(out); }
        onUpdated: {
            var snapshot = sshPoll.value || {};
            root.sshStatus = snapshot.status || "ready";
            root.sshMessage = snapshot.message || "";
            root.sshSessions = snapshot.sessions || [];
        }
    }

    function refresh() {
        userPoll.triggerPoll();
        systemPoll.triggerPoll();
        dockerPoll.triggerPoll();
        sshPoll.triggerPoll();
        refreshDetail();
    }

    function _clearDetail() {
        detailScope = "";
        detailUnitName = "";
        detailStatus = "idle";
        detailMessage = "";
        unitDetail = ({});
        detailLastUpdatedMs = 0;
        detailPermissionLimited = false;
        detailDegraded = false;
        lastGoodUnitDetail = ({});
    }

    function _detailCommand(scope, unitName) {
        var safeScope = scope === "system" ? "system" : "user";
        var safeUnit = String(unitName || "");
        var prefix = safeScope === "system" ? "systemctl" : "systemctl --user";
        var journalPrefix = safeScope === "system" ? "journalctl -u " : "journalctl --user -u ";
        return ["sh", "-c", "scope=\"$1\"; unit=\"$2\"; prefix=\"$3\"; journalPrefix=\"$4\"; " +
                              "if [ -z \"$unit\" ]; then printf '__STATUS__\\tidle\\tNo service selected\\n'; exit 0; fi; " +
                              "if ! command -v systemctl >/dev/null 2>&1; then printf '__STATUS__\\tmissing\\tsystemctl is not installed\\n'; exit 0; fi; " +
                              "status='ready'; message=''; permissionLimited=0; degraded=0; " +
                              "showOutput=$($prefix show \"$unit\" -p Description -p ActiveState -p SubState -p MainPID -p ExecMainStatus -p FragmentPath -p ActiveEnterTimestamp -p TasksCurrent -p MemoryCurrent 2>&1); showStatus=$?; " +
                              "if [ \"$showStatus\" -ne 0 ]; then " +
                              "  case \"$showOutput\" in " +
                              "    *'not found'*|*'could not be found'*) printf '__STATUS__\\tmissing\\tUnit not found\\n'; printf 'scope\\t%s\\nname\\t%s\\n' \"$scope\" \"$unit\"; exit 0 ;; " +
                              "    *) printf '__STATUS__\\terror\\tUnable to query unit detail\\n'; printf 'scope\\t%s\\nname\\t%s\\n' \"$scope\" \"$unit\"; exit 0 ;; " +
                              "  esac; " +
                              "fi; " +
                              "logOutput=$($journalPrefix\"$unit\" -n 20 --no-pager -o short-iso 2>/dev/null); logStatus=$?; " +
                              "if [ \"$logStatus\" -ne 0 ]; then permissionLimited=1; degraded=1; message='Recent logs unavailable'; fi; " +
                              "if [ \"$permissionLimited\" -eq 1 ]; then status='permission-limited'; fi; " +
                              "printf '__STATUS__\\t%s\\t%s\\n' \"$status\" \"$message\"; " +
                              "printf 'scope\\t%s\\n' \"$scope\"; " +
                              "printf 'name\\t%s\\n' \"$unit\"; " +
                              "printf 'permissionLimited\\t%s\\n' \"$permissionLimited\"; " +
                              "printf 'degraded\\t%s\\n' \"$degraded\"; " +
                              "printf '%s\\n' \"$showOutput\" | awk -F= 'BEGIN{OFS=\"\\t\"} {key=$1; sub(/^[^=]*=/, \"\", $0); print key, $0}'; " +
                              "printf '%s\\n' \"$logOutput\" | while IFS= read -r line; do [ -n \"$line\" ] && printf 'log\\t%s\\n' \"$line\"; done;", "sh", safeScope, safeUnit, prefix, journalPrefix];
    }

    function _mergeDetailSnapshot(snapshot) {
        return {
            name: String(snapshot.name || detailUnitName || ""),
            scope: String(snapshot.scope || detailScope || ""),
            description: String(snapshot.Description || ""),
            activeState: String(snapshot.ActiveState || ""),
            subState: String(snapshot.SubState || ""),
            mainPid: snapshot.MainPID !== undefined ? snapshot.MainPID : null,
            execMainStatus: snapshot.ExecMainStatus !== undefined ? snapshot.ExecMainStatus : null,
            fragmentPath: String(snapshot.FragmentPath || ""),
            activeEnterTimestamp: String(snapshot.ActiveEnterTimestamp || ""),
            tasksCurrent: snapshot.TasksCurrent !== undefined ? snapshot.TasksCurrent : null,
            memoryCurrent: snapshot.MemoryCurrent !== undefined ? snapshot.MemoryCurrent : null,
            recentLogs: snapshot.recentLogs || []
        };
    }

    function setDetailUnit(scope, unitName) {
        var safeUnit = String(unitName || "");
        if (safeUnit === "") {
            _clearDetail();
            return;
        }
        detailScope = scope === "system" ? "system" : "user";
        detailUnitName = safeUnit;
        detailStatus = "loading";
        detailMessage = "Loading unit detail...";
        unitDetail = {
            name: detailUnitName,
            scope: detailScope
        };
        detailLastUpdatedMs = 0;
        detailPermissionLimited = false;
        detailDegraded = false;
        detailPoll.triggerPoll();
    }

    function refreshDetail() {
        if (detailUnitName === "")
            return;
        detailPoll.triggerPoll();
    }

    function parseDetailSnapshot(out) {
        var text = String(out || "").trim();
        if (text === "")
            return {
                scope: detailScope,
                name: detailUnitName,
                status: "error",
                message: "No unit detail returned.",
                recentLogs: []
            };

        var lines = text.split("\n");
        var first = String(lines[0] || "");
        var status = "ready";
        var message = "";
        if (first.indexOf("__STATUS__\t") === 0) {
            var meta = first.split("\t");
            status = String(meta[1] || "ready");
            message = String(meta.slice(2).join("\t") || "");
            lines.shift();
        }

        var result = {
            scope: detailScope,
            name: detailUnitName,
            status: status,
            message: message,
            recentLogs: [],
            permissionLimited: false,
            degraded: false
        };

        function parseOptionalInt(value) {
            if (value === undefined || value === null || String(value) === "")
                return null;
            return parseInt(value, 10);
        }

        function parseOptionalBool(value) {
            if (value === undefined || value === null || String(value) === "")
                return false;
            return String(value) === "1" || String(value).toLowerCase() === "true";
        }

        for (var i = 0; i < lines.length; ++i) {
            var line = String(lines[i] || "");
            if (line === "")
                continue;
            var parts = line.split("\t");
            if (parts.length < 2)
                continue;
            var key = parts[0];
            var value = parts.slice(1).join("\t");
            if (key === "log") {
                result.recentLogs.push(value);
                continue;
            }
            if (key === "permissionLimited" || key === "degraded") {
                result[key] = parseOptionalBool(value);
                continue;
            }
            if (key === "MainPID" || key === "ExecMainStatus" || key === "TasksCurrent" || key === "MemoryCurrent")
                result[key] = parseOptionalInt(value);
            else
                result[key] = value;
        }

        return result;
    }

    function pendingActionForUnit(scope, unitName) {
        return pendingActions[String(scope) + ":" + String(unitName)] || "";
    }

    function isUnitPending(scope, unitName) {
        return pendingActionForUnit(scope, unitName) !== "";
    }

    function _setPending(scope, unitName, actionName) {
        var key = String(scope) + ":" + String(unitName);
        var next = Object.assign({}, pendingActions || {});
        if (actionName)
            next[key] = String(actionName);
        else
            delete next[key];
        pendingActions = next;
    }

    function _runUnitAction(scope, unitName, actionName) {
        if (!unitName)
            return false;
        if (actionProc.running) {
            ToastService.showNotice("Action pending", "Wait for the current service action to finish.");
            return false;
        }

        lastActionScope = String(scope || "user");
        lastActionUnitName = String(unitName);
        lastActionState = "pending";
        lastActionMessage = String(actionName || "action").toUpperCase() + " running...";
        lastActionAt = Date.now();
        var command = ["systemctl"];
        if (scope !== "system")
            command.push("--user");
        command.push(actionName);
        command.push(String(unitName));

        _actionScope = String(scope || "user");
        _actionUnitName = String(unitName);
        _actionTitle = "Service updated";
        _actionSuccessMessage = String(unitName) + " " + String(actionName) + " completed.";
        _actionFailureMessage = "Unable to " + String(actionName) + " " + String(unitName) + ".";
        _actionNeedsStdin = false;
        _actionStdin = "";
        _actionCommand = command;
        _setPending(_actionScope, _actionUnitName, actionName);
        actionProc.command = _actionCommand;
        actionProc.running = true;
        return true;
    }

    function _runClipboardAction(scope, unitName, text, successMessage) {
        if (!unitName)
            return false;
        if (actionProc.running) {
            ToastService.showNotice("Action pending", "Wait for the current service action to finish.");
            return false;
        }

        lastActionScope = String(scope || "user");
        lastActionUnitName = String(unitName);
        lastActionState = "pending";
        lastActionMessage = "COPY running...";
        lastActionAt = Date.now();
        _actionScope = String(scope || "user");
        _actionUnitName = String(unitName);
        _actionTitle = "Copied";
        _actionSuccessMessage = String(successMessage || "Copied to clipboard.");
        _actionFailureMessage = "No clipboard utility found (wl-copy/xclip).";
        _actionNeedsStdin = true;
        _actionStdin = String(text || "");
        _actionCommand = ["sh", "-c", "if command -v wl-copy >/dev/null 2>&1; then cat | wl-copy; elif command -v xclip >/dev/null 2>&1; then cat | xclip -selection clipboard; else exit 1; fi"];
        _setPending(_actionScope, _actionUnitName, "copy");
        actionProc.command = _actionCommand;
        actionProc.running = true;
        return true;
    }

    function startUnit(scope, unitName) {
        return _runUnitAction(scope, unitName, "start");
    }

    function stopUnit(scope, unitName) {
        return _runUnitAction(scope, unitName, "stop");
    }

    function restartUnit(scope, unitName) {
        return _runUnitAction(scope, unitName, "restart");
    }

    function reloadUnit(scope, unitName) {
        return _runUnitAction(scope, unitName, "reload");
    }

    function copyUnitName(scope, unitName) {
        return _runClipboardAction(scope, unitName, String(unitName || ""), "Unit name copied to clipboard.");
    }

    function copyUnitFragmentPath(scope, unitName) {
        if (String(scope || "") !== detailScope || String(unitName || "") !== detailUnitName)
            return false;
        return _runClipboardAction(scope, unitName, String(unitDetail.fragmentPath || ""), "Unit fragment path copied to clipboard.");
    }

    function getLogStreamCommand(scope, id) {
        if (scope === "docker") {
            return ["sh", "-c", "runtime=$(command -v docker || command -v podman); if [ -n \"$runtime\" ]; then exec \"$runtime\" logs -f --tail 100 " + id + "; else exit 1; fi"];
        }
        var prefix = scope === "system" ? ["journalctl", "-u"] : ["journalctl", "--user", "-u"];
        return prefix.concat([id, "-f", "-n", "100"]);
    }

    function openUnitLogsInTerminal(scope, unitName) {
        if (!unitName)
            return false;

        var prefix = scope === "system" ? "journalctl -u " : "journalctl --user -u ";
        var cmd = prefix + String(unitName) + " -n 120 --no-pager; echo; read -n 1 -s -r -p \"Press any key to close\"";
        Quickshell.execDetached(SU.terminalCommand(cmd));
        return true;
    }

    function openUnitStatusInTerminal(scope, unitName) {
        if (!unitName)
            return false;

        var prefix = scope === "system" ? "systemctl status " : "systemctl --user status ";
        var cmd = prefix + String(unitName) + " --no-pager; echo; read -n 1 -s -r -p \"Press any key to close\"";
        Quickshell.execDetached(SU.terminalCommand(cmd));
        return true;
    }


    property CommandPoll userPoll: CommandPoll {
        id: userPoll
        interval: Math.max(1500, root.pollIntervalMs)
        running: root.subscriberCount > 0
        command: root._unitsCommand("user")
        parse: function (out) {
            return root._parseUnitSnapshot(out);
        }
        onUpdated: {
            var snapshot = userPoll.value || {};
            root.userStatus = String(snapshot.status || "error");
            root.userMessage = String(snapshot.message || "");
            root.userUnits = snapshot.units || [];
        }
    }

    property CommandPoll systemPoll: CommandPoll {
        id: systemPoll
        interval: Math.max(1500, root.pollIntervalMs)
        running: root.subscriberCount > 0
        command: root._unitsCommand("system")
        parse: function (out) {
            return root._parseUnitSnapshot(out);
        }
        onUpdated: {
            var snapshot = systemPoll.value || {};
            root.systemStatus = String(snapshot.status || "error");
            root.systemMessage = String(snapshot.message || "");
            root.systemUnits = snapshot.units || [];
        }
    }

    property CommandPoll detailPoll: CommandPoll {
        id: detailPoll
        interval: Math.max(1500, root.detailPollIntervalMs)
        running: root.subscriberCount > 0 && root.detailUnitName !== ""
        command: root._detailCommand(root.detailScope, root.detailUnitName)
        parse: function(out) {
            return root.parseDetailSnapshot(out);
        }
        onUpdated: {
            var snapshot = detailPoll.value || {};
            if (String(snapshot.scope || "") !== root.detailScope || String(snapshot.name || "") !== root.detailUnitName)
                return;
            var nextStatus = String(snapshot.status || "ready");
            var nextMessage = String(snapshot.message || "");
            var hasCached = String(root.lastGoodUnitDetail.scope || "") === root.detailScope
                && String(root.lastGoodUnitDetail.name || "") === root.detailUnitName;
            var nextDetail = root._mergeDetailSnapshot(snapshot);

            root.detailLastUpdatedMs = Date.now();
            root.detailPermissionLimited = !!snapshot.permissionLimited || nextStatus === "permission-limited";
            root.detailDegraded = !!snapshot.degraded || nextStatus === "error" || nextStatus === "permission-limited";

            if (nextStatus === "error" && hasCached) {
                root.detailStatus = "error";
                root.detailMessage = nextMessage !== "" ? nextMessage + " Showing last successful detail." : "Detail refresh failed. Showing last successful detail.";
                root.unitDetail = root.lastGoodUnitDetail;
                root.detailDegraded = true;
                return;
            }

            root.detailStatus = nextStatus;
            root.detailMessage = nextMessage;
            root.unitDetail = nextDetail;
            if (nextStatus === "ready" || nextStatus === "permission-limited")
                root.lastGoodUnitDetail = nextDetail;
        }
    }

    property Process actionProc: Process {
        id: actionProc
        command: root._actionCommand
        running: false
        stdinEnabled: true
        onStarted: {
            if (root._actionNeedsStdin) {
                actionProc.write(root._actionStdin);
                actionProc.stdinEnabled = false;
            }
        }
        onExited: (exitCode, exitStatus) => {
            root._setPending(root._actionScope, root._actionUnitName, "");
            root.lastActionScope = root._actionScope;
            root.lastActionUnitName = root._actionUnitName;
            root.lastActionState = exitCode === 0 ? "success" : "error";
            root.lastActionMessage = exitCode === 0 ? root._actionSuccessMessage : root._actionFailureMessage;
            root.lastActionAt = Date.now();
            if (exitCode === 0)
                ToastService.showSuccess(root._actionTitle, root._actionSuccessMessage);
            else
                ToastService.showError(root._actionTitle, root._actionFailureMessage);
            actionRefresh.restart();
            actionRefreshDelayed.restart();
        }
    }

    property Timer actionRefresh: Timer {
        id: actionRefresh
        interval: 120
        repeat: false
        onTriggered: root.refresh()
    }

    property Timer actionRefreshDelayed: Timer {
        id: actionRefreshDelayed
        interval: 800
        repeat: false
        onTriggered: root.refresh()
    }
}
