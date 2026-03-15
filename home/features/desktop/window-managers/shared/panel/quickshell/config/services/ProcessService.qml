pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../widgets" as SharedWidgets

QtObject {
    id: root

    property int subscriberCount: 0
    property int pollIntervalMs: 3000
    property int snapshotLimit: 60
    property string sortBy: "cpu"
    property var processes: []
    property bool busy: processPoll.busy
    property double lastRefreshAt: 0
    property var pendingActions: ({})

    property int _actionPid: 0
    property string _actionKey: ""
    property string _actionTitle: ""
    property string _actionSuccessMessage: ""
    property string _actionFailureMessage: ""
    property bool _actionNeedsStdin: false
    property string _actionStdin: ""
    property var _actionCommand: []

    function snapshotCommand() {
        var sortField = sortBy === "mem" ? "-pmem" : "-pcpu";
        return ["sh", "-c", "ps -eo pid=,ppid=,ni=,user=,stat=,etime=,pcpu=,pmem=,comm=,args= --sort=" + sortField + " | awk 'BEGIN{OFS=\"\\t\"} {pid=$1; ppid=$2; nice=$3; user=$4; state=$5; etime=$6; cpu=$7; mem=$8; comm=$9; $1=$2=$3=$4=$5=$6=$7=$8=$9=\"\"; sub(/^[ \\t]+/, \"\", $0); print pid,ppid,nice,user,state,etime,cpu,mem,comm,$0}' | head -n " + String(snapshotLimit)];
    }

    function parseSnapshot(out) {
        var lines = String(out || "").trim().split("\n");
        var result = [];
        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i] || "").trim();
            if (line === "")
                continue;

            var parts = line.split("\t");
            if (parts.length < 10)
                continue;

            result.push({
                pid: parseInt(parts[0], 10) || 0,
                parentPid: parseInt(parts[1], 10) || 0,
                nice: parseInt(parts[2], 10) || 0,
                user: String(parts[3] || ""),
                state: String(parts[4] || ""),
                elapsed: String(parts[5] || ""),
                cpu: Number(parts[6]) || 0,
                mem: Number(parts[7]) || 0,
                name: String(parts[8] || ""),
                command: String(parts.slice(9).join("\t") || "")
            });
        }
        return result;
    }

    function refresh() {
        processPoll.poll();
    }

    function processByPid(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return null;

        for (var i = 0; i < processes.length; i++) {
            if ((processes[i].pid || 0) === safePid)
                return processes[i];
        }
        return null;
    }

    function pendingActionForPid(pid) {
        return pendingActions[String(parseInt(pid, 10) || 0)] || "";
    }

    function isPidPending(pid) {
        return pendingActionForPid(pid) !== "";
    }

    function _setPending(pid, actionName) {
        var safePid = parseInt(pid, 10) || 0;
        var next = Object.assign({}, pendingActions || {});
        if (safePid > 0 && actionName)
            next[String(safePid)] = String(actionName);
        else
            delete next[String(safePid)];
        pendingActions = next;
    }

    function _scheduleRefresh() {
        immediateRefresh.restart();
        settleRefresh.restart();
    }

    function _runPidAction(pid, actionName, command, title, successMessage, failureMessage) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return false;
        if (actionProc.running) {
            ToastService.showNotice("Action pending", "Wait for the current process action to finish.");
            return false;
        }

        _actionPid = safePid;
        _actionKey = String(safePid);
        _actionTitle = String(title || "Process action");
        _actionSuccessMessage = String(successMessage || "Action completed.");
        _actionFailureMessage = String(failureMessage || "Action failed.");
        _actionNeedsStdin = false;
        _actionStdin = "";
        _actionCommand = command || [];
        _setPending(safePid, actionName);
        actionProc.command = _actionCommand;
        actionProc.running = true;
        return true;
    }

    function _runClipboardAction(pid, text, successMessage) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return false;
        if (actionProc.running) {
            ToastService.showNotice("Action pending", "Wait for the current process action to finish.");
            return false;
        }

        _actionPid = safePid;
        _actionKey = String(safePid);
        _actionTitle = "Copied";
        _actionSuccessMessage = String(successMessage || "Copied to clipboard.");
        _actionFailureMessage = "No clipboard utility found (wl-copy/xclip).";
        _actionNeedsStdin = true;
        _actionStdin = String(text || "");
        _actionCommand = ["sh", "-c", "if command -v wl-copy >/dev/null 2>&1; then cat | wl-copy; elif command -v xclip >/dev/null 2>&1; then cat | xclip -selection clipboard; else exit 1; fi"];
        _setPending(safePid, "copy");
        actionProc.command = _actionCommand;
        actionProc.running = true;
        return true;
    }

    function terminateProcess(pid) {
        return _runPidAction(pid, "term", ["kill", "-TERM", String(pid)], "Process terminated", "SIGTERM sent to PID " + String(pid) + ".", "Unable to terminate PID " + String(pid) + ".");
    }

    function killProcess(pid) {
        return _runPidAction(pid, "kill", ["kill", "-KILL", String(pid)], "Process killed", "SIGKILL sent to PID " + String(pid) + ".", "Unable to kill PID " + String(pid) + ".");
    }

    function togglePause(pid) {
        var process = processByPid(pid);
        if (!process)
            return false;
        var isStopped = String(process.state || "").indexOf("T") !== -1;
        return _runPidAction(pid, isStopped ? "resume" : "suspend", ["kill", isStopped ? "-CONT" : "-STOP", String(pid)], isStopped ? "Process resumed" : "Process suspended", (isStopped ? "SIGCONT" : "SIGSTOP") + " sent to PID " + String(pid) + ".", "Unable to change the run state for PID " + String(pid) + ".");
    }

    function reniceProcess(pid, niceValue) {
        var safePid = parseInt(pid, 10) || 0;
        var nextNice = Math.max(-20, Math.min(19, parseInt(niceValue, 10) || 0));
        return _runPidAction(safePid, "renice", ["renice", "-n", String(nextNice), "-p", String(safePid)], "Priority updated", "PID " + String(safePid) + " now targets nice " + String(nextNice) + ".", "Unable to update priority for PID " + String(safePid) + ".");
    }

    function copyPid(pid) {
        return _runClipboardAction(pid, String(parseInt(pid, 10) || 0), "PID copied to clipboard.");
    }

    function copyCommand(pid) {
        var process = processByPid(pid);
        if (!process)
            return false;
        return _runClipboardAction(pid, String(process.command || process.name || ""), "Process command copied to clipboard.");
    }

    function openProcessInTerminal(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return false;
        Quickshell.execDetached(["kitty", "-e", "bash", "-lc", "if command -v htop >/dev/null 2>&1; then exec htop -p " + String(safePid) + "; else exec top -p " + String(safePid) + "; fi"]);
        return true;
    }

    function openProcessDetailsInTerminal(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return false;
        Quickshell.execDetached(["kitty", "-e", "bash", "-lc", "if command -v lsof >/dev/null 2>&1; then lsof -p " + String(safePid) + "; else ps -fp " + String(safePid) + "; echo; echo \"lsof not available\"; fi; echo; read -n 1 -s -r -p \"Press any key to close\""]);
        return true;
    }

    property SharedWidgets.CommandPoll processPoll: SharedWidgets.CommandPoll {
        id: processPoll
        interval: Math.max(750, root.pollIntervalMs)
        running: root.subscriberCount > 0
        command: root.snapshotCommand()
        parse: function (out) {
            return root.parseSnapshot(out);
        }
        onUpdated: {
            root.processes = processPoll.value || [];
            root.lastRefreshAt = Date.now();
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
            var pid = root._actionPid;
            root._setPending(pid, "");
            if (exitCode === 0)
                ToastService.showSuccess(root._actionTitle, root._actionSuccessMessage);
            else
                ToastService.showError(root._actionTitle, root._actionFailureMessage);
            root._scheduleRefresh();
        }
    }

    property Timer immediateRefresh: Timer {
        id: immediateRefresh
        interval: 120
        repeat: false
        onTriggered: root.refresh()
    }

    property Timer settleRefresh: Timer {
        id: settleRefresh
        interval: 700
        repeat: false
        onTriggered: root.refresh()
    }
}
