import QtQuick
import QtQuick.Layouts
import "../../../services"
import ".."

Item {
  id: root
  property var settingsRoot: null
  property string tabId: ""

  SettingsTabPage {
    anchors.fill: parent
    tabId: root.tabId
    title: "Time & Weather"
    iconName: "󰔛"

    SettingsCard {
      title: "Time Format"
      iconName: "󰔛"

      SettingsFieldGrid {
        SettingsToggleRow { label: "24-Hour Clock"; icon: "󰅐"; configKey: "timeUse24Hour" }
        SettingsToggleRow { label: "Show Seconds"; icon: "󰔟"; configKey: "timeShowSeconds" }
        SettingsToggleRow { label: "Show Date In Bar"; icon: "󰃭"; configKey: "timeShowBarDate" }
      }

      SettingsModeRow {
        label: "Bar Date Style"
        currentValue: Config.timeBarDateStyle
        options: [
          { value: "weekday_short", label: "Weekday" },
          { value: "month_day", label: "Month + Day" },
          { value: "weekday_month_day", label: "Weekday + Date" }
        ]
        onModeSelected: (modeValue) => Config.timeBarDateStyle = modeValue
      }
    }

    SettingsCard {
      title: "Weather"
      iconName: "󰖔"

      SettingsModeRow {
        label: "Units"
        currentValue: Config.weatherUnits
        options: [
          { value: "metric", label: "Metric (C)" },
          { value: "imperial", label: "Imperial (F)" }
        ]
        onModeSelected: (modeValue) => Config.weatherUnits = modeValue
      }

      SettingsModeRow {
        label: "Location Priority"
        currentValue: Config.weatherLocationPriority
        options: [
          { value: "latlon_city_auto", label: "LatLon > City > Auto" },
          { value: "city_auto_latlon", label: "City > Auto > LatLon" },
          { value: "auto_city_latlon", label: "Auto > City > LatLon" }
        ]
        onModeSelected: (modeValue) => Config.weatherLocationPriority = modeValue
      }

      SettingsToggleRow {
        label: "Auto Location"
        icon: "󰍹"
        configKey: "weatherAutoLocation"
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingM

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingXS

          Text {
            text: "City"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Medium
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Colors.radiusSmall
            color: Colors.bgWidget
            border.color: cityInput.activeFocus ? Colors.primary : Colors.border
            border.width: 1

            TextInput {
              id: cityInput
              anchors.fill: parent
              anchors.leftMargin: Colors.spacingM
              anchors.rightMargin: Colors.spacingM
              verticalAlignment: Text.AlignVCenter
              color: Colors.text
              font.pixelSize: Colors.fontSizeSmall
              text: Config.weatherCityQuery
              onEditingFinished: {
                if (Config.weatherCityQuery !== text)
                  Config.weatherCityQuery = text;
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingM

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            Text {
              text: "Latitude"
              color: Colors.textSecondary
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.Medium
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 36
              radius: Colors.radiusSmall
              color: Colors.bgWidget
              border.color: latitudeInput.activeFocus ? Colors.primary : Colors.border
              border.width: 1

              TextInput {
                id: latitudeInput
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                verticalAlignment: Text.AlignVCenter
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                text: Config.weatherLatitude
                onEditingFinished: {
                  if (Config.weatherLatitude !== text)
                    Config.weatherLatitude = text;
                }
              }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            Text {
              text: "Longitude"
              color: Colors.textSecondary
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.Medium
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 36
              radius: Colors.radiusSmall
              color: Colors.bgWidget
              border.color: longitudeInput.activeFocus ? Colors.primary : Colors.border
              border.width: 1

              TextInput {
                id: longitudeInput
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                verticalAlignment: Text.AlignVCenter
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                text: Config.weatherLongitude
                onEditingFinished: {
                  if (Config.weatherLongitude !== text)
                    Config.weatherLongitude = text;
                }
              }
            }
          }
        }

        Text {
          text: "Priority and source settings apply to both the standalone Weather menu and the Date & Time dropdown."
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
      }
    }
  }
}
