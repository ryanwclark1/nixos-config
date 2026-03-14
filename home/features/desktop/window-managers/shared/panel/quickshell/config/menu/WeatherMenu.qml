import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 500; compactThreshold: 460
  implicitHeight: compactMode ? 760 : 700
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

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingM

    // ── Current conditions card ──────────────────
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 182 : 132
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      GridLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        columns: root.compactMode ? 1 : 3
        columnSpacing: Colors.spacingM
        rowSpacing: Colors.spacingM

        Text {
          text: Colors.weatherIcon(WeatherService.condition)
          color: Colors.accent
          font.family: Colors.fontMono
          font.pixelSize: root.compactMode ? 38 : 46
          Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingXXS

          Text {
            text: WeatherService.temp || "--"
            color: Colors.text
            font.pixelSize: root.compactMode ? 32 : 38
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
            font.pixelSize: Colors.fontSizeMedium
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }

        ColumnLayout {
          Layout.fillWidth: root.compactMode
          spacing: Colors.spacingXS

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

    // ── Additional details row ──────────────────
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: detailsGrid.implicitHeight + Colors.spacingM * 2
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      GridLayout {
        id: detailsGrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Colors.spacingM
        columns: root.compactMode ? 2 : 4
        columnSpacing: Colors.spacingL
        rowSpacing: Colors.spacingS

        // UV Index
        ColumnLayout {
          spacing: Colors.spacingXXS
          Text { text: "UV Index"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
          Text { text: WeatherService.uvIndex; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold }
        }

        // Pressure
        ColumnLayout {
          spacing: Colors.spacingXXS
          Text { text: "Pressure"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
          Text { text: WeatherService.pressure; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold }
        }

        // Precipitation
        ColumnLayout {
          spacing: Colors.spacingXXS
          Text { text: "Precip"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
          Text { text: WeatherService.precipitation; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold }
        }

        // Sunrise / Sunset
        ColumnLayout {
          spacing: Colors.spacingXXS
          Text { text: "Sun"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
          RowLayout {
            spacing: Colors.spacingXS
            Text { text: "↑" + WeatherService.sunrise; color: Colors.accent; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
            Text { text: "↓" + WeatherService.sunset; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
          }
        }
      }
    }

    // ── Hourly forecast ──────────────────────────
    SharedWidgets.SectionLabel {
      label: "HOURLY"
      visible: WeatherService.hourlyForecast.length > 0
    }

    Flickable {
      Layout.fillWidth: true
      implicitHeight: 78
      visible: WeatherService.hourlyForecast.length > 0
      contentWidth: hourlyRow.width
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.HorizontalFlick

      Row {
        id: hourlyRow
        spacing: Colors.spacingXS

        Repeater {
          model: WeatherService.hourlyForecast

          delegate: Rectangle {
            width: 62
            height: 72
            radius: Colors.radiusXS
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Colors.spacingXS
              spacing: Colors.spacingXXS

              Text {
                text: modelData.time
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
              }

              Text {
                text: Colors.weatherIcon(modelData.condition)
                color: Colors.accent
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeLarge
                Layout.alignment: Qt.AlignHCenter
              }

              Text {
                text: modelData.temp
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
              }

              Text {
                text: modelData.chanceOfRain
                color: Colors.primary
                font.pixelSize: Colors.fontSizeXS
                visible: modelData.chanceOfRain !== "0%"
                Layout.alignment: Qt.AlignHCenter
              }
            }
          }
        }
      }
    }

    // ── Daily forecast ──────────────────────────
    SharedWidgets.SectionLabel { label: "FORECAST" }

    Repeater {
      model: WeatherService.forecast || []
      delegate: Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.compactMode ? 78 : 60
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

        GridLayout {
          anchors.fill: parent
          anchors.margins: Colors.spacingM
          columns: root.compactMode ? 2 : 5
          columnSpacing: Colors.spacingM
          rowSpacing: root.compactMode ? Colors.spacingXS : 0

          Text {
            text: root.dayName(modelData.date)
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.DemiBold
            Layout.preferredWidth: root.compactMode ? -1 : 76
            Layout.fillWidth: root.compactMode
          }

          Text {
            text: Colors.weatherIcon(modelData.condition)
            color: Colors.accent
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeXL
            Layout.alignment: root.compactMode ? Qt.AlignRight : Qt.AlignLeft
          }

          Text {
            text: modelData.condition
            color: Colors.fgSecondary
            font.pixelSize: Colors.fontSizeSmall
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.columnSpan: root.compactMode ? 2 : 1
          }

          // Precipitation chance badge
          Text {
            visible: modelData.chanceOfRain !== undefined && modelData.chanceOfRain !== "--" && modelData.chanceOfRain !== "0%"
            text: "💧" + modelData.chanceOfRain
            color: Colors.primary
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Medium
            Layout.columnSpan: root.compactMode ? 1 : 1
          }

          RowLayout {
            spacing: Colors.spacingXXS
            Layout.columnSpan: root.compactMode ? (modelData.chanceOfRain !== undefined && modelData.chanceOfRain !== "--" && modelData.chanceOfRain !== "0%" ? 1 : 2) : 1
            Text {
              text: "Low " + modelData.minTemp + "\u00b0"
              color: Colors.textDisabled
              font.pixelSize: Colors.fontSizeMedium
            }
            Text {
              text: "\u2022"
              color: Colors.border
              font.pixelSize: Colors.fontSizeMedium
            }
            Text {
              text: "High"
              color: Colors.primary
              font.pixelSize: Colors.fontSizeSmall
            }
            Text {
              text: modelData.maxTemp + "\u00b0"
              color: Colors.text
              font.pixelSize: Colors.fontSizeMedium
              font.weight: Font.DemiBold
            }
          }
        }
      }
    }
  }
}
