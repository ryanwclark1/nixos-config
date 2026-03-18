import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../menu"
import "../../services"
import "../system/sections"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 560; compactThreshold: 520
  implicitHeight: compactMode ? 620 : 560
  title: "Date & Time"
  subtitle: Qt.formatDateTime(clock.date, "dddd, MMMM d")

  SharedWidgets.Ref { service: WeatherService }

  SystemClock {
    id: clock
    precision: Config.timeShowSeconds ? SystemClock.Seconds : SystemClock.Minutes
  }

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingL

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 196 : 132
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      GridLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingL
        columns: root.compactMode ? 1 : 2
        columnSpacing: Colors.spacingL
        rowSpacing: Colors.spacingL

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingXXS

          Text {
            text: Qt.formatDateTime(
              clock.date,
              Config.timeUse24Hour
                ? (Config.timeShowSeconds ? "HH:mm:ss" : "HH:mm")
                : (Config.timeShowSeconds ? "hh:mm:ss AP" : "hh:mm AP")
            )
            color: Colors.text
            font.pixelSize: root.compactMode ? 48 : 60
            font.weight: Font.Bold
            font.letterSpacing: -1.0
          }

          Text {
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")
            color: Colors.textSecondary
            font.pixelSize: root.compactMode ? Colors.fontSizeMedium : Colors.fontSizeLarge
            wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
            Layout.fillWidth: true
          }
        }

        ColumnLayout {
          Layout.fillWidth: root.compactMode
          Layout.preferredWidth: root.compactMode ? -1 : 160
          spacing: Colors.spacingXS

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 88
            radius: Colors.radiusMedium
            color: Colors.withAlpha(Colors.primary, 0.08)
            border.color: Colors.withAlpha(Colors.primary, 0.2)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Colors.spacingM
              spacing: 2

              RowLayout {
                spacing: Colors.spacingXS
                Text {
                  text: Colors.weatherIcon(WeatherService.condition)
                  color: Colors.accent
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeLarge
                }
                Text {
                  text: WeatherService.temp || "--"
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeXL
                  font.weight: Font.Bold
                }
              }

              Text {
                text: WeatherService.location || "Local"
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: WeatherService.condition || "Clear"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXXS
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }
          }
        }
      }
    }

    Calendar {
      Layout.fillWidth: true
      Layout.preferredHeight: 310
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingS

      SharedWidgets.SectionLabel { label: "WEATHER DETAILS" }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.compactMode ? 140 : 96
        radius: Colors.radiusMedium
        color: Colors.cardSurface
        border.color: Colors.border
        border.width: 1

        GridLayout {
          anchors.fill: parent
          anchors.margins: Colors.spacingL
          columns: root.compactMode ? 1 : 2
          columnSpacing: Colors.spacingL
          rowSpacing: Colors.spacingM

          RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingL

            Rectangle {
              width: 44; height: 44
              radius: Colors.radiusSmall
              color: Colors.withAlpha(Colors.accent, 0.1)
              Text {
                anchors.centerIn: parent
                text: Colors.weatherIcon(WeatherService.condition)
                color: Colors.accent
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeDisplay
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              Text {
                text: WeatherService.condition || "Loading weather"
                color: Colors.text
                font.pixelSize: Colors.fontSizeLarge
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: (WeatherService.location || "Local") + "  •  Feels like " + (WeatherService.feelsLike || "--")
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingM

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0
              Text {
                text: "Humidity: " + (WeatherService.humidity || "--")
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
              }
              Text {
                text: "Wind: " + (WeatherService.windSpeed || "--")
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
              }
            }

            Rectangle {
              implicitWidth: weatherButtonLabel.implicitWidth + 28
              implicitHeight: 32
              radius: Colors.radiusPill
              color: Colors.highlight
              border.color: Colors.primary
              border.width: 1
              Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

              SharedWidgets.StateLayer {
                id: fullWeatherState
                hovered: fullWeatherMouse.containsMouse
                pressed: fullWeatherMouse.pressed
              }

              Text {
                id: weatherButtonLabel
                anchors.centerIn: parent
                text: "Full Report"
                color: Colors.primary
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Bold
              }

              MouseArea {
                id: fullWeatherMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  fullWeatherState.burst(mouse.x, mouse.y);
                  Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleSurface", "weatherMenu"]);
                }
              }
            }
          }
        }
      }
    }
  }
}
