.pragma library

function _str(v) { return String(v); }

var sectionKey = "theme"

var maps = [
    ["name", "themeName"],
    ["autoScheduleEnabled", "themeAutoScheduleEnabled"],
    ["autoScheduleMode", "themeAutoScheduleMode"],
    ["useDynamicTheming", "useDynamicTheming"],
    ["darkName", "themeDarkName"],
    ["lightName", "themeLightName"],
    ["darkHour", "themeDarkHour"],
    ["darkMinute", "themeDarkMinute"],
    ["lightHour", "themeLightHour"],
    ["lightMinute", "themeLightMinute"],
    ["autoLatitude", "themeAutoLatitude", _str],
    ["autoLongitude", "themeAutoLongitude", _str]
]
