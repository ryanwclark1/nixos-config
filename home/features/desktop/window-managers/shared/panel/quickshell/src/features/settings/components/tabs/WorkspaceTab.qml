import QtQuick
import "../../../../services"
import ".."

Item {
    id: root

    property bool compactMode: false
    property var settingsRoot: null
    property string tabId: ""
    property bool tightSpacing: false

    SettingsTabPage {
        anchors.fill: parent
        iconName: "widgets.svg"
        tabId: root.tabId
        title: "Workspaces"

        SettingsCard {
            description: "Control which workspaces are shown and how they appear."
            iconName: "widgets.svg"
            title: "Workspace Display"

            SettingsToggleRow {
                checked: Config.workspaceShowEmpty
                icon: "󱗝"
                label: "Show Empty Workspaces"

                onToggled: Config.workspaceShowEmpty = !Config.workspaceShowEmpty
            }
            SettingsToggleRow {
                checked: Config.workspaceShowNames
                icon: "󰑭"
                label: "Show Workspace Names"

                onToggled: Config.workspaceShowNames = !Config.workspaceShowNames
            }
            SettingsToggleRow {
                checked: Config.workspaceShowWindowCount
                icon: "󰇄"
                label: "Show Window Count"

                onToggled: Config.workspaceShowWindowCount = !Config.workspaceShowWindowCount
            }
            SettingsModeRow {
                currentValue: Config.workspaceLayout
                label: "Layout"
                options: [
                    {
                        value: "horizontal",
                        label: "Horizontal"
                    },
                    {
                        value: "vertical",
                        label: "Vertical"
                    },
                    {
                        value: "grid",
                        label: "Grid"
                    }
                ]

                onModeSelected: value => Config.workspaceLayout = value
            }
            SettingsModeRow {
                currentValue: Config.workspaceStyle
                label: "Visual Style"
                options: [
                    {
                        value: "pill",
                        label: "Pill"
                    },
                    {
                        value: "strip",
                        label: "Strip"
                    },
                    {
                        value: "dots",
                        label: "Dots"
                    },
                    {
                        value: "icons",
                        label: "Icons"
                    }
                ]

                onModeSelected: value => Config.workspaceStyle = value
            }
            SettingsModeRow {
                currentValue: Config.workspacePillSize
                label: "Pill Size"
                options: [
                    {
                        value: "compact",
                        label: "Compact"
                    },
                    {
                        value: "normal",
                        label: "Normal"
                    },
                    {
                        value: "large",
                        label: "Large"
                    }
                ]

                onModeSelected: value => Config.workspacePillSize = value
            }
        }
        SettingsCard {
            description: "Show application icons inside workspace pills."
            iconName: "󰀻"
            title: "App Icons"

            SettingsToggleRow {
                checked: Config.workspaceShowAppIcons
                icon: "󰀻"
                label: "Show App Icons"

                onToggled: Config.workspaceShowAppIcons = !Config.workspaceShowAppIcons
            }
            SettingsSliderRow {
                label: "Max Icons Per Pill"
                max: 6
                min: 1
                step: 1
                value: Config.workspaceMaxIcons
                visible: Config.workspaceShowAppIcons

                onMoved: v => Config.workspaceMaxIcons = v
            }
        }
        SettingsCard {
            description: "Mouse wheel workspace switching on the workspace strip."
            iconName: "󰍽"
            title: "Scroll Behavior"

            SettingsToggleRow {
                checked: Config.workspaceScrollEnabled
                icon: "󰍽"
                label: "Scroll to Switch"

                onToggled: Config.workspaceScrollEnabled = !Config.workspaceScrollEnabled
            }
            SettingsToggleRow {
                checked: Config.workspaceReverseScroll
                icon: "󰁝"
                label: "Reverse Scroll Direction"
                visible: Config.workspaceScrollEnabled

                onToggled: Config.workspaceReverseScroll = !Config.workspaceReverseScroll
            }
        }
        SettingsCard {
            description: "Notepad integration with workspaces."
            iconName: "󱓧"
            title: "Notepad"

            SettingsToggleRow {
                checked: Config.notepadProjectSync
                icon: "󰓹"
                label: "Auto-Switch Tabs by Workspace"

                onToggled: Config.notepadProjectSync = !Config.notepadProjectSync
            }
        }
        SettingsCard {
            description: "Custom colors for workspace pills. Leave empty to use theme defaults."
            iconName: "color-palette.svg"
            title: "Colors"

            SettingsColorRow {
                currentValue: Config.workspaceActiveColor
                icon: "󰸌"
                label: "Active Color"

                onColorSelected: v => Config.workspaceActiveColor = v
            }
            SettingsColorRow {
                currentValue: Config.workspaceUrgentColor
                icon: "󰀦"
                label: "Urgent Color"

                onColorSelected: v => Config.workspaceUrgentColor = v
            }
        }
        SettingsCard {
            description: "Customize how you interact with workspaces."
            iconName: "arrow-counterclockwise.svg"
            title: "Advanced Interaction"

            SettingsModeRow {
                currentValue: Config.workspaceClickBehavior
                label: "Click Behavior"
                options: [
                    {
                        value: "focus",
                        label: "Focus Workspace"
                    },
                    {
                        value: "last_window",
                        label: "Last Active Window"
                    }
                ]

                onModeSelected: value => Config.workspaceClickBehavior = value
            }
        }
    }
}
