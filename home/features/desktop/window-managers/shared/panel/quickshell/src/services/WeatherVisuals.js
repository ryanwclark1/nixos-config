.pragma library

function _normalizedCondition(condition) {
    return String(condition || "").trim().toLowerCase();
}

function _containsAny(text, needles) {
    for (var i = 0; i < needles.length; i++) {
        if (text.indexOf(needles[i]) !== -1)
            return true;
    }
    return false;
}

function _intensityLevel(text) {
    if (_containsAny(text, ["violent", "heavy", "dense", "intense", "blizzard"]))
        return "heavy";
    if (_containsAny(text, ["light", "slight", "patchy", "drizzle", "mainly"]))
        return "light";
    return "normal";
}

function _intensityValue(level) {
    if (level === "heavy")
        return 1.0;
    if (level === "light")
        return 0.4;
    return 0.7;
}

function visualForCondition(condition) {
    var text = _normalizedCondition(condition);
    var level = _intensityLevel(text);
    var scene = "cloud";
    var icon = "cloud.svg";
    var overlayScene = "none";
    var flash = false;

    if (_containsAny(text, ["thunder", "storm", "lightning"])) {
        scene = "thunder";
        icon = "weather-thunderstorm.svg";
        overlayScene = "rain";
        flash = true;
    } else if (_containsAny(text, ["snow", "sleet", "ice pellets", "blowing snow"])) {
        scene = "snow";
        icon = "weather-snow.svg";
        overlayScene = "snow";
    } else if (_containsAny(text, ["rain", "drizzle", "shower"])) {
        scene = "rain";
        icon = "weather-rain.svg";
        overlayScene = "rain";
    } else if (_containsAny(text, ["fog", "mist", "haze", "smoke"])) {
        scene = "fog";
        icon = "weather-fog.svg";
        overlayScene = "fog";
    } else if (_containsAny(text, ["clear", "sunny"])) {
        scene = "clear";
        icon = "weather-sunny.svg";
    } else if (_containsAny(text, ["cloud", "overcast"])) {
        scene = "cloud";
        icon = "cloud.svg";
    }

    return {
        scene: scene,
        icon: icon,
        level: level,
        intensity: _intensityValue(level),
        overlayScene: overlayScene,
        flash: flash
    };
}
