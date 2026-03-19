pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property string currentProfile: _available ? _profileToString(PowerProfiles.profile) : "balanced"
    readonly property bool available: _available
    readonly property bool hasPerformanceProfile: _available && PowerProfiles.hasPerformanceProfile
    readonly property var availableProfiles: {
        var p = ["balanced", "power-saver"];
        if (hasPerformanceProfile) p.push("performance");
        return p;
    }

    // Ref.qml compat (no-op — reactive now)
    property int subscriberCount: 0

    property bool _available: false

    Component.onCompleted: _detectProc.running = true

    property Process _detectProc: Process {
        running: false
        command: ["sh", "-c", "busctl --user introspect org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: root._available = (this.text || "").trim() === "yes"
        }
    }

    function setProfile(name) {
        if (!_available) return;
        if (name === "performance" && hasPerformanceProfile)
            PowerProfiles.profile = PowerProfile.Performance;
        else if (name === "power-saver")
            PowerProfiles.profile = PowerProfile.PowerSaver;
        else
            PowerProfiles.profile = PowerProfile.Balanced;
    }

    function refresh() {} // no-op, reactive now

    function _profileToString(p) {
        if (p === PowerProfile.Performance) return "performance";
        if (p === PowerProfile.PowerSaver) return "power-saver";
        return "balanced";
    }
}
