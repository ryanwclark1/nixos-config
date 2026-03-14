import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  property string temp: "--"
  property string feelsLike: "--"
  property string humidity: "--"
  property string windSpeed: "--"
  property string windDir: ""
  property string visibility: "--"
  property string condition: ""
  property string location: "Local"
  property var forecast: []

  readonly property string _unitMode: Config.weatherUnits === "imperial" ? "imperial" : "metric"
  readonly property string _tempSuffix: _unitMode === "imperial" ? "°F" : "°C"
  readonly property string _windSuffix: _unitMode === "imperial" ? " mph" : " km/h"
  readonly property string _visibilitySuffix: _unitMode === "imperial" ? " mi" : " km"

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
          var data = JSON.parse(raw);

          var cur = (data.current_condition && data.current_condition.length > 0) ? data.current_condition[0] : null;
          if (!cur) throw new Error("missing current condition");

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

          var days = [];
          var weather = data.weather || [];
          for (var i = 0; i < Math.min(3, weather.length); i++) {
            var w = weather[i];
            var desc = (w.hourly && w.hourly[4] && w.hourly[4].weatherDesc && w.hourly[4].weatherDesc[0])
              ? w.hourly[4].weatherDesc[0].value : "Unknown";
            days.push({
              date: w.date,
              maxTemp: _tempValue(w, "maxtemp"),
              minTemp: _tempValue(w, "mintemp"),
              condition: desc
            });
          }
          root.forecast = days;
        } catch (e) {
          console.warn("WeatherService: parse error:", e);
          root.condition = "Error loading weather";
          root.location = "Local";
          root.forecast = [];
        }
      }
    }
  }

  property Timer weatherTimer: Timer {
    interval: 1800000
    running: root._ready
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // Debounce config changes — avoids multiple curl requests when several
  // weather settings change in rapid succession (e.g. SettingsHub batch updates).
  property Timer _configDebounce: Timer {
    interval: 500
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
