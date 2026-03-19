.pragma library

function stateText(device, UPowerEnums) {
    if (!device) return "Unknown";
    if (device.state === UPowerEnums.DeviceStateCharging) return "Charging";
    if (device.state === UPowerEnums.DeviceStateFullyCharged) return "Fully charged";
    if (device.state === UPowerEnums.DeviceStatePendingCharge) return "Pending charge";
    if (device.state === UPowerEnums.DeviceStatePendingDischarge) return "Pending discharge";
    return "Discharging";
}
