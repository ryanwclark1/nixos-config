import QtQuick
import QtQuick.Layouts
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property string validationMessage: ""

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Dock"
        iconName: "󰍜"

        SettingsInfoCallout {
            visible: root.validationMessage !== "" || Config.dockHasConflict()
            iconName: "󰀪"
            title: root.validationMessage !== "" ? "Dock conflict" : "Reserved edge in use"
            body: root.validationMessage !== "" ? root.validationMessage : "An enabled bar already occupies the dock edge on at least one display. The dock will stay hidden only on those conflicting displays."
        }

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
            description: "Dock position and icon sizing. The dock cannot share an edge with any enabled bar."

            SettingsModeRow {
                label: "Dock Position"
                currentValue: Config.dockPosition
                options: [
                    { value: "top", label: "Top" },
                    { value: "bottom", label: "Bottom" },
                    { value: "left", label: "Left" },
                    { value: "right", label: "Right" }
                ]
                onModeSelected: value => {
                    root.validationMessage = "";
                    if (!Config.setDockPosition(value))
                        root.validationMessage = "The " + value + " edge is already occupied by an enabled bar.";
                }
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
