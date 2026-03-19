pragma Singleton

import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower

QtObject {
    id: root

    property bool _probeComplete: false
    property bool _powerProfilesAvailable: false

    readonly property bool availabilityKnown: _probeComplete
    readonly property bool available: _probeComplete && _powerProfilesAvailable
    readonly property string currentProfile: available ? _profileToString(PowerProfiles.profile) : "balanced"
    readonly property bool hasPerformanceProfile: available ? PowerProfiles.hasPerformanceProfile : false
    readonly property var availableProfiles: {
        var p = ["balanced", "power-saver"];
        if (hasPerformanceProfile)
            p.push("performance");
        return p;
    }

    // Ref.qml compat (no-op — reactive now)
    property int subscriberCount: 0

    property Process _availabilityProbe: Process {
        command: ["sh", "-c", "command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl list >/dev/null 2>&1"]
        running: true
        onExited: (exitCode) => {
            root._powerProfilesAvailable = exitCode === 0;
            root._probeComplete = true;
        }
    }

    function setProfile(name) {
        if (!available)
            return;
        if (name === "performance" && hasPerformanceProfile)
            PowerProfiles.profile = PowerProfile.Performance;
        else if (name === "power-saver")
            PowerProfiles.profile = PowerProfile.PowerSaver;
        else
            PowerProfiles.profile = PowerProfile.Balanced;
    }

    function refresh() {
        if (_availabilityProbe.running)
            return;
        _probeComplete = false;
        _availabilityProbe.running = true;
    }

    function _profileToString(p) {
        if (p === PowerProfile.Performance)
            return "performance";
        if (p === PowerProfile.PowerSaver)
            return "power-saver";
        return "balanced";
    }
}
