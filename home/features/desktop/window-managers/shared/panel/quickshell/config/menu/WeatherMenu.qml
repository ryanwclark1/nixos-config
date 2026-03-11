import Quickshell
import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  implicitWidth: 380
  implicitHeight: 520

  // Current conditions
  property string currentTemp: "--"
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
    var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
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
        var cur = data.current_condition[0];
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
      if (v.currentTemp) root.currentTemp = v.currentTemp;
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

  Rectangle {
    anchors.fill: parent
    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 14

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Weather"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        SharedWidgets.MenuCloseButton { toggleMethod: "toggleWeatherMenu" }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
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
          anchors.margins: 14
          spacing: 14

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
              color: Colors.fgMain
              font.pixelSize: 36
              font.weight: Font.Bold
            }
            Text {
              text: root.condition
              color: Colors.fgSecondary
              font.pixelSize: 12
              font.weight: Font.Medium
            }
            Text {
              text: root.location
              color: Colors.textDisabled
              font.pixelSize: 10
            }
          }

          // Details column
          ColumnLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
              spacing: 4
              Text { text: "Feels"; color: Colors.textDisabled; font.pixelSize: 9 }
              Text { text: root.feelsLike; color: Colors.fgSecondary; font.pixelSize: 10; font.weight: Font.Medium }
            }
            RowLayout {
              spacing: 4
              Text { text: "Humidity"; color: Colors.textDisabled; font.pixelSize: 9 }
              Text { text: root.humidity; color: Colors.fgSecondary; font.pixelSize: 10; font.weight: Font.Medium }
            }
            RowLayout {
              spacing: 4
              Text { text: "Wind"; color: Colors.textDisabled; font.pixelSize: 9 }
              Text { text: root.windSpeed + " " + root.windDir; color: Colors.fgSecondary; font.pixelSize: 10; font.weight: Font.Medium }
            }
            RowLayout {
              spacing: 4
              Text { text: "Visibility"; color: Colors.textDisabled; font.pixelSize: 9 }
              Text { text: root.visibility; color: Colors.fgSecondary; font.pixelSize: 10; font.weight: Font.Medium }
            }
          }
        }
      }

      // Forecast section label
      Text {
        text: "3-DAY FORECAST"
        color: Colors.textDisabled
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.5
      }

      // Forecast days
      Repeater {
        model: root.forecast
        delegate: Rectangle {
          Layout.fillWidth: true
          implicitHeight: 60
          radius: Colors.radiusMedium
          color: forecastHover.containsMouse ? Colors.highlightLight : Colors.cardSurface
          border.color: Colors.border
          border.width: 1

          Behavior on color { ColorAnimation { duration: 150 } }

          MouseArea {
            id: forecastHover
            anchors.fill: parent
            hoverEnabled: true
          }

          RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Day name
            Text {
              text: root.dayName(modelData.date)
              color: Colors.fgMain
              font.pixelSize: 13
              font.weight: Font.DemiBold
              Layout.preferredWidth: 70
            }

            // Condition icon
            Text {
              text: Colors.weatherIcon(modelData.condition)
              color: Colors.accent
              font.family: Colors.fontMono
              font.pixelSize: 22
            }

            // Description
            Text {
              text: modelData.condition
              color: Colors.fgSecondary
              font.pixelSize: 11
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            // Min temp
            Text {
              text: modelData.minTemp + "°"
              color: Colors.textDisabled
              font.pixelSize: 12
            }

            // Max temp with up arrow
            RowLayout {
              spacing: 2
              Text {
                text: "↑"
                color: Colors.primary
                font.pixelSize: 11
              }
              Text {
                text: modelData.maxTemp + "°"
                color: Colors.fgMain
                font.pixelSize: 12
                font.weight: Font.DemiBold
              }
            }
          }
        }
      }

      Item { Layout.fillHeight: true }
    }
  }
}
