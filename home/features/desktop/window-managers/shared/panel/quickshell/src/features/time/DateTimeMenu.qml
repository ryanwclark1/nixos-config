import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/ShellUtils.js" as SU
import "../system/sections"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 400; popupMaxWidth: 620; compactThreshold: 580
  // Tall enough for clock + calendar + weather strip without Flickable scroll on default scaling.
  implicitHeight: compactMode ? 860 : 800
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
    columnSpacing: Appearance.spacingL

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 196 : 132
      radius: Appearance.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      GridLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacingL
        columns: root.compactMode ? 1 : 2
        columnSpacing: Appearance.spacingL
        rowSpacing: Appearance.spacingL

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingXXS

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
            font.pixelSize: root.compactMode ? Appearance.fontSizeMedium : Appearance.fontSizeLarge
            wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
            Layout.fillWidth: true
          }
        }

        ColumnLayout {
          Layout.fillWidth: root.compactMode
          Layout.preferredWidth: root.compactMode ? -1 : 160
          spacing: Appearance.spacingXS

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 88
            radius: Appearance.radiusMedium
            color: Colors.withAlpha(Colors.primary, 0.08)
            border.color: Colors.withAlpha(Colors.primary, 0.2)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Appearance.spacingM
              spacing: Appearance.spacingXXS

              RowLayout {
                spacing: Appearance.spacingXS
                SharedWidgets.AnimatedWeatherIcon {
                  condition: WeatherService.condition
                  color: Colors.accent
                  size: Appearance.fontSizeLarge
                }
                Text {
                  text: WeatherService.temp || "--"
                  color: Colors.text
                  font.pixelSize: Appearance.fontSizeXL
                  font.weight: Font.Bold
                }
              }

              Text {
                text: WeatherService.location || "Local"
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeSmall
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: WeatherService.condition || "Clear"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
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
      spacing: Appearance.spacingS

      SharedWidgets.SectionLabel { label: "WEATHER DETAILS" }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.compactMode ? 140 : 96
        radius: Appearance.radiusMedium
        color: Colors.cardSurface
        border.color: Colors.border
        border.width: 1

        GridLayout {
          anchors.fill: parent
          anchors.margins: Appearance.spacingL
          columns: root.compactMode ? 1 : 2
          columnSpacing: Appearance.spacingL
          rowSpacing: Appearance.spacingM

          RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingL

            Rectangle {
              width: 44; height: 44
              radius: Appearance.radiusSmall
              color: Colors.withAlpha(Colors.accent, 0.1)
              SharedWidgets.AnimatedWeatherIcon {
                anchors.centerIn: parent
                condition: WeatherService.condition
                color: Colors.accent
                size: Appearance.fontSizeDisplay
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              Text {
                text: WeatherService.condition || "Loading weather"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeLarge
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: (WeatherService.location || "Local") + "  •  Feels like " + (WeatherService.feelsLike || "--")
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeSmall
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingM

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0
              Text {
                text: "Humidity: " + (WeatherService.humidity || "--")
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
              }
              Text {
                text: "Wind: " + (WeatherService.windSpeed || "--")
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
              }
            }

            Rectangle {
              implicitWidth: weatherButtonLabel.implicitWidth + 28
              implicitHeight: 32
              radius: Appearance.radiusPill
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
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Bold
              }

              MouseArea {
                id: fullWeatherMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  fullWeatherState.burst(mouse.x, mouse.y);
                  Quickshell.execDetached(SU.ipcCall("Shell", "toggleSurface", "weatherMenu"));
                }
              }
            }
          }
        }
      }
    }
  }
}
