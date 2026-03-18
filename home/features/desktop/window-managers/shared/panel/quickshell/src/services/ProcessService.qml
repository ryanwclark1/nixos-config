pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "ShellUtils.js" as SU

QtObject {
    id: root

    property int subscriberCount: 0
    property int pollIntervalMs: 5000
    property int snapshotLimit: 60
    property string sortBy: "cpu"
    property var processes: []
    property bool busy: processPoll.busy
    property int detailPollIntervalMs: 10000
    property int detailPid: 0
    property string detailStatus: "idle"
    property string detailMessage: ""
    property var processDetail: ({})
    readonly property bool detailBusy: detailPoll.busy
    property double detailLastUpdatedMs: 0
    property bool detailPermissionLimited: false
    property bool detailDegraded: false
    property var lastGoodProcessDetail: ({})
    property double lastRefreshAt: 0
    property var pendingActions: ({})
    property int lastActionPid: 0
    property string lastActionState: "idle"
    property string lastActionMessage: ""
    property double lastActionAt: 0

    property int _actionPid: 0
    property string _actionKey: ""
    property string _actionTitle: ""
    property string _actionSuccessMessage: ""
    property string _actionFailureMessage: ""
    property bool _actionNeedsStdin: false
    property string _actionStdin: ""
    property var _actionCommand: []

    function _detailCommand(pid) {
        var safePid = parseInt(pid, 10) || 0;
        return ["sh", "-c", "pid=\"$1\"; proc=\"/proc/$pid\"; " +
                              "if [ -z \"$pid\" ] || [ \"$pid\" -le 0 ] 2>/dev/null; then printf '__STATUS__\\tidle\\tNo process selected\\n'; printf 'pid\\t0\\n'; exit 0; fi; " +
                              "if [ ! -d \"$proc\" ]; then printf '__STATUS__\\tterminated\\tProcess exited\\n'; printf 'pid\\t%s\\n' \"$pid\"; exit 0; fi; " +
                              "status='ready'; message=''; permissionLimited=0; degraded=0; " +
                              "cwd=$(readlink \"$proc/cwd\" 2>/dev/null || true); " +
                              "if [ -z \"$cwd\" ]; then message='cwd unavailable'; permissionLimited=1; degraded=1; fi; " +
                              "exe=$(readlink \"$proc/exe\" 2>/dev/null || true); " +
                              "if [ -z \"$exe\" ]; then permissionLimited=1; degraded=1; if [ -n \"$message\" ]; then message=\"$message; exe unavailable\"; else message='exe unavailable'; fi; fi; " +
                              "fdCount=$(find \"$proc/fd\" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' '); " +
                              "readBytes=''; writeBytes=''; cancelledWriteBytes=''; " +
                              "if [ -r \"$proc/io\" ]; then " +
                              "  readBytes=$(awk '/^read_bytes:/ {print $2}' \"$proc/io\" 2>/dev/null); " +
                              "  writeBytes=$(awk '/^write_bytes:/ {print $2}' \"$proc/io\" 2>/dev/null); " +
                              "  cancelledWriteBytes=$(awk '/^cancelled_write_bytes:/ {print $2}' \"$proc/io\" 2>/dev/null); " +
                              "else " +
                              "  permissionLimited=1; degraded=1; " +
                              "  if [ -n \"$message\" ]; then message=\"$message; io unavailable\"; else message='io unavailable'; fi; " +
                              "fi; " +
                              "if [ ! -r \"$proc/status\" ]; then permissionLimited=1; degraded=1; fi; " +
                              "if [ \"$permissionLimited\" -eq 1 ]; then status='permission-limited'; fi; " +
                              "printf '__STATUS__\\t%s\\t%s\\n' \"$status\" \"$message\"; " +
                              "printf 'pid\\t%s\\n' \"$pid\"; " +
                              "printf 'permissionLimited\\t%s\\n' \"$permissionLimited\"; " +
                              "printf 'degraded\\t%s\\n' \"$degraded\"; " +
                              "printf 'cwd\\t%s\\n' \"$cwd\"; " +
                              "printf 'exe\\t%s\\n' \"$exe\"; " +
                              "printf 'fdCount\\t%s\\n' \"$fdCount\"; " +
                              "printf 'readBytes\\t%s\\n' \"$readBytes\"; " +
                              "printf 'writeBytes\\t%s\\n' \"$writeBytes\"; " +
                              "printf 'cancelledWriteBytes\\t%s\\n' \"$cancelledWriteBytes\"; " +
                              "if [ -r \"$proc/status\" ]; then " +
                              "  printf 'threads\\t%s\\n' \"$(awk '/^Threads:/ {print $2}' \"$proc/status\" 2>/dev/null)\"; " +
                              "  printf 'vmRssKb\\t%s\\n' \"$(awk '/^VmRSS:/ {print $2}' \"$proc/status\" 2>/dev/null)\"; " +
                              "  printf 'voluntaryCtxtSwitches\\t%s\\n' \"$(awk '/^voluntary_ctxt_switches:/ {print $2}' \"$proc/status\" 2>/dev/null)\"; " +
                              "  printf 'nonvoluntaryCtxtSwitches\\t%s\\n' \"$(awk '/^nonvoluntary_ctxt_switches:/ {print $2}' \"$proc/status\" 2>/dev/null)\"; " +
                              "fi; " +
                              "if [ -d \"$proc/fd\" ]; then " +
                              "  for fdPath in $(find \"$proc/fd\" -mindepth 1 -maxdepth 1 2>/dev/null | sort -V | head -n 8); do " +
                              "    fdName=$(basename \"$fdPath\"); target=$(readlink \"$fdPath\" 2>/dev/null || true); " +
                              "    printf 'openFile\\t%s\\t%s\\n' \"$fdName\" \"$target\"; " +
                              "  done; " +
                              "fi;", "sh", String(safePid)];
    }

    function snapshotCommand() {
        var sortField = sortBy === "mem" ? "-pmem" : "-pcpu";
        return ["sh", "-c", "ps -eo pid=,ppid=,ni=,nlwp=,rss=,tty=,user=,stat=,etime=,pcpu=,pmem=,comm=,args= --sort=" + sortField + " | awk 'BEGIN{OFS=\"\\t\"} {pid=$1; ppid=$2; nice=$3; nlwp=$4; rss=$5; tty=$6; user=$7; state=$8; etime=$9; cpu=$10; mem=$11; comm=$12; $1=$2=$3=$4=$5=$6=$7=$8=$9=$10=$11=$12=\"\"; sub(/^[ \\t]+/, \"\", $0); print pid,ppid,nice,nlwp,rss,tty,user,state,etime,cpu,mem,comm,$0}' | head -n " + String(snapshotLimit)];
    }

    function parseSnapshot(out) {
        var lines = String(out || "").trim().split("\n");
        var result = [];
        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i] || "").trim();
            if (line === "")
                continue;

            var parts = line.split("\t");
            if (parts.length < 13)
                continue;

            result.push({
                pid: parseInt(parts[0], 10) || 0,
                parentPid: parseInt(parts[1], 10) || 0,
                nice: parseInt(parts[2], 10) || 0,
                threadCount: parseInt(parts[3], 10) || 0,
                rssKb: parseInt(parts[4], 10) || 0,
                tty: String(parts[5] || ""),
                user: String(parts[6] || ""),
                state: String(parts[7] || ""),
                elapsed: String(parts[8] || ""),
                cpu: Number(parts[9]) || 0,
                mem: Number(parts[10]) || 0,
                name: String(parts[11] || ""),
                command: String(parts.slice(12).join("\t") || "")
            });
        }
        return result;
    }

    function refresh() {
        processPoll.triggerPoll();
        refreshDetail();
    }

    function _clearDetail() {
        detailStatus = "idle";
        detailMessage = "";
        processDetail = ({});
        detailLastUpdatedMs = 0;
        detailPermissionLimited = false;
        detailDegraded = false;
        lastGoodProcessDetail = ({});
    }

    function _mergeDetailSnapshot(snapshot, pid) {
        var safePid = parseInt(pid, 10) || 0;
        var base = processByPid(safePid) || {};
        return {
            pid: safePid,
            cwd: snapshot.cwd || "",
            exe: snapshot.exe || "",
            fdCount: snapshot.fdCount,
            threadCount: snapshot.threads !== undefined && snapshot.threads !== null ? snapshot.threads : (base.threadCount !== undefined ? base.threadCount : null),
            rssKb: snapshot.vmRssKb !== undefined && snapshot.vmRssKb !== null ? snapshot.vmRssKb : (base.rssKb !== undefined ? base.rssKb : null),
            tty: String(base.tty || ""),
            state: String(base.state || ""),
            readBytes: snapshot.readBytes,
            writeBytes: snapshot.writeBytes,
            cancelledWriteBytes: snapshot.cancelledWriteBytes,
            command: String(base.command || base.name || ""),
            statusFields: {
                threads: snapshot.threads !== undefined ? snapshot.threads : null,
                vmRssKb: snapshot.vmRssKb !== undefined ? snapshot.vmRssKb : null,
                voluntaryCtxtSwitches: snapshot.voluntaryCtxtSwitches !== undefined ? snapshot.voluntaryCtxtSwitches : null,
                nonvoluntaryCtxtSwitches: snapshot.nonvoluntaryCtxtSwitches !== undefined ? snapshot.nonvoluntaryCtxtSwitches : null
            },
            openFilePreview: snapshot.openFilePreview || []
        };
    }

    function setDetailPid(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0) {
            detailPid = 0;
            _clearDetail();
            return;
        }
        if (detailPid === safePid && detailStatus !== "idle") {
            refreshDetail();
            return;
        }
        detailPid = safePid;
        detailStatus = "loading";
        detailMessage = "Loading process detail...";
        processDetail = { pid: safePid };
        detailLastUpdatedMs = 0;
        detailPermissionLimited = false;
        detailDegraded = false;
        detailPoll.triggerPoll();
    }

    function refreshDetail() {
        if ((parseInt(detailPid, 10) || 0) <= 0)
            return;
        detailPoll.triggerPoll();
    }

    function copyCwd(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0 || detailPid !== safePid)
            return false;
        return _runClipboardAction(safePid, String(processDetail.cwd || ""), "Working directory copied to clipboard.");
    }

    function copyExe(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0 || detailPid !== safePid)
            return false;
        return _runClipboardAction(safePid, String(processDetail.exe || ""), "Executable path copied to clipboard.");
    }

    function parseDetailSnapshot(out) {
        var text = String(out || "").trim();
        if (text === "")
            return {
                pid: detailPid,
                status: "error",
                message: "No process detail returned."
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
            pid: detailPid,
            status: status,
            message: message,
            openFilePreview: [],
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
            if (key === "openFile") {
                result.openFilePreview.push({
                    fd: parseInt(parts[1], 10) || 0,
                    target: String(parts.slice(2).join("\t") || "")
                });
                continue;
            }
            var value = parts.slice(1).join("\t");
            if (key === "pid")
                result.pid = parseInt(value, 10) || 0;
            else if (key === "permissionLimited" || key === "degraded")
                result[key] = parseOptionalBool(value);
            else if (key === "fdCount" || key === "readBytes" || key === "writeBytes" || key === "cancelledWriteBytes" || key === "threads" || key === "vmRssKb" || key === "voluntaryCtxtSwitches" || key === "nonvoluntaryCtxtSwitches")
                result[key] = parseOptionalInt(value);
            else
                result[key] = value;
        }

        return result;
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

        lastActionPid = safePid;
        lastActionState = "pending";
        lastActionMessage = String(actionName || "action").toUpperCase() + " running...";
        lastActionAt = Date.now();
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

        lastActionPid = safePid;
        lastActionState = "pending";
        lastActionMessage = "COPY running...";
        lastActionAt = Date.now();
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
        var cmd = "if command -v htop >/dev/null 2>&1; then exec htop -p " + String(safePid) + "; else exec top -p " + String(safePid) + "; fi";
        Quickshell.execDetached(SU.terminalCommand(cmd));
        return true;
    }

    function openProcessDetailsInTerminal(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return false;
        var cmd = "if command -v lsof >/dev/null 2>&1; then lsof -p " + String(safePid) + "; else ps -fp " + String(safePid) + "; echo; echo \"lsof not available\"; fi; echo; read -n 1 -s -r -p \"Press any key to close\"";
        Quickshell.execDetached(SU.terminalCommand(cmd));
        return true;
    }


    property var processPoll: CommandPoll {
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
            if (root.detailPid > 0 && !root.processByPid(root.detailPid) && root.detailStatus !== "loading") {
                root.detailStatus = "terminated";
                root.detailMessage = "Process exited.";
                root.detailLastUpdatedMs = Date.now();
                root.detailPermissionLimited = false;
                root.detailDegraded = false;
                root.processDetail = {
                    pid: root.detailPid
                };
            }
        }
    }

    property var detailPoll: CommandPoll {
        id: detailPoll
        interval: Math.max(1000, root.detailPollIntervalMs)
        running: root.subscriberCount > 0 && root.detailPid > 0
        command: root._detailCommand(root.detailPid)
        parse: function(out) {
            return root.parseDetailSnapshot(out);
        }
        onUpdated: {
            var snapshot = detailPoll.value || {};
            var snapshotPid = parseInt(snapshot.pid, 10) || 0;
            if (snapshotPid <= 0 || snapshotPid !== root.detailPid)
                return;

            var nextStatus = String(snapshot.status || "ready");
            var nextMessage = String(snapshot.message || "");
            var hasCached = parseInt(root.lastGoodProcessDetail.pid, 10) === snapshotPid;
            var nextDetail = root._mergeDetailSnapshot(snapshot, snapshotPid);

            root.detailLastUpdatedMs = Date.now();
            root.detailPermissionLimited = !!snapshot.permissionLimited || nextStatus === "permission-limited";
            root.detailDegraded = !!snapshot.degraded || nextStatus === "error" || nextStatus === "permission-limited";

            if (nextStatus === "error" && hasCached) {
                root.detailStatus = "error";
                root.detailMessage = nextMessage !== "" ? nextMessage + " Showing last successful detail." : "Detail refresh failed. Showing last successful detail.";
                root.processDetail = root.lastGoodProcessDetail;
                root.detailDegraded = true;
                return;
            }

            root.detailStatus = nextStatus;
            root.detailMessage = nextMessage;
            root.processDetail = nextDetail;
            if (nextStatus === "ready" || nextStatus === "permission-limited")
                root.lastGoodProcessDetail = nextDetail;
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
            root.lastActionPid = pid;
            root.lastActionState = exitCode === 0 ? "success" : "error";
            root.lastActionMessage = exitCode === 0 ? root._actionSuccessMessage : root._actionFailureMessage;
            root.lastActionAt = Date.now();
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
