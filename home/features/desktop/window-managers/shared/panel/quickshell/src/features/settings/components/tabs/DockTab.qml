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
    property string validationMessage: ""
    readonly property string conflictMessage: Config.dockConflictMessage()
    readonly property string dockPositionLabel: {
        var position = String(Config.dockPosition || "bottom");
        return position.charAt(0).toUpperCase() + position.slice(1);
    }
    readonly property string dockVisibilitySummary: Config.dockEnabled
        ? (Config.dockAutoHide ? "Auto-hide" : "Always visible")
        : "Disabled"

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Dock"
        iconName: "󰍜"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Dock Overview"
            description: "Visibility, edge placement, and grouping state for the shell dock."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󰍜",
                            label: "Dock",
                            value: root.dockVisibilitySummary
                        },
                        {
                            icon: "󰌷",
                            label: "Edge",
                            value: root.dockPositionLabel
                        },
                        {
                            icon: "options.svg",
                            label: "Grouping",
                            value: Config.dockGroupApps ? "Grouped windows" : "Per-window"
                        },
                        {
                            icon: "󰆼",
                            label: "Icon Size",
                            value: Config.dockIconSize + " px"
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
            title: "Dock Layout & Behavior"
            description: "Position, visibility, grouping, and edge conflict handling for the dock surface."

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
                        icon: "options.svg"
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
                        {
                            value: "top",
                            label: "Top"
                        },
                        {
                            value: "bottom",
                            label: "Bottom"
                        },
                        {
                            value: "left",
                            label: "Left"
                        },
                        {
                            value: "right",
                            label: "Right"
                        }
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
}
