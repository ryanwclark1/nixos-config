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
        title: "Workspaces"
        iconName: "󰕮"

        SettingsCard {
            title: "Workspace Display"
            iconName: "󰕮"
            description: "Control which workspaces are shown and how they appear."

            SettingsToggleRow {
                label: "Show Empty Workspaces"
                icon: "󱗝"
                checked: Config.workspaceShowEmpty
                onToggled: Config.workspaceShowEmpty = !Config.workspaceShowEmpty
            }

            SettingsToggleRow {
                label: "Show Workspace Names"
                icon: "󰑭"
                checked: Config.workspaceShowNames
                onToggled: Config.workspaceShowNames = !Config.workspaceShowNames
            }

            SettingsModeRow {
                label: "Pill Size"
                currentValue: Config.workspacePillSize
                options: [
                    { value: "compact", label: "Compact" },
                    { value: "normal",  label: "Normal"  },
                    { value: "large",   label: "Large"   }
                ]
                onModeSelected: value => Config.workspacePillSize = value
            }
        }

        SettingsCard {
            title: "App Icons"
            iconName: "󰀻"
            description: "Show application icons inside workspace pills."

            SettingsToggleRow {
                label: "Show App Icons"
                icon: "󰀻"
                checked: Config.workspaceShowAppIcons
                onToggled: Config.workspaceShowAppIcons = !Config.workspaceShowAppIcons
            }

            SettingsSliderRow {
                visible: Config.workspaceShowAppIcons
                label: "Max Icons Per Pill"
                min: 1
                max: 6
                value: Config.workspaceMaxIcons
                step: 1
                onMoved: v => Config.workspaceMaxIcons = v
            }
        }

        SettingsCard {
            title: "Scroll Behavior"
            iconName: "󰍽"
            description: "Mouse wheel workspace switching on the workspace strip."

            SettingsToggleRow {
                label: "Scroll to Switch"
                icon: "󰍽"
                checked: Config.workspaceScrollEnabled
                onToggled: Config.workspaceScrollEnabled = !Config.workspaceScrollEnabled
            }

            SettingsToggleRow {
                visible: Config.workspaceScrollEnabled
                label: "Reverse Scroll Direction"
                icon: "󰁝"
                checked: Config.workspaceReverseScroll
                onToggled: Config.workspaceReverseScroll = !Config.workspaceReverseScroll
            }
        }

        SettingsCard {
            title: "Notepad"
            iconName: "󱓧"
            description: "Notepad integration with workspaces."

            SettingsToggleRow {
                label: "Auto-Switch Tabs by Workspace"
                icon: "󰓹"
                checked: Config.notepadProjectSync
                onToggled: Config.notepadProjectSync = !Config.notepadProjectSync
            }
        }

        SettingsCard {
            title: "Colors"
            iconName: "󰏘"
            description: "Custom colors for workspace pills. Leave empty to use theme defaults."

            SettingsColorRow {
                label: "Active Color"
                icon: "󰸌"
                currentValue: Config.workspaceActiveColor
                onColorSelected: v => Config.workspaceActiveColor = v
            }

            SettingsColorRow {
                label: "Urgent Color"
                icon: "󰀦"
                currentValue: Config.workspaceUrgentColor
                onColorSelected: v => Config.workspaceUrgentColor = v
            }
        }
    }
}
