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
        title: "Power & Sleep"
        iconName: "󰌪"

        SettingsCard {
            title: "Power Menu"
            iconName: "󰌪"
            description: "Configure countdown timing for destructive power actions."

            SettingsSliderRow {
                label: "Powermenu Countdown"
                min: 1000
                max: 10000
                step: 500
                value: Config.powermenuCountdown
                unit: "ms"
                onMoved: v => Config.powermenuCountdown = v
            }
        }

        SettingsCard {
            title: "Display"
            iconName: "󰍹"
            description: "Visual helpers and idle inhibition behavior."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Screen Borders"
                    icon: "󰩪"
                    configKey: "showScreenBorders"
                }
                SettingsToggleRow {
                    label: "Idle Inhibitor"
                    icon: "󰈈"
                    configKey: "idleInhibitEnabled"
                }
            }
        }
    }
}
