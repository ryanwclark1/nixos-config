pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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

  // ── Air Quality (Open-Meteo) ──────────────────
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

  readonly property string _unitMode: Config.weatherUnits === "imperial" ? "imperial" : "metric"
  readonly property string _tempSuffix: _unitMode === "imperial" ? "°F" : "°C"
  readonly property string _windSuffix: _unitMode === "imperial" ? " mph" : " km/h"
  readonly property string _visibilitySuffix: _unitMode === "imperial" ? " mi" : " km"

  // ── Named constants ──────────────────────────
  readonly property int _refreshIntervalMs: 1800000  // 30 min
  readonly property int _configDebounceMs: 500

  // Deferred activation flag — ensures Timer starts via a false→true transition
  // after the event loop is ready.
  property bool _ready: false
  Component.onCompleted: _ready = true

  function _hasValidLatLon() {
    var lat = parseFloat(Config.weatherLatitude);
    var lon = parseFloat(Config.weatherLongitude);
    return !isNaN(lat) && !isNaN(lon) && Math.abs(lat) <= 90 && Math.abs(lon) <= 180;
  }

  function _sourceByPriority() {
    var city = String(Config.weatherCityQuery || "").trim();
    var autoAllowed = !!Config.weatherAutoLocation;
    var priority = String(Config.weatherLocationPriority || "latlon_city_auto");

    var hasLatLon = _hasValidLatLon();
    var hasCity = city.length > 0;

    if (priority === "city_auto_latlon") {
      if (hasCity) return { kind: "city", target: encodeURIComponent(city) };
      if (autoAllowed) return { kind: "auto", target: "" };
      if (hasLatLon) return { kind: "latlon", target: parseFloat(Config.weatherLatitude) + "," + parseFloat(Config.weatherLongitude) };
      return { kind: "none", target: "" };
    }

    if (priority === "latlon_city_auto") {
      if (hasLatLon) return { kind: "latlon", target: parseFloat(Config.weatherLatitude) + "," + parseFloat(Config.weatherLongitude) };
      if (hasCity) return { kind: "city", target: encodeURIComponent(city) };
      if (autoAllowed) return { kind: "auto", target: "" };
      return { kind: "none", target: "" };
    }

    // auto_city_latlon
    if (autoAllowed) return { kind: "auto", target: "" };
    if (hasCity) return { kind: "city", target: encodeURIComponent(city) };
    if (hasLatLon) return { kind: "latlon", target: parseFloat(Config.weatherLatitude) + "," + parseFloat(Config.weatherLongitude) };
    return { kind: "none", target: "" };
  }

  function _tempValue(item, baseKey) {
    if (!item) return "--";
    if (_unitMode === "imperial") return item[baseKey + "F"] || "--";
    return item[baseKey + "C"] || "--";
  }

  function _windValue(item) {
    if (!item) return "--";
    return _unitMode === "imperial" ? (item.windspeedMiles || "--") : (item.windspeedKmph || "--");
  }

  function _visibilityValue(item) {
    if (!item) return "--";
    var raw = _unitMode === "imperial" ? item.visibilityMiles : item.visibility;
    return (raw || "--") + _visibilitySuffix;
  }

  function _tempWithUnit(item, baseKey) {
    return _tempValue(item, baseKey) + _tempSuffix;
  }

  function _resetAqiState() {
    root.aqi = "--"; root.aqiCategory = "";
    root.pm25 = "--"; root.pm10 = "--";
    root.no2 = "--"; root.o3 = "--";
    root.so2 = "--"; root.co = "--";
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

  function _fetchAqi() {
    if (!root._resolvedLat || !root._resolvedLon) { _resetAqiState(); return; }
    var url = "https://air-quality-api.open-meteo.com/v1/air-quality"
      + "?latitude=" + root._resolvedLat
      + "&longitude=" + root._resolvedLon
      + "&current=european_aqi,us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone";
    aqiProc.command = ["curl", "-s", "--max-time", "10", url];
    if (!aqiProc.running) aqiProc.running = true;
  }

  function _setUnavailableState() {
    root.temp = "--";
    root.feelsLike = "--";
    root.humidity = "--";
    root.windSpeed = "--";
    root.windDir = "";
    root.visibility = "--";
    root.condition = "Weather unavailable";
    root.location = "Local";
    root.forecast = [];
    root.hourlyForecast = [];
    root.uvIndex = "--";
    root.pressure = "--";
    root.precipitation = "--";
    root.sunrise = "--";
    root.sunset = "--";
    root._resolvedLat = "";
    root._resolvedLon = "";
    root._resetAqiState();
  }

  function _reportFailure(key, details) {
    var failureKey = String(key || "unknown");
    if (root._lastFailureKey !== failureKey) {
      root._lastFailureKey = failureKey;
      if (details)
        console.warn("WeatherService:", failureKey, details);
      else
        console.warn("WeatherService:", failureKey);
    }

    // Preserve the last known-good snapshot for transient upstream/API failures.
    if (!root._hasSuccessfulFetch)
      root._setUnavailableState();
  }

  function refresh() {
    var url = _buildUrl();
    if (!url) {
      root.temp = "--";
      root.feelsLike = "--";
      root.humidity = "--";
      root.windSpeed = "--";
      root.windDir = "";
      root.visibility = "--";
      root.condition = "Location not configured";
      root.location = "Set city or coordinates";
      root.forecast = [];
      root.hourlyForecast = [];
      root.uvIndex = "--";
      root.pressure = "--";
      root.precipitation = "--";
      root.sunrise = "--";
      root.sunset = "--";
      root._resolvedLat = "";
      root._resolvedLon = "";
      root._resetAqiState();
      return;
    }

    weatherProc.command = ["curl", "-s", "--max-time", "15", url];
    if (!weatherProc.running) weatherProc.running = true;
  }

  function _buildUrl() {
    var source = _sourceByPriority();
    if (source.kind === "none") return "";

    var base = source.target ? ("https://wttr.in/" + source.target) : "https://wttr.in/";
    var unitFlag = _unitMode === "imperial" ? "&u" : "";
    return base + "?format=j1" + unitFlag;
  }

  property Process weatherProc: Process {
    command: ["sh", "-c", "echo"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = String(this.text || "").trim();
          if (!raw) throw new Error("empty weather response");
          if (raw.indexOf("{") !== 0) throw new Error("response is not JSON");
          var json = JSON.parse(raw);
          var data = json.data || json; // Handle wrapped or unwrapped data

          var cur = (data.current_condition && data.current_condition.length > 0) ? data.current_condition[0] : null;
          if (!cur) {
            throw new Error("missing current condition");
          }

          var loc = "Local";
          if (data.nearest_area && data.nearest_area[0]) {
            var area = data.nearest_area[0];
            var areaName = (area.areaName && area.areaName[0] && area.areaName[0].value) ? area.areaName[0].value : "";
            var region = (area.region && area.region[0] && area.region[0].value) ? area.region[0].value : "";
            loc = areaName || region || "Local";
          }

          root.location = loc;
          root.condition = (cur.weatherDesc && cur.weatherDesc[0]) ? cur.weatherDesc[0].value : "Unknown";
          root.temp = _tempWithUnit(cur, "temp_");
          root.feelsLike = _tempWithUnit(cur, "FeelsLike");
          root.humidity = (cur.humidity || "--") + "%";
          root.windSpeed = _windValue(cur) + _windSuffix;
          root.windDir = cur.winddir16Point || "";
          root.visibility = _visibilityValue(cur);

          // Additional current condition data
          root.uvIndex = cur.uvIndex || "--";
          root.pressure = (_unitMode === "imperial"
            ? (cur.pressureInches || "--") + " inHg"
            : (cur.pressureMB || "--") + " hPa");
          root.precipitation = (cur.precipMM || "0") + " mm";

          var weather = data.weather || [];

          // Astronomy (sunrise/sunset) from first day
          if (weather.length > 0 && weather[0].astronomy && weather[0].astronomy[0]) {
            var astro = weather[0].astronomy[0];
            root.sunrise = astro.sunrise || "--";
            root.sunset = astro.sunset || "--";
          } else {
            root.sunrise = "--";
            root.sunset = "--";
          }

          // Daily forecast
          var days = [];
          for (var i = 0; i < Math.min(3, weather.length); i++) {
            var w = weather[i];
            var desc = (w.hourly && w.hourly[4] && w.hourly[4].weatherDesc && w.hourly[4].weatherDesc[0])
              ? w.hourly[4].weatherDesc[0].value : "Unknown";
            days.push({
              date: w.date,
              maxTemp: _tempValue(w, "maxtemp"),
              minTemp: _tempValue(w, "mintemp"),
              condition: desc,
              chanceOfRain: (w.hourly && w.hourly[4]) ? (w.hourly[4].chanceofrain || "0") + "%" : "--",
              sunrise: (w.astronomy && w.astronomy[0]) ? w.astronomy[0].sunrise : "",
              sunset: (w.astronomy && w.astronomy[0]) ? w.astronomy[0].sunset : ""
            });
          }
          root.forecast = days;

          // Hourly forecast: remaining hours today + tomorrow
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
                temp: _tempWithUnit(entry, "temp"),
                condition: hdesc,
                chanceOfRain: (entry.chanceofrain || "0") + "%",
                windSpeed: _windValue(entry) + _windSuffix
              });
            }
          }
          root.hourlyForecast = hourly;
          root._hasSuccessfulFetch = true;
          root._lastFailureKey = "";

          // Extract lat/lon for AQI fetch
          var source = root._sourceByPriority();
          if (source.kind === "latlon") {
            var parts = source.target.split(",");
            root._resolvedLat = parts[0];
            root._resolvedLon = parts[1];
          } else if (data.nearest_area && data.nearest_area[0]) {
            root._resolvedLat = data.nearest_area[0].latitude || "";
            root._resolvedLon = data.nearest_area[0].longitude || "";
          }
          root._fetchAqi();
        } catch (e) {
          root._reportFailure(String(e || "parse error"));
        }
      }
    }
  }

  property Process aqiProc: Process {
    command: ["sh", "-c", "echo"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = String(this.text || "").trim();
          if (!raw || raw.indexOf("{") !== 0) throw new Error("invalid AQI response");
          var json = JSON.parse(raw);
          var cur = json.current;
          if (!cur) throw new Error("missing current AQI data");

          var useUS = root._unitMode === "imperial";
          var aqiVal = useUS ? cur.us_aqi : cur.european_aqi;
          var v = parseInt(aqiVal);
          if (isNaN(v)) throw new Error("invalid AQI value");

          root.aqi = String(v);
          root.aqiCategory = useUS ? root._aqiCategoryUS(v) : root._aqiCategoryEU(v);
          root.pm25 = (cur.pm2_5 !== undefined && cur.pm2_5 !== null) ? String(Math.round(cur.pm2_5 * 10) / 10) : "--";
          root.pm10 = (cur.pm10 !== undefined && cur.pm10 !== null) ? String(Math.round(cur.pm10 * 10) / 10) : "--";
          root.no2 = (cur.nitrogen_dioxide !== undefined && cur.nitrogen_dioxide !== null) ? String(Math.round(cur.nitrogen_dioxide * 10) / 10) : "--";
          root.o3 = (cur.ozone !== undefined && cur.ozone !== null) ? String(Math.round(cur.ozone * 10) / 10) : "--";
          root.so2 = (cur.sulphur_dioxide !== undefined && cur.sulphur_dioxide !== null) ? String(Math.round(cur.sulphur_dioxide * 10) / 10) : "--";
          root.co = (cur.carbon_monoxide !== undefined && cur.carbon_monoxide !== null) ? String(Math.round(cur.carbon_monoxide * 10) / 10) : "--";
        } catch (e) {
          root._resetAqiState();
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

  // Debounce config changes — avoids multiple curl requests when several
  // weather settings change in rapid succession (e.g. SettingsHub batch updates).
  property Timer _configDebounce: Timer {
    interval: root._configDebounceMs
    onTriggered: root.refresh()
  }

  property Connections configConnections: Connections {
    target: Config
    function onWeatherUnitsChanged() { root._configDebounce.restart(); }
    function onWeatherAutoLocationChanged() { root._configDebounce.restart(); }
    function onWeatherCityQueryChanged() { root._configDebounce.restart(); }
    function onWeatherLatitudeChanged() { root._configDebounce.restart(); }
    function onWeatherLongitudeChanged() { root._configDebounce.restart(); }
    function onWeatherLocationPriorityChanged() { root._configDebounce.restart(); }
  }
}
