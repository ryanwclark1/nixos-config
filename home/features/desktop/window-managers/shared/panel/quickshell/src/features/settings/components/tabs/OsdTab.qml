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
        title: "On-Screen Display"
        iconName: "󰍡"

        SettingsCard {
            title: "Position"
            iconName: "󰍡"
            description: "Where on-screen indicators appear."

            SettingsModeRow {
                label: "Screen Position"
                currentValue: Config.osdPosition
                options: [
                    {
                        value: "top_left",
                        label: "Top Left"
                    },
                    {
                        value: "top",
                        label: "Top"
                    },
                    {
                        value: "top_right",
                        label: "Top Right"
                    },
                    {
                        value: "left",
                        label: "Left"
                    },
                    {
                        value: "center",
                        label: "Center"
                    },
                    {
                        value: "right",
                        label: "Right"
                    },
                    {
                        value: "bottom_left",
                        label: "Bottom Left"
                    },
                    {
                        value: "bottom",
                        label: "Bottom"
                    },
                    {
                        value: "bottom_right",
                        label: "Bottom Right"
                    }
                ]
                onModeSelected: v => Config.osdPosition = v
            }
        }

        SettingsCard {
            title: "Style"
            iconName: "󰏘"
            description: "Shape and behavior for OSD presentation."

            SettingsModeRow {
                label: "Display Style"
                currentValue: Config.osdStyle
                options: [
                    {
                        value: "circular",
                        label: "Circular"
                    },
                    {
                        value: "pill",
                        label: "Pill"
                    }
                ]
                onModeSelected: v => Config.osdStyle = v
            }

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Volume Overdrive"
                    icon: "󰝝"
                    configKey: "osdOverdrive"
                }
            }
        }

        SettingsCard {
            title: "Timing & Size"
            iconName: "󰔛"
            description: "Display duration and physical OSD scale."

            SettingsSliderRow {
                label: "OSD Duration"
                min: 1000
                max: 5000
                step: 250
                value: Config.osdDuration
                unit: "ms"
                onMoved: v => Config.osdDuration = v
            }

            SettingsSliderRow {
                label: "OSD Size"
                min: 140
                max: 260
                value: Config.osdSize
                onMoved: v => Config.osdSize = v
            }
        }
    }
}
