.pragma library

// Shared schedule utilities for NightLightService and ThemeService.

function computeSunTimes(date, lat, lon) {
    var dayOfYear = Math.floor((date - new Date(date.getFullYear(), 0, 0)) / 86400000);
    var radLat = lat * Math.PI / 180;
    var decl = -23.45 * Math.cos(2 * Math.PI / 365 * (dayOfYear + 10)) * Math.PI / 180;
    var cosHA = (Math.cos(90.833 * Math.PI / 180) - Math.sin(radLat) * Math.sin(decl))
              / (Math.cos(radLat) * Math.cos(decl));
    cosHA = Math.max(-1, Math.min(1, cosHA));
    var ha = Math.acos(cosHA) * 180 / Math.PI;
    var solarNoon = 720 - 4 * lon;
    var sunriseMin = Math.round(solarNoon - ha * 4);
    var sunsetMin = Math.round(solarNoon + ha * 4);
    var tzOffset = -date.getTimezoneOffset();
    sunriseMin = ((sunriseMin + tzOffset) % 1440 + 1440) % 1440;
    sunsetMin = ((sunsetMin + tzOffset) % 1440 + 1440) % 1440;
    return { sunrise: sunriseMin, sunset: sunsetMin };
}

function currentMinutes(now) {
    return now.getHours() * 60 + now.getMinutes();
}

// Returns true if currentMin falls within a wrap-around window [startMin, endMin).
function isInWindow(currentMin, startMin, endMin) {
    if (startMin > endMin)
        return currentMin >= startMin || currentMin < endMin;
    return currentMin >= startMin && currentMin < endMin;
}

// Returns true if night-time (between sunset and sunrise) for the given coordinates.
function isDarkAtLocation(now, lat, lon) {
    if (isNaN(lat) || isNaN(lon)) return false;
    var times = computeSunTimes(now, lat, lon);
    var current = currentMinutes(now);
    return current >= times.sunset || current < times.sunrise;
}
