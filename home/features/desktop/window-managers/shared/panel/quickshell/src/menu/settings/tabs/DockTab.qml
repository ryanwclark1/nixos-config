import QtQuick
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    property string validationMessage: ""
    readonly property string conflictMessage: Config.dockConflictMessage()

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Dock"
        iconName: "󰍜"

        SettingsInfoCallout {
            visible: root.validationMessage !== "" || root.conflictMessage !== ""
            iconName: "󰀪"
            title: root.validationMessage !== "" ? "Dock warning" : "Shared edge"
            body: root.validationMessage !== "" ? root.validationMessage : root.conflictMessage
        }

        SettingsCard {
            title: "Behavior"
            iconName: "󰍜"
            description: "Dock visibility and grouping behavior."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

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
            description: "Dock position and icon sizing. If a bar uses the same edge on a display, the dock hides only on that display."

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
                        root.validationMessage = "Invalid dock edge: " + value + ".";
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
