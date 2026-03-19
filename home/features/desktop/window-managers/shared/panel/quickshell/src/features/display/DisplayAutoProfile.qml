import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

QtObject {
    id: root

    // Debounce screen changes — monitors may appear in rapid succession
    property var _applyTimer: Timer {
        interval: 1500
        repeat: false
        onTriggered: root._tryAutoApply()
    }

    property var _screenWatcher: Connections {
        target: Quickshell
        function onScreensChanged() {
            if (Config.displayAutoProfile && Config.displayProfiles.length > 0)
                root._applyTimer.restart();
        }
    }

    property var _applyQueue: []

    property var _applyProcess: Process {
        running: false
        onRunningChanged: {
            if (!running) root._runNextCmd();
        }
    }

    function _currentScreenNames() {
        var screens = Quickshell.screens || [];
        var names = [];
        for (var i = 0; i < screens.length; i++) {
            var name = screens[i].name;
            if (name) names.push(String(name));
        }
        names.sort();
        return names;
    }

    function _profileScreenNames(profile) {
        if (!profile || !profile.monitors) return [];
        var names = [];
        for (var i = 0; i < profile.monitors.length; i++) {
            var name = profile.monitors[i].name;
            if (name) names.push(String(name));
        }
        names.sort();
        return names;
    }

    function _arraysEqual(a, b) {
        if (a.length !== b.length) return false;
        for (var i = 0; i < a.length; i++) {
            if (a[i] !== b[i]) return false;
        }
        return true;
    }

    function _tryAutoApply() {
        if (!Config.displayAutoProfile) return;

        var current = _currentScreenNames();
        if (current.length === 0) return;

        var profiles = Config.displayProfiles;
        for (var i = 0; i < profiles.length; i++) {
            var profileNames = _profileScreenNames(profiles[i]);
            if (_arraysEqual(current, profileNames)) {
                _applyProfile(profiles[i]);
                return;
            }
        }
    }

    function _applyProfile(profile) {
        if (!profile || !profile.monitors) return;

        var name = profile.name || "Unnamed";
        ToastService.showSuccess("Display profile applied", name);

        var cmds = [];
        for (var i = 0; i < profile.monitors.length; i++) {
            var m = profile.monitors[i];
            var rateStr = m.refreshRate.toFixed(2);
            var posStr  = m.x + "x" + m.y;
            var dimStr  = m.width + "x" + m.height + "@" + rateStr;
            var scaleStr = m.scale.toFixed(2);
            cmds.push(CompositorAdapter.monitorKeywordCommand(
                m.name + "," + dimStr + "," + posStr + "," + scaleStr
            ));
        }
        _applyQueue = cmds;
        _runNextCmd();
    }

    function _runNextCmd() {
        if (_applyQueue.length === 0) return;
        var cmd = _applyQueue.shift();
        _applyProcess.command = cmd;
        _applyProcess.running = true;
    }
}
