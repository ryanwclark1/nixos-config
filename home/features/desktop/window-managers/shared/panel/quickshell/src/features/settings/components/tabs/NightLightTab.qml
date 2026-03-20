import QtQuick
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Night Light"
        iconName: "weather-moon.svg"

        SettingsCard {
            title: "Night Light"
            iconName: "weather-moon.svg"
            description: "Reduce blue light to ease eye strain at night."

            SettingsToggleRow {
                label: "Enable Night Light"
                icon: "weather-moon.svg"
                checked: Config.nightLightEnabled
                enabledText: "Night light is active"
                disabledText: "Night light is off"
                onToggled: NightLightService.toggle()
            }

            SettingsSliderRow {
                label: "Color Temperature"
                min: 2500
                max: 6500
                step: 100
                value: Config.nightLightTemperature
                onMoved: v => Config.nightLightTemperature = v
            }

            SettingsInfoCallout {
                iconName: "info.svg"
                title: "Color temperature"
                body: "Lower values (2500 K) are warmer and more orange. Higher values (6500 K) are cooler and more blue."
            }
        }

        SettingsCard {
            title: "Auto Schedule"
            iconName: "󰔠"
            description: "Automatically enable night light on a schedule."

            SettingsToggleRow {
                label: "Auto Schedule"
                icon: "clock.svg"
                checked: Config.nightLightAutoSchedule
                enabledText: "Night light follows the configured schedule"
                disabledText: "Schedule is disabled"
                onToggled: Config.nightLightAutoSchedule = !Config.nightLightAutoSchedule
            }

            SettingsModeRow {
                visible: Config.nightLightAutoSchedule
                label: "Schedule Mode"
                currentValue: Config.nightLightScheduleMode
                options: [
                    {
                        value: "time",
                        label: "Fixed Time"
                    },
                    {
                        value: "sunrise_sunset",
                        label: "Sunrise/Sunset"
                    }
                ]
                onModeSelected: v => Config.nightLightScheduleMode = v
            }
        }

        SettingsCard {
            visible: Config.nightLightAutoSchedule && Config.nightLightScheduleMode === "time"
            title: "Fixed Time Schedule"
            iconName: "󰥔"
            description: "Set specific times to enable and disable night light."

            SettingsSliderRow {
                label: "Start Hour"
                min: 0
                max: 23
                step: 1
                value: Config.nightLightStartHour
                onMoved: v => Config.nightLightStartHour = v
            }

            SettingsSliderRow {
                label: "Start Minute"
                min: 0
                max: 55
                step: 5
                value: Config.nightLightStartMinute
                onMoved: v => Config.nightLightStartMinute = v
            }

            SettingsSliderRow {
                label: "End Hour"
                min: 0
                max: 23
                step: 1
                value: Config.nightLightEndHour
                onMoved: v => Config.nightLightEndHour = v
            }

            SettingsSliderRow {
                label: "End Minute"
                min: 0
                max: 55
                step: 5
                value: Config.nightLightEndMinute
                onMoved: v => Config.nightLightEndMinute = v
            }
        }

        SettingsCard {
            visible: Config.nightLightAutoSchedule && Config.nightLightScheduleMode === "sunrise_sunset"
            title: "Location"
            iconName: "󰍎"
            description: "Coordinates for sunrise/sunset calculation."

            SettingsTextInputRow {
                label: "Latitude"
                leadingIcon: "compass.svg"
                text: Config.nightLightLatitude
                placeholderText: "e.g. 40.7128"
                onSubmitted: v => Config.nightLightLatitude = v.trim()
            }

            SettingsTextInputRow {
                label: "Longitude"
                leadingIcon: "compass.svg"
                text: Config.nightLightLongitude
                placeholderText: "e.g. -74.0060"
                onSubmitted: v => Config.nightLightLongitude = v.trim()
            }
        }
    }
}
