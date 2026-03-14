import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    property string currentProfile: "balanced"
    property var availableProfiles: []
    property bool available: false
    property string backend: "none"   // "powerprofilesctl" | "tlp" | "none"

    // ── Subscriber-based polling ─────────────────
    property int subscriberCount: 0

    // ── Backend detection ────────────────────────
    Component.onCompleted: _detectBackend()

    property Process _detectProc: Process {
        running: false
        command: ["sh", "-c",
            "if command -v powerprofilesctl >/dev/null 2>&1; then echo ppd; "
            + "elif command -v tlp >/dev/null 2>&1; then echo tlp; "
            + "else echo none; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var result = (this.text || "").trim();
                root.backend = result;
                root.available = result !== "none";
                if (root.available)
                    root._fetchProfiles();
            }
        }
    }

    function _detectBackend() {
        if (!_detectProc.running)
            _detectProc.running = true;
    }

    // ── Fetch available profiles ─────────────────
    property Process _profilesProc: Process {
        running: false
        command: ["sh", "-c",
            "powerprofilesctl list 2>/dev/null | grep -oP '(?<=^  )\\S+(?=:)' || echo 'balanced'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (this.text || "").trim().split("\n");
                var profiles = [];
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].trim();
                    if (p) profiles.push(p);
                }
                if (profiles.length === 0)
                    profiles = ["balanced"];
                root.availableProfiles = profiles;
            }
        }
    }

    function _fetchProfiles() {
        if (!_profilesProc.running)
            _profilesProc.running = true;
    }

    // ── Current profile polling ──────────────────
    property Process _currentProc: Process {
        running: false
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var result = (this.text || "").trim();
                if (result)
                    root.currentProfile = result;
            }
        }
    }

    property Timer _pollTimer: Timer {
        interval: 5000
        running: root.subscriberCount > 0 && root.available
        repeat: true
        onTriggered: {
            if (!root._currentProc.running)
                root._currentProc.running = true;
        }
    }

    // ── Actions ──────────────────────────────────
    function setProfile(name) {
        if (!root.available) return;
        if (root.backend === "ppd") {
            Quickshell.execDetached(["powerprofilesctl", "set", name]);
        }
        root.currentProfile = name;
    }

    function refresh() {
        if (root.available && !_currentProc.running)
            _currentProc.running = true;
    }
}
