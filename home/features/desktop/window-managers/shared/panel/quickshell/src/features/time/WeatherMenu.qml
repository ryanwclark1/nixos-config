import QtQuick
import QtQuick.Layouts
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 500; compactThreshold: 460
  implicitHeight: compactMode ? 760 : 700
  title: "Weather"
  subtitle: WeatherService.location || "Local"

  SharedWidgets.Ref { service: WeatherService }

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
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 182 : 132

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
            color: Colors.textSecondary
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

          SharedWidgets.InfoRow {
            label: "Feels"
            value: WeatherService.feelsLike || "--"
          }
          SharedWidgets.InfoRow {
            label: "Humidity"
            value: WeatherService.humidity || "--"
          }
          SharedWidgets.InfoRow {
            label: "Wind"
            value: (WeatherService.windSpeed || "--") + (WeatherService.windDir ? (" " + WeatherService.windDir) : "")
          }
          SharedWidgets.InfoRow {
            label: "Visibility"
            value: WeatherService.visibility || "--"
          }
        }
      }
    }

    // ── Additional details row ──────────────────
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      implicitHeight: detailsGrid.implicitHeight + Colors.spacingM * 2

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
            Text { text: "↓" + WeatherService.sunset; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
          }
        }
      }
    }

    // ── Air Quality card ──────────────────────────
    SharedWidgets.ThemedContainer {
      variant: "card"
      Layout.fillWidth: true
      visible: WeatherService.aqi !== "--"
      implicitHeight: aqiContent.implicitHeight + Colors.spacingM * 2

      ColumnLayout {
        id: aqiContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingS

        RowLayout {
          spacing: Colors.spacingS

          Rectangle {
            width: 10; height: 10; radius: 5
            color: Colors.aqiColor(WeatherService.aqi, Config.weatherUnits === "imperial")
          }

          Text {
            text: "AQI " + WeatherService.aqi
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.DemiBold
          }

          Text {
            text: WeatherService.aqiCategory
            color: Colors.aqiColor(WeatherService.aqi, Config.weatherUnits === "imperial")
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Medium
          }
        }

        GridLayout {
          Layout.fillWidth: true
          columns: root.compactMode ? 2 : 3
          columnSpacing: Colors.spacingL
          rowSpacing: Colors.spacingXS

          SharedWidgets.InfoRow { label: "PM2.5"; value: WeatherService.pm25 }
          SharedWidgets.InfoRow { label: "PM10"; value: WeatherService.pm10 }
          SharedWidgets.InfoRow { label: "O\u2083"; value: WeatherService.o3 }
          SharedWidgets.InfoRow { label: "NO\u2082"; value: WeatherService.no2 }
          SharedWidgets.InfoRow { label: "SO\u2082"; value: WeatherService.so2 }
          SharedWidgets.InfoRow { label: "CO"; value: WeatherService.co }
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

          delegate: SharedWidgets.ThemedContainer {
            variant: "card"
            width: 62
            height: 72

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
        color: forecastHover.containsMouse ? Colors.primaryFaint : Colors.cardSurface
        border.color: forecastHover.containsMouse ? Colors.primary : Colors.border
        border.width: 1

        SharedWidgets.InnerHighlight { hoveredOpacity: 0.2; hovered: forecastHover.containsMouse }

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
            color: Colors.textSecondary
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
