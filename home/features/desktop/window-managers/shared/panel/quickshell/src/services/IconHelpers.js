.pragma library

function panelChevronIcon(expanded) {
    return expanded ? "chevron-up.svg" : "chevron-down.svg";
}

function disclosureIcon(expanded) {
    return expanded ? "chevron-down.svg" : "chevron-right.svg";
}

function treeDisclosureIcon(collapsed, hasChildren) {
    if (!hasChildren)
        return "subtract.svg";
    return collapsed ? "chevron-right.svg" : "chevron-down.svg";
}

function secretVisibilityIcon(visible) {
    return visible ? "eye.svg" : "eye-off.svg";
}

function sortIndicatorIcon(ascending) {
    return ascending ? "caret-up.svg" : "caret-down.svg";
}

function trendIndicatorIcon(up) {
    return sortIndicatorIcon(up);
}

function weatherDetailIcon(kind) {
    if (kind === "sunrise")
        return "caret-up.svg";
    if (kind === "sunset")
        return "caret-down.svg";
    if (kind === "precipitation")
        return "weather-rain.svg";
    return "info.svg";
}

function audioOutputIcon(volume, muted, deviceType) {
    if (muted)
        return "speaker-mute.svg";
    var kind = String(deviceType || "").toLowerCase();
    if (kind === "bluetooth")
        return "bluetooth.svg";
    if (kind === "headphone")
        return "headphones.svg";
    var v = Number(volume || 0);
    if (!isFinite(v))
        v = 0;
    if (v <= 0.001)
        return "speaker-none.svg";
    if (v > 0.6)
        return "speaker-2-filled.svg";
    if (v > 0.3)
        return "speaker-1.svg";
    return "speaker-0.svg";
}

function batteryIcon(device, UPowerEnums) {
    if (!device)
        return "battery-warning.svg";
    if (device.state === UPowerEnums.DeviceStateCharging || device.state === UPowerEnums.DeviceStatePendingCharge)
        return "battery-charge.svg";
    if (device.state === UPowerEnums.DeviceStateFullyCharged)
        return "battery-full.svg";
    var p = Number(device.percentage || 0);
    if (!isFinite(p))
        p = 0;
    if (p >= 0.95)
        return "battery-full.svg";
    if (p >= 0.85)
        return "battery-9.svg";
    if (p >= 0.75)
        return "battery-8.svg";
    if (p >= 0.65)
        return "battery-7.svg";
    if (p >= 0.55)
        return "battery-6.svg";
    if (p >= 0.45)
        return "battery-5.svg";
    if (p >= 0.35)
        return "battery-4.svg";
    if (p >= 0.25)
        return "battery-3.svg";
    if (p >= 0.18)
        return "battery-2.svg";
    if (p >= 0.1)
        return "battery-1.svg";
    return "battery-warning.svg";
}

function bluetoothDeviceIcon(deviceOrName) {
    var raw = typeof deviceOrName === "string" ? deviceOrName : String(deviceOrName && deviceOrName.name || "");
    var name = raw.toLowerCase();
    if (name.indexOf("headphone") !== -1 || name.indexOf("airpod") !== -1 || name.indexOf("buds") !== -1 || name.indexOf("earphone") !== -1)
        return "headphones.svg";
    if (name.indexOf("keyboard") !== -1)
        return "keyboard.svg";
    if (name.indexOf("mouse") !== -1 || name.indexOf("trackpad") !== -1)
        return "cursor-click.svg";
    if (name.indexOf("phone") !== -1 || name.indexOf("iphone") !== -1 || name.indexOf("pixel") !== -1 || name.indexOf("galaxy") !== -1)
        return "phone.svg";
    if (name.indexOf("speaker") !== -1 || name.indexOf("soundbar") !== -1)
        return "desktop-speaker.svg";
    if (name.indexOf("watch") !== -1)
        return "clock.svg";
    if (name.indexOf("gamepad") !== -1 || name.indexOf("controller") !== -1 || name.indexOf("xbox") !== -1 || name.indexOf("dualsense") !== -1)
        return "games.svg";
    return "bluetooth.svg";
}

function transportToggleIcon(playing) {
    return playing ? "pause.svg" : "play.svg";
}

function runningStateIcon(running) {
    return running ? "stop.svg" : "play.svg";
}

function busyStatusIcon(busy) {
    return busy ? "arrow-clockwise.svg" : "checkmark.svg";
}

function updatedStatusIcon(degraded) {
    return degraded ? "warning.svg" : "clock.svg";
}

function degradedStatusIcon(degraded, healthyIcon) {
    return degraded ? "warning.svg" : healthyIcon;
}

function healthStatusIcon(attentionNeeded) {
    return attentionNeeded ? "warning.svg" : "checkmark.svg";
}

function pluginTypeIcon(typeName) {
    if (typeName === "bar-widget")
        return "layout-row.svg";
    if (typeName === "desktop-widget")
        return "desktop.svg";
    if (typeName === "launcher-provider")
        return "globe-search.svg";
    if (typeName === "control-center-widget")
        return "settings.svg";
    if (typeName === "daemon")
        return "settings-cog-multiple.svg";
    return "puzzle-piece.svg";
}

function hookCategoryIcon(category) {
    if (category === "Appearance")
        return "color-palette.svg";
    if (category === "Power")
        return "power.svg";
    if (category === "Audio")
        return "speaker-2-filled.svg";
    if (category === "Display")
        return "desktop.svg";
    if (category === "Notifications")
        return "alert.svg";
    if (category === "Media")
        return "music-note-2.svg";
    if (category === "Compositor")
        return "window-shield.svg";
    return "sparkle.svg";
}

function barSectionIcon(sectionKey) {
    if (sectionKey === "left")
        return "arrow-left.svg";
    if (sectionKey === "center")
        return "layout-row.svg";
    return "arrow-right.svg";
}

function notificationActionIcon(action) {
    return action === "mute" ? "alert-off.svg" : "alert-snooze.svg";
}

function presetDeleteIcon(confirming) {
    return confirming ? "warning.svg" : "delete.svg";
}

function commandExecuteIcon(running) {
    return running ? "arrow-clockwise.svg" : "play.svg";
}
