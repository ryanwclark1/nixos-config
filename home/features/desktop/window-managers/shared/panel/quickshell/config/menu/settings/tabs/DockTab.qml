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
        title: "Dock"
        iconName: "󰍜"

        SettingsCard {
            title: "Behavior"
            iconName: "󰍜"
            description: "Dock visibility and grouping behavior."

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "Dock Enabled"
                    icon: "󰍜"
                    configKey: "dockEnabled"
                }
                SettingsToggleRow {
                    label: "Auto Hide"
                    icon: "󰘊"
                    configKey: "dockAutoHide"
                }
                SettingsToggleRow {
                    label: "Group Windows"
                    icon: "󰖲"
                    configKey: "dockGroupApps"
                }
            }
        }

        SettingsCard {
            title: "Layout"
            iconName: "󰕰"
            description: "Dock position and icon sizing."

            SettingsModeRow {
                label: "Dock Position"
                currentValue: Config.dockPosition
                options: [
                    {
                        value: "top",
                        label: "Top"
                    },
                    {
                        value: "bottom",
                        label: "Bottom"
                    }
                ]
                onModeSelected: v => Config.dockPosition = v
            }

            SettingsSliderRow {
                label: "Icon Size"
                min: 24
                max: 56
                value: Config.dockIconSize
                onMoved: v => Config.dockIconSize = v
            }
        }
    }
}
