import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../system/sections"
import "../widgets" as SharedWidgets

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
    columnSpacing: Colors.spacingM

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 188 : 122
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      GridLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        columns: root.compactMode ? 1 : 2
        columnSpacing: Colors.spacingM
        rowSpacing: Colors.spacingM

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingXS

          Text {
            text: Qt.formatDateTime(
              clock.date,
              Config.timeUse24Hour
                ? (Config.timeShowSeconds ? "HH:mm:ss" : "HH:mm")
                : (Config.timeShowSeconds ? "hh:mm:ss AP" : "hh:mm AP")
            )
            color: Colors.text
            font.pixelSize: root.compactMode ? 44 : 56
            font.weight: Font.Bold
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
          Layout.preferredWidth: root.compactMode ? -1 : 152
          spacing: Colors.spacingXS

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 84
            radius: Colors.radiusMedium
            color: Colors.withAlpha(Colors.primary, 0.18)
            border.color: Colors.withAlpha(Colors.primary, 0.42)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Colors.spacingS
              spacing: Colors.spacingXXS

              Text {
                text: Colors.weatherIcon(WeatherService.condition)
                color: Colors.accent
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeLarge
              }

              Text {
                text: WeatherService.temp || "--"
                color: Colors.text
                font.pixelSize: Colors.fontSizeHuge
                font.weight: Font.Bold
              }

              Text {
                text: WeatherService.location || "Local"
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeMedium
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
      Layout.preferredHeight: 280
    }

    SharedWidgets.SectionLabel { label: "WEATHER" }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 122 : 88
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      GridLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        columns: root.compactMode ? 1 : 2
        columnSpacing: Colors.spacingM
        rowSpacing: Colors.spacingS

        RowLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingM

          Text {
            text: Colors.weatherIcon(WeatherService.condition)
            color: Colors.accent
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeDisplay
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXXS

            Text {
              text: WeatherService.condition || "Loading weather"
              color: Colors.text
              font.pixelSize: Colors.fontSizeXL
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: (WeatherService.location || "Local") + "  •  Feels like " + (WeatherService.feelsLike || "--") + "  •  Humidity " + (WeatherService.humidity || "--")
              color: Colors.textSecondary
              font.pixelSize: Colors.fontSizeMedium
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }
        }

        Rectangle {
          implicitWidth: weatherButtonLabel.implicitWidth + 24
          implicitHeight: 34
          radius: Colors.radiusSmall
          color: Colors.highlight
          border.color: Colors.border
          border.width: 1
          Layout.alignment: root.compactMode ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)

          SharedWidgets.StateLayer {
            id: fullWeatherState
            hovered: fullWeatherMouse.containsMouse
            pressed: fullWeatherMouse.pressed
          }

          Text {
            id: weatherButtonLabel
            anchors.centerIn: parent
            text: "Weather"
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
          }

          MouseArea {
            id: fullWeatherMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
              fullWeatherState.burst(mouse.x, mouse.y);
              Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleWeatherMenu"]);
            }
          }
        }
      }
    }
  }
}
