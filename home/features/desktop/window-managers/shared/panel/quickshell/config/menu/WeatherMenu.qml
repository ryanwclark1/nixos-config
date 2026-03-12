import Quickshell
import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  implicitWidth: 380
  implicitHeight: 520
  title: "Weather"
  toggleMethod: "toggleWeatherMenu"

  // Current conditions — headline temp comes from WeatherService (same as bar)
  // to avoid discrepancy between the two API formats.
  readonly property string currentTemp: WeatherService.temp || "--"
  property string feelsLike: "--"
  property string humidity: "--"
  property string windSpeed: "--"
  property string windDir: ""
  property string condition: "Loading..."
  property string visibility: "--"
  property string location: "Local"

  // 3-day forecast
  property var forecast: []

  function dayName(dateStr) {
    var parts = dateStr.split("-");
    if (parts.length < 3) return dateStr;
    var d = new Date(parseInt(parts[0], 10) || 2000, (parseInt(parts[1], 10) || 1) - 1, parseInt(parts[2], 10) || 1);
    var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    var today = new Date();
    if (d.toDateString() === today.toDateString()) return "Today";
    var tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    if (d.toDateString() === tomorrow.toDateString()) return "Tomorrow";
    return days[d.getDay()];
  }

  SharedWidgets.CommandPoll {
    id: weatherPoll
    interval: 1800000
    running: root.visible
    command: ["sh", "-c", "curl -s --max-time 15 'wttr.in?format=j1'"]
    parse: function(out) {
      try {
        var data = JSON.parse(out);
        var cur = (data.current_condition && data.current_condition.length > 0) ? data.current_condition[0] : null;
        if (!cur) return { condition: "No weather data" };
        var loc = (data.nearest_area && data.nearest_area[0] && data.nearest_area[0].areaName && data.nearest_area[0].areaName[0])
          ? data.nearest_area[0].areaName[0].value : "Local";
        var days = [];
        var weather = data.weather;
        for (var i = 0; i < Math.min(3, weather.length); i++) {
          var w = weather[i];
          var noonDesc = (w.hourly && w.hourly[4] && w.hourly[4].weatherDesc && w.hourly[4].weatherDesc[0])
            ? w.hourly[4].weatherDesc[0].value : "Unknown";
          days.push({ date: w.date, maxTemp: w.maxtempC, minTemp: w.mintempC, condition: noonDesc });
        }
        return {
          currentTemp: cur.temp_C + "°C", feelsLike: cur.FeelsLikeC + "°C",
          humidity: cur.humidity + "%", windSpeed: cur.windspeedKmph + " km/h",
          windDir: cur.winddir16Point || "",
          condition: (cur.weatherDesc && cur.weatherDesc[0]) ? cur.weatherDesc[0].value : "Unknown",
          visibility: (cur.visibility || "--") + " km", location: loc, forecast: days
        };
      } catch (e) {
        return { condition: "Error loading weather" };
      }
    }
    onUpdated: {
      var v = weatherPoll.value;
      // currentTemp is a readonly binding to WeatherService.temp — don't overwrite
      if (v.feelsLike) root.feelsLike = v.feelsLike;
      if (v.humidity) root.humidity = v.humidity;
      if (v.windSpeed) root.windSpeed = v.windSpeed;
      if (v.windDir !== undefined) root.windDir = v.windDir;
      if (v.condition) root.condition = v.condition;
      if (v.visibility) root.visibility = v.visibility;
      if (v.location) root.location = v.location;
      if (v.forecast) root.forecast = v.forecast;
    }
  }

  // Current conditions card
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 110
    radius: Colors.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: Colors.spacingM
      spacing: Colors.spacingM

      // Big weather icon
      Text {
        text: Colors.weatherIcon(root.condition)
        color: Colors.accent
        font.family: Colors.fontMono
        font.pixelSize: 48
        Layout.alignment: Qt.AlignVCenter
      }

      // Temp + condition + location
      ColumnLayout {
        spacing: 2
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter

        Text {
          text: root.currentTemp
          color: Colors.text
          font.pixelSize: 36
          font.weight: Font.Bold
        }
        Text {
          text: root.condition
          color: Colors.fgSecondary
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Medium
        }
        Text {
          text: root.location
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
        }
      }

      // Details column
      ColumnLayout {
        spacing: Colors.spacingXS
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "Feels"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS }
          Text { text: root.feelsLike; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
        }
        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "Humidity"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS }
          Text { text: root.humidity; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
        }
        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "Wind"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS }
          Text { text: root.windSpeed + " " + root.windDir; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
        }
        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "Visibility"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS }
          Text { text: root.visibility; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
        }
      }
    }
  }

  // Forecast section label
  SharedWidgets.SectionLabel { label: "3-DAY FORECAST" }

  // Forecast days
  Repeater {
    model: root.forecast
    delegate: Rectangle {
      Layout.fillWidth: true
      implicitHeight: 60
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      SharedWidgets.StateLayer {
        hovered: forecastHover.containsMouse
        pressed: forecastHover.pressed
        enableRipple: false
      }

      MouseArea {
        id: forecastHover
        anchors.fill: parent
        hoverEnabled: true
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingM

        Text {
          text: root.dayName(modelData.date)
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.DemiBold
          Layout.preferredWidth: 70
        }

        Text {
          text: Colors.weatherIcon(modelData.condition)
          color: Colors.accent
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeHuge
        }

        Text {
          text: modelData.condition
          color: Colors.fgSecondary
          font.pixelSize: Colors.fontSizeSmall
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: modelData.minTemp + "°"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeMedium
        }

        RowLayout {
          spacing: 2
          Text {
            text: "↑"
            color: Colors.primary
            font.pixelSize: Colors.fontSizeSmall
          }
          Text {
            text: modelData.maxTemp + "°"
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.DemiBold
          }
        }
      }
    }
  }

  Item { Layout.fillHeight: true }
}
