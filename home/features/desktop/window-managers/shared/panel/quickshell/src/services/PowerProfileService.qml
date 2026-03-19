pragma Singleton

import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property string currentProfile: _profileToString(PowerProfiles.profile)
    readonly property bool available: true
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile
    readonly property var availableProfiles: {
        var p = ["balanced", "power-saver"];
        if (hasPerformanceProfile) p.push("performance");
        return p;
    }

    // Ref.qml compat (no-op — reactive now)
    property int subscriberCount: 0

    function setProfile(name) {
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
