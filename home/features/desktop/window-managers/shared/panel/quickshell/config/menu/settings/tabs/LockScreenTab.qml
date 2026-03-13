import QtQuick
import QtQuick.Layouts
import "../../../services"
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
        title: "Lock Screen"
        iconName: "󰌾"

        SettingsCard {
            title: "Features"
            iconName: "󰌾"
            description: "Lock screen modules and pre-lock countdown timing."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Compact Mode"
                    icon: "󰘖"
                    configKey: "lockScreenCompact"
                }
                SettingsToggleRow {
                    label: "Media Controls"
                    icon: "󰝚"
                    configKey: "lockScreenMediaControls"
                }
                SettingsToggleRow {
                    label: "Weather"
                    icon: "󰖙"
                    configKey: "lockScreenWeather"
                }
                SettingsToggleRow {
                    label: "Session Buttons"
                    icon: "󰐥"
                    configKey: "lockScreenSessionButtons"
                }
            }

            SettingsSliderRow {
                label: "Lock Countdown"
                min: 1000
                max: 10000
                step: 500
                value: Config.lockScreenCountdown
                unit: "ms"
                onMoved: v => Config.lockScreenCountdown = v
            }
        }
    }
}
