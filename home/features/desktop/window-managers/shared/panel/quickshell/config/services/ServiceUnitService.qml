pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../widgets" as SharedWidgets

QtObject {
    id: root

    property int subscriberCount: 0
    property int pollIntervalMs: 5000
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
    property var pendingActions: ({})

    function _dockerCommand() {
        return ["sh", "-c", "if ! command -v docker >/dev/null 2>&1; then printf '__STATUS__\\tmissing\\tdocker is not installed\\n'; exit 0; fi; " + "if ! output=$(docker ps -a --format '{{.ID}}\\t{{.Names}}\\t{{.Status}}\\t{{.Image}}\\t{{.State}}' 2>/dev/null); then " + "printf '__STATUS__\\terror\\tUnable to query docker containers\\n'; exit 0; fi; " + "printf '__STATUS__\\tready\\t\\n'; " + "printf '%s\\n' \"$output\""];
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
            var parts = lines[i].split("\t");
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
        _actionCommand = ["docker", action, containerId];
        _setPending(_actionScope, _actionUnitName, action);
        actionProc.command = _actionCommand;
        actionProc.running = true;
    }

    property SharedWidgets.CommandPoll dockerPoll: SharedWidgets.CommandPoll {
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

    property SharedWidgets.CommandPoll sshPoll: SharedWidgets.CommandPoll {
        id: sshPoll
        interval: 10000
        running: root.subscriberCount > 0
        command: ["sh", "-c", "who | grep 'pts/' | awk '{print $1 \"@\" $5}' | sed 's/[()]//g'"]
        parse: function(out) {
            var lines = String(out || "").trim().split("\n");
            var result = [];
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].trim()) result.push(lines[i].trim());
            }
            return result;
        }
        onUpdated: root.sshSessions = sshPoll.value || []
    }

    function refresh() {
        userPoll.triggerPoll();
        systemPoll.triggerPoll();
        dockerPoll.triggerPoll();
        sshPoll.triggerPoll();
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

    function getLogStreamCommand(scope, id) {
        if (scope === "docker") {
            return ["docker", "logs", "-f", "--tail", "100", id];
        }
        var prefix = scope === "system" ? ["journalctl", "-u"] : ["journalctl", "--user", "-u"];
        return prefix.concat([id, "-f", "-n", "100"]);
    }

    function openUnitLogsInTerminal(scope, unitName) {
        if (!unitName)
            return false;

        var prefix = scope === "system" ? "journalctl -u " : "journalctl --user -u ";
        Quickshell.execDetached(["kitty", "-e", "bash", "-lc", prefix + String(unitName) + " -n 120 --no-pager; echo; read -n 1 -s -r -p \"Press any key to close\""]);
        return true;
    }

    function openUnitStatusInTerminal(scope, unitName) {
        if (!unitName)
            return false;

        var prefix = scope === "system" ? "systemctl status " : "systemctl --user status ";
        Quickshell.execDetached(["kitty", "-e", "bash", "-lc", prefix + String(unitName) + " --no-pager; echo; read -n 1 -s -r -p \"Press any key to close\""]);
        return true;
    }

    property SharedWidgets.CommandPoll userPoll: SharedWidgets.CommandPoll {
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

    property SharedWidgets.CommandPoll systemPoll: SharedWidgets.CommandPoll {
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
