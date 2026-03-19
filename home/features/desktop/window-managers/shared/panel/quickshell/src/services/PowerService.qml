pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    readonly property bool onBattery: UPower.onBattery
    readonly property string powerSource: onBattery ? "battery" : "ac"

    // ── Battery alerts ──────────────────────────
    property bool _warningFired: false
    property bool _criticalFired: false
    property var _batteryDevice: UPower.displayDevice

    property Connections _batteryWatcher: Connections {
        target: root._batteryDevice
        enabled: root._batteryDevice != null && root._batteryDevice.isPresent
        function onPercentageChanged() { root._checkBatteryAlerts(); }
        function onStateChanged() { root._checkBatteryAlerts(); }
    }

    function _checkBatteryAlerts() {
        if (!Config.batteryAlertsEnabled) return;
        if (!_batteryDevice || !_batteryDevice.isPresent) return;

        var pct = Math.round(_batteryDevice.percentage * 100);
        var charging = _batteryDevice.state === UPower.DeviceStateCharging
                    || _batteryDevice.state === UPower.DeviceStateFullyCharged;

        // Reset alerts when charging
        if (charging) {
            _warningFired = false;
            _criticalFired = false;
            return;
        }

        if (pct <= Config.batteryCriticalThreshold && !_criticalFired) {
            _criticalFired = true;
            _warningFired = true;
            ToastService.showError("Battery Critical", "Battery at " + pct + "% \u2014 plug in immediately");
            return;
        }
        if (pct <= Config.batteryWarningThreshold && !_warningFired) {
            _warningFired = true;
            ToastService.showNotice("Battery Low", "Battery at " + pct + "% \u2014 consider plugging in");
        }
    }
}
