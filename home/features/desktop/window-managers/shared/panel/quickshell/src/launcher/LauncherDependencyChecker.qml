import QtQuick
import Quickshell.Io
import "../services"
import "LauncherModeData.js" as ModeData

Item {
    id: root

    property var commandAvailability: ({})
    property var _commandCheckProcs: ({})
    property var _commandWaiters: ({})

    Component {
        id: commandCheckProcComponent
        Process {
            id: _checkProc
            property string _commandName: ""
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    root._finalizeCommandCheck(_checkProc, (this.text || "").trim() === "1");
                }
            }
        }
    }

    function checkCommandAvailable(cmd, callback) {
        if (!cmd) {
            callback(false);
            return;
        }
        if (DependencyService.knows(cmd)) {
            callback(DependencyService.isAvailable(cmd));
            return;
        }
        if (commandAvailability[cmd] !== undefined) {
            callback(commandAvailability[cmd] === true);
            return;
        }
        if (_commandCheckProcs[cmd]) {
            var queued = _commandWaiters[cmd] || [];
            queued.push(callback);
            var queuedMap = Object.assign({}, _commandWaiters);
            queuedMap[cmd] = queued;
            _commandWaiters = queuedMap;
            return;
        }

        var proc = commandCheckProcComponent.createObject(root);
        proc._commandName = cmd;
        proc.command = ["sh", "-c", "command -v \"$1\" >/dev/null 2>&1 && echo 1 || echo 0", "sh", cmd];
        var nextProcMap = Object.assign({}, _commandCheckProcs);
        nextProcMap[cmd] = proc;
        _commandCheckProcs = nextProcMap;

        var waiters = Object.assign({}, _commandWaiters);
        waiters[cmd] = [callback];
        _commandWaiters = waiters;
        proc.running = true;
    }

    function _finalizeCommandCheck(proc, ok) {
        var cmd = proc._commandName;
        var nextAvailability = Object.assign({}, commandAvailability);
        nextAvailability[cmd] = ok;
        commandAvailability = nextAvailability;
        var next = Object.assign({}, _commandCheckProcs);
        delete next[cmd];
        _commandCheckProcs = next;
        var waiters = _commandWaiters[cmd] || [];
        var nextWaiters = Object.assign({}, _commandWaiters);
        delete nextWaiters[cmd];
        _commandWaiters = nextWaiters;
        for (var i = 0; i < waiters.length; ++i) {
            try {
                waiters[i](ok);
            } catch (e) {}
        }
        proc.destroy();
    }

    function ensureModeDependencies(modeKey, onReady) {
        var deps = ModeData.modeDependencies(modeKey);
        if (!deps || deps.length === 0) {
            onReady(true, "");
            return;
        }

        var pending = deps.length;
        var failed = "";
        for (var i = 0; i < deps.length; ++i) {
            (function (depName) {
                    checkCommandAvailable(depName, function (ok) {
                        if (!ok && failed === "")
                            failed = depName;
                        pending--;
                        if (pending === 0)
                            onReady(failed === "", failed);
                    });
                })(deps[i]);
        }
    }

    function invalidateCommandAvailability(cmd) {
        if (commandAvailability[cmd] === undefined)
            return;
        var nextAvailability = Object.assign({}, commandAvailability);
        delete nextAvailability[cmd];
        commandAvailability = nextAvailability;
    }
}
