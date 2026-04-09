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
        iconName: "apps.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Dock Overview"
            description: "Visibility, edge placement, and grouping state for the shell dock."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingM

                Repeater {
                    model: [
                        {
                            icon: "apps.svg",
                            label: "Dock",
                            value: root.dockVisibilitySummary
                        },
                        {
                            icon: "pin.svg",
                            label: "Edge",
                            value: root.dockPositionLabel
                        },
                        {
                            icon: "options.svg",
                            label: "Grouping",
                            value: Config.dockGroupApps ? "Grouped windows" : "Per-window"
                        },
                        {
                            icon: "desktop.svg",
                            label: "Icon Size",
                            value: Config.dockIconSize + " px"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(140, Math.floor((parent.width - Appearance.spacingM * 3) / 4))
                        implicitHeight: metricColumn.implicitHeight + Appearance.spacingM * 2
                        radius: Appearance.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            spacing: Appearance.spacingXS

                            SettingsMetricIcon { icon: modelData.icon }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Appearance.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
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
                iconName: "warning.svg"
                title: root.validationMessage !== "" ? "Dock warning" : "Shared edge"
                body: root.validationMessage !== "" ? root.validationMessage : root.conflictMessage
            }

            SettingsCard {
                title: "Behavior"
                iconName: "apps.svg"
                description: "Dock visibility and grouping behavior."

                SettingsFieldGrid {
                    maximumColumns: root.compactMode ? 1 : 2

                    SettingsToggleRow {
                        label: "Dock Enabled"
                        icon: "apps.svg"
                        configKey: "dockEnabled"
                    }
                    SettingsToggleRow {
                        label: "Auto Hide"
                        icon: "re-order-dots-vertical.svg"
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
                iconName: "options.svg"
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
