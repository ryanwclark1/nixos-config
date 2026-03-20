pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "WeatherLocationHelpers.js" as WeatherLocationHelpers

QtObject {
  id: root

  // ── Subscriber lifecycle ──────────────────────────
  property int subscriberCount: 0

  property string temp: "--"
  property string feelsLike: "--"
  property string humidity: "--"
  property string windSpeed: "--"
  property string windDir: ""
  property string visibility: "--"
  property string condition: ""
  property string location: "Local"
  property var forecast: []
  property string uvIndex: "--"
  property string pressure: "--"
  property string precipitation: "--"
  property string sunrise: "--"
  property string sunset: "--"
  property var hourlyForecast: []
  property bool _hasSuccessfulFetch: false
  property string _lastFailureKey: ""

  // ── Air Quality ───────────────────────────────
  property string aqi: "--"
  property string aqiCategory: ""
  property string pm25: "--"
  property string pm10: "--"
  property string no2: "--"
  property string o3: "--"
  property string so2: "--"
  property string co: "--"
  property string _resolvedLat: ""
  property string _resolvedLon: ""
  property var _locationPlan: []
  property int _locationPlanIndex: -1
  property var _cityVariants: []
  property int _cityVariantIndex: -1

  readonly property string _unitMode: Config.weatherUnits === "imperial" ? "imperial" : "metric"
  readonly property string _tempSuffix: _unitMode === "imperial" ? "°F" : "°C"
  readonly property string _windSuffix: _unitMode === "imperial" ? " mph" : " km/h"
  readonly property string _visibilitySuffix: _unitMode === "imperial" ? " mi" : " km"

  // ── Named constants ──────────────────────────
  readonly property int _refreshIntervalMs: 1800000  // 30 min
  readonly property int _retryIntervalMs: 30000      // 30s retry on failure
  readonly property int _configDebounceMs: 500

  property bool _ready: false
  Component.onCompleted: _ready = true

  function _getConditionFromWmo(code) {
    switch (code) {
      case 0: return "Clear sky";
      case 1: return "Mainly clear";
      case 2: return "Partly cloudy";
      case 3: return "Overcast";
      case 45: return "Fog";
      case 48: return "Depositing rime fog";
      case 51: return "Light drizzle";
      case 53: return "Moderate drizzle";
      case 55: return "Dense drizzle";
      case 56: return "Light freezing drizzle";
      case 57: return "Dense freezing drizzle";
      case 61: return "Slight rain";
      case 63: return "Moderate rain";
      case 65: return "Heavy rain";
      case 66: return "Light freezing rain";
      case 67: return "Heavy freezing rain";
      case 71: return "Slight snow fall";
      case 73: return "Moderate snow fall";
      case 75: return "Heavy snow fall";
      case 77: return "Snow grains";
      case 80: return "Slight rain showers";
      case 81: return "Moderate rain showers";
      case 82: return "Violent rain showers";
      case 85: return "Slight snow showers";
      case 86: return "Heavy snow showers";
      case 95: return "Thunderstorm";
      case 96: return "Thunderstorm with slight hail";
      case 99: return "Thunderstorm with heavy hail";
      default: return "Unknown";
    }
  }

  function _getWindDir(degree) {
    var sectors = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
    var idx = Math.floor((degree + 11.25) / 22.5) % 16;
    return sectors[idx];
  }

  function _aqiCategoryUS(v) {
    if (v <= 50) return "Good";
    if (v <= 100) return "Moderate";
    if (v <= 150) return "Unhealthy for Sensitive";
    if (v <= 200) return "Unhealthy";
    if (v <= 300) return "Very Unhealthy";
    return "Hazardous";
  }

  function _aqiCategoryEU(v) {
    if (v <= 20) return "Good";
    if (v <= 40) return "Fair";
    if (v <= 60) return "Moderate";
    if (v <= 80) return "Poor";
    if (v <= 100) return "Very Poor";
    return "Extremely Poor";
  }

  function _reportFailure(key, details) {
    var failureKey = String(key || "unknown");
    if (root._lastFailureKey !== failureKey) {
      root._lastFailureKey = failureKey;
      if (details)
        Logger.w("WeatherService", failureKey, details);
      else
        Logger.w("WeatherService", failureKey);
    }
    retryTimer.restart();
  }

  function _hasManualCoordinates() {
    var lat = parseFloat(Config.weatherLatitude);
    var lon = parseFloat(Config.weatherLongitude);
    return !isNaN(lat) && !isNaN(lon);
  }

  function _buildLocationPlan() {
    return WeatherLocationHelpers.buildLocationPlan(
      Config.weatherLocationPriority,
      root._hasManualCoordinates(),
      String(Config.weatherCityQuery || "").trim().length > 0,
      Config.weatherAutoLocation
    );
  }

  function _advanceLocationPlan() {
    root._locationPlanIndex += 1;
    if (root._locationPlanIndex >= root._locationPlan.length) {
      root._setUnavailableState("Location not configured");
      return;
    }

    var mode = root._locationPlan[root._locationPlanIndex];
    if (mode === "city") {
      root._cityVariants = WeatherLocationHelpers.cityQueryVariants(Config.weatherCityQuery);
      root._cityVariantIndex = 0;
      if (root._cityVariants.length > 0) {
        _geocode(root._cityVariants[0]);
        return;
      }
    } else if (mode === "latlon") {
      var lat = parseFloat(Config.weatherLatitude);
      var lon = parseFloat(Config.weatherLongitude);
      root._resolvedLat = lat.toString();
      root._resolvedLon = lon.toString();
      root.location = "Coordinates (" + lat.toFixed(2) + ", " + lon.toFixed(2) + ")";
      _fetchWeather();
      return;
    } else if (mode === "auto") {
      _autoLocate();
      return;
    }

    root._advanceLocationPlan();
  }

  function _tryNextLocationSource(failureKey, details) {
    if (root._locationPlan[root._locationPlanIndex] === "city" && root._cityVariantIndex + 1 < root._cityVariants.length) {
      root._cityVariantIndex += 1;
      _geocode(root._cityVariants[root._cityVariantIndex]);
      return true;
    }

    if (root._locationPlanIndex + 1 < root._locationPlan.length) {
      Logger.w("WeatherService", failureKey, (details ? details + " — falling back" : "falling back"));
      root._advanceLocationPlan();
      return true;
    }

    return false;
  }

  function refresh() {
    if (Config.weatherProvider === "wttr") {
      _refreshWttr();
    } else {
      _refreshOpenMeteo();
    }
  }

  function _refreshWttr() {
    var source = _sourceByPriority();
    if (source.kind === "none") {
      _setUnavailableState("Location not configured");
      return;
    }

    var base = source.target ? ("https://wttr.in/" + source.target) : "https://wttr.in/";
    var unitFlag = _unitMode === "imperial" ? "&u" : "";
    var url = base + "?format=j1" + unitFlag;

    weatherProc.command = ["curl", "-s", "--compressed", "--max-time", "15",
      "-H", "User-Agent: quickshell-weather/1.0", url];
    if (!weatherProc.running) weatherProc.running = true;
  }

  function _refreshOpenMeteo() {
    root._locationPlan = root._buildLocationPlan();
    root._locationPlanIndex = -1;
    root._cityVariants = [];
    root._cityVariantIndex = -1;

    if (root._locationPlan.length > 0) {
      root._advanceLocationPlan();
      return;
    }

    _setUnavailableState("Location not configured");
  }

  function _setUnavailableState(reason) {
    root.condition = reason || "Weather unavailable";
    root.temp = "--";
    root.feelsLike = "--";
    root.location = "Configure location";
  }

  function _geocode(city) {
    var url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(city) + "&count=1&language=en&format=json";
    geoproc.command = ["curl", "-s", "--max-time", "10", url];
    if (!geoproc.running) geoproc.running = true;
  }

  function _autoLocate() {
    ipapi.command = ["curl", "-s", "--max-time", "10", "https://ipapi.co/json/"];
    if (!ipapi.running) ipapi.running = true;
  }

  function _fetchWeather() {
    if (!root._resolvedLat || !root._resolvedLon) return;
    
    var url = "https://api.open-meteo.com/v1/forecast"
      + "?latitude=" + root._resolvedLat
      + "&longitude=" + root._resolvedLon
      + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,pressure_msl,wind_speed_10m,wind_direction_10m"
      + "&hourly=temperature_2m,weather_code,precipitation_probability"
      + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max"
      + "&timezone=auto"
      + (root._unitMode === "imperial" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch" : "");

    weatherProc.command = ["curl", "-s", "--max-time", "15", url];
    if (!weatherProc.running) weatherProc.running = true;
  }

  function _fetchAqi() {
    if (!root._resolvedLat || !root._resolvedLon) return;
    var url = "https://air-quality-api.open-meteo.com/v1/air-quality"
      + "?latitude=" + root._resolvedLat
      + "&longitude=" + root._resolvedLon
      + "&current=european_aqi,us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone";
    aqiProc.command = ["curl", "-s", "--max-time", "10", url];
    if (!aqiProc.running) aqiProc.running = true;
  }

  property Process geoproc: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var json = JSON.parse(this.text);
          if (json.results && json.results.length > 0) {
            var res = json.results[0];
            root._resolvedLat = res.latitude.toString();
            root._resolvedLon = res.longitude.toString();
            root.location = res.name + (res.admin1 ? ", " + res.admin1 : "");
            root._fetchWeather();
          } else {
            throw new Error("City not found");
          }
        } catch (e) {
          if (root._tryNextLocationSource("Geocoding error", e.message))
            return;
          root._setUnavailableState("Weather unavailable");
          root._reportFailure("Geocoding error", e.message);
        }
      }
    }
  }

  property Process ipapi: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var json = JSON.parse(this.text);
          if (json.latitude && json.longitude) {
            root._resolvedLat = json.latitude.toString();
            root._resolvedLon = json.longitude.toString();
            root.location = json.city + (json.region ? ", " + json.region : "");
            root._fetchWeather();
          } else {
            throw new Error("IP location failed");
          }
        } catch (e) {
          if (root._tryNextLocationSource("Auto-location error", e.message))
            return;
          root._setUnavailableState("Weather unavailable");
          root._reportFailure("Auto-location error", e.message);
        }
      }
    }
  }

  property Process weatherProc: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(this.text);
          if (Config.weatherProvider === "wttr") {
            _parseWttr(data);
          } else {
            _parseOpenMeteo(data);
          }
          root._hasSuccessfulFetch = true;
          root._lastFailureKey = "";
          root._fetchAqi();
        } catch (e) {
          if (Config.weatherProvider === "open-meteo" && root._tryNextLocationSource("Weather parse error", e.message))
            return;
          root._reportFailure("Weather parse error", e.message);
        }
      }
    }
  }

  function _parseWttr(json) {
    var data = json.data || json;
    var cur = (data.current_condition && data.current_condition.length > 0) ? data.current_condition[0] : null;
    if (!cur) throw new Error("missing current condition in wttr response");

    var loc = "Local";
    if (data.nearest_area && data.nearest_area[0]) {
      var area = data.nearest_area[0];
      var areaName = (area.areaName && area.areaName[0] && area.areaName[0].value) ? area.areaName[0].value : "";
      var region = (area.region && area.region[0] && area.region[0].value) ? area.region[0].value : "";
      loc = areaName || region || "Local";
    }

    root.location = loc;
    root.condition = (cur.weatherDesc && cur.weatherDesc[0]) ? cur.weatherDesc[0].value : "Unknown";
    
    // Units are already handled by wttr.in if we pass &u, but it returns strings with units
    // We'll strip them to match our suffixes
    var rawTemp = _unitMode === "imperial" ? cur.temp_F : cur.temp_C;
    root.temp = (rawTemp || "--") + root._tempSuffix;
    
    var rawFeels = _unitMode === "imperial" ? cur.FeelsLikeF : cur.FeelsLikeC;
    root.feelsLike = (rawFeels || "--") + root._tempSuffix;
    
    root.humidity = (cur.humidity || "--") + "%";
    
    var rawWind = _unitMode === "imperial" ? cur.windspeedMiles : cur.windspeedKmph;
    root.windSpeed = (rawWind || "--") + root._windSuffix;
    root.windDir = cur.winddir16Point || "";
    
    var rawVis = _unitMode === "imperial" ? cur.visibilityMiles : cur.visibility;
    root.visibility = (rawVis || "--") + root._visibilitySuffix;

    root.uvIndex = cur.uvIndex || "--";
    root.pressure = (_unitMode === "imperial"
      ? (cur.pressureInches || "--") + " inHg"
      : (cur.pressureMB || "--") + " hPa");
    root.precipitation = (cur.precipMM || "0") + " mm";

    var weather = data.weather || [];
    if (weather.length > 0 && weather[0].astronomy && weather[0].astronomy[0]) {
      var astro = weather[0].astronomy[0];
      root.sunrise = astro.sunrise || "--";
      root.sunset = astro.sunset || "--";
    }

    var daily = [];
    for (var i = 0; i < Math.min(3, weather.length); i++) {
      var w = weather[i];
      var desc = (w.hourly && w.hourly[4] && w.hourly[4].weatherDesc && w.hourly[4].weatherDesc[0])
        ? w.hourly[4].weatherDesc[0].value : "Unknown";
      daily.push({
        date: w.date,
        maxTemp: (_unitMode === "imperial" ? w.maxtempF : w.maxtempC) + "°",
        minTemp: (_unitMode === "imperial" ? w.mintempF : w.mintempC) + "°",
        condition: desc
      });
    }
    root.forecast = daily;

    var hourly = [];
    var currentHour = new Date().getHours();
    for (var d = 0; d < Math.min(2, weather.length); d++) {
      var hours = weather[d].hourly || [];
      for (var h = 0; h < hours.length; h++) {
        var entry = hours[h];
        var hourTime = parseInt(entry.time, 10) / 100;
        if (d === 0 && hourTime < currentHour) continue;
        var hdesc = (entry.weatherDesc && entry.weatherDesc[0])
          ? entry.weatherDesc[0].value : "Unknown";
        hourly.push({
          time: String(Math.floor(hourTime)).padStart(2, '0') + ":00",
          temp: (_unitMode === "imperial" ? entry.tempF : entry.tempC) + "°",
          condition: hdesc,
          chanceOfRain: (entry.chanceofrain || "0") + "%"
        });
      }
    }
    root.hourlyForecast = hourly;

    if (data.nearest_area && data.nearest_area[0]) {
      root._resolvedLat = data.nearest_area[0].latitude || "";
      root._resolvedLon = data.nearest_area[0].longitude || "";
    }
  }

  function _parseOpenMeteo(data) {
    var cur = data.current;
    if (!cur) throw new Error("Missing current weather data");

    root.temp = Math.round(cur.temperature_2m) + root._tempSuffix;
    root.feelsLike = Math.round(cur.apparent_temperature) + root._tempSuffix;
    root.humidity = Math.round(cur.relative_humidity_2m) + "%";
    root.windSpeed = Math.round(cur.wind_speed_10m) + root._windSuffix;
    root.windDir = root._getWindDir(cur.wind_direction_10m);
    root.condition = root._getConditionFromWmo(cur.weather_code);
    root.pressure = Math.round(cur.pressure_msl) + " hPa";
    root.precipitation = cur.precipitation + (root._unitMode === "imperial" ? " in" : " mm");

    if (data.daily) {
      var d = data.daily;
      root.sunrise = (d.sunrise && d.sunrise[0]) ? d.sunrise[0].split("T")[1] : "--";
      root.sunset = (d.sunset && d.sunset[0]) ? d.sunset[0].split("T")[1] : "--";
      root.uvIndex = (d.uv_index_max && d.uv_index_max[0]) ? d.uv_index_max[0].toString() : "--";

      var daily = [];
      for (var i = 0; i < Math.min(3, d.time.length); i++) {
        daily.push({
          date: d.time[i],
          maxTemp: Math.round(d.temperature_2m_max[i]) + "°",
          minTemp: Math.round(d.temperature_2m_min[i]) + "°",
          condition: root._getConditionFromWmo(d.weather_code[i])
        });
      }
      root.forecast = daily;
    }

    if (data.hourly) {
      var h = data.hourly;
      var hourly = [];
      var now = new Date().getTime();
      for (var j = 0; j < h.time.length; j++) {
        var t = new Date(h.time[j]).getTime();
        if (t < now - 3600000) continue;
        if (hourly.length >= 12) break;
        hourly.push({
          time: h.time[j].split("T")[1],
          temp: Math.round(h.temperature_2m[j]) + "°",
          condition: root._getConditionFromWmo(h.weather_code[j]),
          chanceOfRain: h.precipitation_probability[j] + "%"
        });
      }
      root.hourlyForecast = hourly;
    }
  }

  property Process aqiProc: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var json = JSON.parse(this.text);
          var cur = json.current;
          if (!cur) throw new Error("missing current AQI data");

          var useUS = root._unitMode === "imperial";
          var aqiVal = useUS ? cur.us_aqi : cur.european_aqi;
          var v = parseInt(aqiVal);
          
          root.aqi = String(v);
          root.aqiCategory = useUS ? root._aqiCategoryUS(v) : root._aqiCategoryEU(v);
          root.pm25 = (cur.pm2_5 !== undefined) ? String(Math.round(cur.pm2_5 * 10) / 10) : "--";
          root.pm10 = (cur.pm10 !== undefined) ? String(Math.round(cur.pm10 * 10) / 10) : "--";
          root.no2 = (cur.nitrogen_dioxide !== undefined) ? String(Math.round(cur.nitrogen_dioxide * 10) / 10) : "--";
          root.o3 = (cur.ozone !== undefined) ? String(Math.round(cur.ozone * 10) / 10) : "--";
          root.so2 = (cur.sulphur_dioxide !== undefined) ? String(Math.round(cur.sulphur_dioxide * 10) / 10) : "--";
          root.co = (cur.carbon_monoxide !== undefined) ? String(Math.round(cur.carbon_monoxide * 10) / 10) : "--";
        } catch (e) {
          // ignore AQI failures
        }
      }
    }
  }

  property Timer weatherTimer: Timer {
    interval: root._refreshIntervalMs
    running: root._ready && root.subscriberCount > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  property Timer _retryTimer: Timer {
    id: retryTimer
    interval: root._retryIntervalMs
    onTriggered: root.refresh()
  }

  property Timer _configDebounce: Timer {
    id: configDebounce
    interval: root._configDebounceMs
    onTriggered: root.refresh()
  }

  property Connections configConnections: Connections {
    target: Config
    function onWeatherProviderChanged() { configDebounce.restart(); }
    function onWeatherUnitsChanged() { configDebounce.restart(); }
    function onWeatherAutoLocationChanged() { configDebounce.restart(); }
    function onWeatherCityQueryChanged() { configDebounce.restart(); }
    function onWeatherLatitudeChanged() { configDebounce.restart(); }
    function onWeatherLongitudeChanged() { configDebounce.restart(); }
    function onWeatherLocationPriorityChanged() { configDebounce.restart(); }
  }
}
