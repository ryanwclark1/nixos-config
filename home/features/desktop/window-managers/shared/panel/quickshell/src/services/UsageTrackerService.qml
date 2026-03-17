pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Public API ───────────────────────────────
    function recordUsage(appId) {
        if (!appId) return;
        var now = Date.now();
        var entry = _data[appId];
        if (entry) {
            entry.count = (entry.count || 0) + 1;
            entry.lastUsed = now;
        } else {
            _data[appId] = { count: 1, lastUsed: now, firstUsed: now };
        }
        _scheduleSave();
    }

    function getUsageScore(appId) {
        if (!appId) return 0;
        var entry = _data[appId];
        if (!entry) return 0;

        var now = Date.now();
        var daysSinceUsed = (now - (entry.lastUsed || 0)) / 86400000;  // ms → days
        var frequency = Math.log2(Math.max(1, entry.count || 0) + 1);
        var decay = Math.exp(-0.03 * daysSinceUsed);  // ~50% at 23 days

        return frequency * decay;
    }

    // ── Internal ─────────────────────────────────
    property var _data: ({})
    readonly property string _filePath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/usage.json"

    property FileView _file: FileView {
        path: root._filePath
    }

    Component.onCompleted: _load()

    function _load() {
        var raw = _file.text();
        if (!raw) return;
        try {
            var parsed = JSON.parse(raw);
            // Prune entries older than 90 days
            var now = Date.now();
            var pruneThreshold = now - (90 * 86400000);
            var pruned = {};
            for (var key in parsed) {
                if (parsed[key] && (parsed[key].lastUsed || 0) > pruneThreshold)
                    pruned[key] = parsed[key];
            }
            _data = pruned;
        } catch (e) {
            _data = {};
        }
    }

    property Timer _saveTimer: Timer {
        interval: 1000
        onTriggered: root._save()
    }

    function _scheduleSave() {
        _saveTimer.restart();
    }

    function _save() {
        try {
            _file.setText(JSON.stringify(_data));
        } catch (e) {
            // Silently fail — not critical
        }
    }
}
