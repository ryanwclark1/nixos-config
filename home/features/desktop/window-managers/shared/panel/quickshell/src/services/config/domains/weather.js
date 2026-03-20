.pragma library

function _str(v) { return String(v); }

var sectionKey = "weather"

var maps = [
    ["provider", "weatherProvider"],
    ["units", "weatherUnits"],
    ["autoLocation", "weatherAutoLocation"],
    ["cityQuery", "weatherCityQuery"],
    ["latitude", "weatherLatitude", _str],
    ["longitude", "weatherLongitude", _str],
    ["locationPriority", "weatherLocationPriority"]
]
