import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    readonly property string _positionSummary: {
        switch (Config.osdPosition) {
            case "top_left": return "Top Left";
            case "top": return "Top";
            case "top_right": return "Top Right";
            case "left": return "Left";
            case "center": return "Center";
            case "right": return "Right";
            case "bottom_left": return "Bottom Left";
            case "bottom": return "Bottom";
            case "bottom_right": return "Bottom Right";
            default: return "Center";
        }
    }
    readonly property string _styleSummary: Config.osdStyle === "pill" ? "Pill" : "Circular"

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "On-Screen Display"
        iconName: "󰍡"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "OSD Overview"
            description: "Placement, presentation style, and timing for shell overlays like volume and brightness indicators."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󰍡",
                            label: "Position",
                            value: root._positionSummary
                        },
                        {
                            icon: "󰏘",
                            label: "Style",
                            value: root._styleSummary
                        },
                        {
                            icon: "󰔛",
                            label: "Duration",
                            value: Config.osdDuration + " ms"
                        },
                        {
                            icon: "󰆼",
                            label: "Size",
                            value: String(Config.osdSize)
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(180, Math.floor((parent.width - Colors.spacingM * 2) / 3))
                        implicitHeight: metricColumn.implicitHeight + Colors.spacingM * 2
                        radius: Colors.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            SettingsMetricIcon { icon: modelData.icon }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Colors.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Placement & Style"
            description: "Choose where OSD surfaces appear and what visual treatment they use."

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
        }

        SettingsSectionGroup {
            title: "Timing & Size"
            description: "Tune how large the OSD is and how long it remains visible."

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
}
