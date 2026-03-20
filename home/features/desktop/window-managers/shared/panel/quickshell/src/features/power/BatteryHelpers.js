.pragma library

.import "../../services/IconHelpers.js" as IconHelpers

function stateText(device, UPowerEnums) {
    if (!device) return "Unknown";
    if (device.state === UPowerEnums.DeviceStateCharging) return "Charging";
    if (device.state === UPowerEnums.DeviceStateFullyCharged) return "Fully charged";
    if (device.state === UPowerEnums.DeviceStatePendingCharge) return "Pending charge";
    if (device.state === UPowerEnums.DeviceStatePendingDischarge) return "Pending discharge";
    return "Discharging";
}

function iconName(device, UPowerEnums) {
    return IconHelpers.batteryIcon(device, UPowerEnums);
}
