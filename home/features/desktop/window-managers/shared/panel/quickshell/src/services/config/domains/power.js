.pragma library

var sectionKey = "power"

var maps = [
    ["idleInhibit", "idleInhibitEnabled"],
    ["inhibitIdleWhenPlaying", "inhibitIdleWhenPlaying"],
    ["batteryAlertsEnabled", "batteryAlertsEnabled"],
    ["batteryWarningThreshold", "batteryWarningThreshold"],
    ["batteryCriticalThreshold", "batteryCriticalThreshold"],
    ["acMonitorTimeout", "powerAcMonitorTimeout"],
    ["acLockTimeout", "powerAcLockTimeout"],
    ["acSuspendTimeout", "powerAcSuspendTimeout"],
    ["acSuspendAction", "powerAcSuspendAction"],
    ["batMonitorTimeout", "powerBatMonitorTimeout"],
    ["batLockTimeout", "powerBatLockTimeout"],
    ["batSuspendTimeout", "powerBatSuspendTimeout"],
    ["batSuspendAction", "powerBatSuspendAction"]
]

var nightLight = {
    sectionKey: "nightLight",
    maps: [
        ["enabled", "nightLightEnabled"],
        ["temperature", "nightLightTemperature"],
        ["autoSchedule", "nightLightAutoSchedule"],
        ["scheduleMode", "nightLightScheduleMode"],
        ["startHour", "nightLightStartHour"],
        ["startMinute", "nightLightStartMinute"],
        ["endHour", "nightLightEndHour"],
        ["endMinute", "nightLightEndMinute"],
        ["latitude", "nightLightLatitude", _str],
        ["longitude", "nightLightLongitude", _str]
    ]
}

function _str(v) { return String(v); }
