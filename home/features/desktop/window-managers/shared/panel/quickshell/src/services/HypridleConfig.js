.pragma library

function clampMinutes(value, fallbackValue) {
    var parsed = parseInt(value, 10);
    if (!isFinite(parsed) || parsed < 1)
        return fallbackValue;
    return parsed;
}

function suspendCommand(action) {
    switch (String(action || "").trim().toLowerCase()) {
    case "hibernate":
        return "systemctl hibernate";
    case "poweroff":
        return "systemctl poweroff";
    case "suspend":
    default:
        return "systemctl suspend";
    }
}

function render(profile) {
    var monitorMinutes = clampMinutes(profile && profile.monitorTimeout, 15);
    var lockMinutes = clampMinutes(profile && profile.lockTimeout, 45);
    var suspendMinutes = clampMinutes(profile && profile.suspendTimeout, 60);
    var sleepCommand = suspendCommand(profile && profile.suspendAction);

    var lines = [
        "# Managed by Quickshell. Manual edits will be replaced.",
        "",
        "general {",
        "    lock_cmd = pidof hyprlock || hyprlock",
        "    before_sleep_cmd = loginctl lock-session",
        "    after_sleep_cmd = hyprctl dispatch dpms on",
        "    ignore_dbus_inhibit = false",
        "}",
        "",
        "listener {",
        "    timeout = " + (monitorMinutes * 60),
        "    on-timeout = hyprctl dispatch dpms off",
        "    on-resume = hyprctl dispatch dpms on && brightnessctl -r",
        "}",
        "",
        "listener {",
        "    timeout = " + (lockMinutes * 60),
        "    on-timeout = loginctl lock-session",
        "}",
        "",
        "listener {",
        "    timeout = " + (suspendMinutes * 60),
        "    on-timeout = " + sleepCommand,
        "}",
        ""
    ];

    return lines.join("\n");
}
