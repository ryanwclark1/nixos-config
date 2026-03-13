import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  implicitWidth: 500
  implicitHeight: 560
  title: "Weather"
  subtitle: WeatherService.location || "Local"
  toggleMethod: "toggleWeatherMenu"

  function dayName(dateStr) {
    var parts = String(dateStr || "").split("-");
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

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 124
    radius: Colors.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: Colors.spacingM
      spacing: Colors.spacingM

      Text {
        text: Colors.weatherIcon(WeatherService.condition)
        color: Colors.accent
        font.family: Colors.fontMono
        font.pixelSize: 44
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: WeatherService.temp || "--"
          color: Colors.text
          font.pixelSize: 36
          font.weight: Font.Bold
        }

        Text {
          text: WeatherService.condition || "Loading weather"
          color: Colors.fgSecondary
          font.pixelSize: Colors.fontSizeLarge
          font.weight: Font.DemiBold
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: WeatherService.location || "Local"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeSmall
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }

      ColumnLayout {
        spacing: 2

        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "Feels"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeSmall }
          Text { text: WeatherService.feelsLike || "--"; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
        }

        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "Humidity"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeSmall }
          Text { text: WeatherService.humidity || "--"; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
        }

        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "Wind"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeSmall }
          Text {
            text: (WeatherService.windSpeed || "--") + (WeatherService.windDir ? (" " + WeatherService.windDir) : "")
            color: Colors.fgSecondary
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Medium
          }
        }

        RowLayout {
          spacing: Colors.spacingXS
          Text { text: "Visibility"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeSmall }
          Text { text: WeatherService.visibility || "--"; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
        }
      }
    }
  }

  SharedWidgets.SectionLabel { label: "FORECAST" }

  Repeater {
    model: WeatherService.forecast || []
    delegate: Rectangle {
      Layout.fillWidth: true
      implicitHeight: 58
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
          Layout.preferredWidth: 76
        }

        Text {
          text: Colors.weatherIcon(modelData.condition)
          color: Colors.accent
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeXL
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
