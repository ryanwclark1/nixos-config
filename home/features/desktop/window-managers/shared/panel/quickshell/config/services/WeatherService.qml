import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: service

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
      service.temp = "--";
      service.feelsLike = "--";
      service.humidity = "--";
      service.windSpeed = "--";
      service.windDir = "";
      service.visibility = "--";
      service.condition = "Location not configured";
      service.location = "Set city or coordinates";
      service.forecast = [];
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

          service.location = loc;
          service.condition = (cur.weatherDesc && cur.weatherDesc[0]) ? cur.weatherDesc[0].value : "Unknown";
          service.temp = _tempWithUnit(cur, "temp_");
          service.feelsLike = _tempWithUnit(cur, "FeelsLike");
          service.humidity = (cur.humidity || "--") + "%";
          service.windSpeed = _windValue(cur) + _windSuffix;
          service.windDir = cur.winddir16Point || "";
          service.visibility = _visibilityValue(cur);

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
          service.forecast = days;
        } catch (e) {
          console.warn("WeatherService: parse error:", e);
          service.condition = "Error loading weather";
          service.location = "Local";
          service.forecast = [];
        }
      }
    }
  }

  property Timer weatherTimer: Timer {
    interval: 1800000
    running: service._ready
    repeat: true
    triggeredOnStart: true
    onTriggered: service.refresh()
  }

  property Connections configConnections: Connections {
    target: Config
    function onWeatherUnitsChanged() { service.refresh(); }
    function onWeatherAutoLocationChanged() { service.refresh(); }
    function onWeatherCityQueryChanged() { service.refresh(); }
    function onWeatherLatitudeChanged() { service.refresh(); }
    function onWeatherLongitudeChanged() { service.refresh(); }
    function onWeatherLocationPriorityChanged() { service.refresh(); }
  }
}
