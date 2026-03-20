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

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Desktop Widgets"
        iconName: "options.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Desktop Widget Overview"
            description: "Widget visibility, layout assistance, and edit-mode access for the desktop surface."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󰖲",
                            label: "Widgets",
                            value: Config.desktopWidgetsEnabled ? "Enabled" : "Disabled"
                        },
                        {
                            icon: "󰕰",
                            label: "Grid Snap",
                            value: Config.desktopWidgetsGridSnap ? "Enabled" : "Freeform"
                        },
                        {
                            icon: "󰏫",
                            label: "Edit Mode",
                            value: "Launch from settings"
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
            title: "Workspace Management"
            description: "Control widget layout assistance and jump directly into the desktop editing surface."

            SettingsCard {
                title: "Widgets"
                iconName: "options.svg"
                description: "Desktop widget visibility, snapping, and edit mode."

                SettingsFieldGrid {
                    maximumColumns: root.compactMode ? 1 : 2

                    SettingsToggleRow {
                        label: "Desktop Widgets"
                        icon: "󰖲"
                        configKey: "desktopWidgetsEnabled"
                    }
                    SettingsToggleRow {
                        label: "Grid Snap"
                        icon: "󰕰"
                        configKey: "desktopWidgetsGridSnap"
                    }
                }

                SettingsActionButton {
                    Layout.fillWidth: true
                    emphasized: true
                    iconName: "edit.svg"
                    label: "Edit Widgets"
                    onClicked: {
                        DesktopWidgetRegistry.editMode = true;
                        if (root.settingsRoot)
                            root.settingsRoot.close();
                    }
                }
            }
        }
    }
}
