.pragma library

.import "../../services/IconHelpers.js" as IconHelpers

// UPower sometimes leaves state as "discharging" while only time-to-full is populated (ACPI/firmware quirk).
function _timesImplyCharging(device) {
    // Use !(timeToEmpty > 0) so undefined/unknown empty time still allows the heuristic.
    return device && device.timeToFull > 0 && !(device.timeToEmpty > 0);
}

/** True when the machine is on AC or actively charging (matches stateText "plugged" cases). */
function isAcPowered(device, UPowerEnums) {
    if (!device) return false;
    if (device.state === UPowerEnums.DeviceStateCharging) return true;
    if (device.state === UPowerEnums.DeviceStateFullyCharged) return true;
    if (device.state === UPowerEnums.DeviceStatePendingCharge) return true;
    return _timesImplyCharging(device);
}

function stateText(device, UPowerEnums) {
    if (!device) return "Unknown";
    if (device.state === UPowerEnums.DeviceStateFullyCharged) return "Fully charged";
    if (device.state === UPowerEnums.DeviceStateCharging) return "Charging";
    if (device.state === UPowerEnums.DeviceStatePendingCharge) return "Pending charge";
    if (device.state === UPowerEnums.DeviceStatePendingDischarge) return "Pending discharge";
    if (_timesImplyCharging(device)) return "Charging";
    return "Discharging";
}

function iconName(device, UPowerEnums) {
    return IconHelpers.batteryIcon(device, UPowerEnums);
}
