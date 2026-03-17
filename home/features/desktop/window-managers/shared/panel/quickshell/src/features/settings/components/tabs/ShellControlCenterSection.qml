import QtQuick
import QtQuick.Layouts
import Quickshell
import "ShellCoreHelpers.js" as Helpers
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    required property bool compactMode
    required property var settingsRoot

    implicitHeight: card.implicitHeight
    implicitWidth: card.implicitWidth

    SettingsCard {
        id: card
        anchors.fill: parent
        title: "Control Center"
        iconName: "󰖲"
        description: "Visibility and width of control center modules."

        SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2

            SettingsToggleRow {
                label: "Quick Links"
                icon: "󰖩"
                configKey: "controlCenterShowQuickLinks"
            }
            SettingsToggleRow {
                label: "Media Widget"
                icon: "󰝚"
                configKey: "controlCenterShowMediaWidget"
            }
        }

        SettingsSliderRow {
            label: "Control Center Width"
            icon: "󰖲"
            min: Config.controlCenterWidthMin
            max: Config.controlCenterWidthMax
            value: Config.controlCenterWidth
            onMoved: v => Config.controlCenterWidth = v
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "Quick Toggles"
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
            }

            Text {
                text: "Control toggle visibility and order in the Control Center grid."
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: Helpers.orderedControlCenterToggles(ControlCenterRegistry)

                delegate: SettingsListRow {
                    required property var modelData
                    readonly property bool hidden: Array.isArray(Config.controlCenterHiddenToggles) && Config.controlCenterHiddenToggles.indexOf(modelData.id) !== -1
                    readonly property int rowIndex: Helpers.orderedControlCenterToggles(ControlCenterRegistry).findIndex(function (item) {
                        return item.id === modelData.id;
                    })
                    minimumHeight: root.compactMode ? 72 : 60
                    active: !hidden

                    Text {
                        text: modelData.icon || "󰖲"
                        color: hidden ? Colors.textDisabled : Colors.primary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeLarge
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXXS

                        Text {
                            text: modelData.label || modelData.id
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: hidden ? "Hidden" : "Visible"
                            color: hidden ? Colors.textDisabled : Colors.success
                            font.pixelSize: Colors.fontSizeXS
                        }
                    }

                    RowLayout {
                        spacing: Colors.spacingS

                        SettingsActionButton {
                            compact: true
                            iconName: "󰁍"
                            label: "Up"
                            enabled: rowIndex > 0
                            onClicked: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterToggleOrder", modelData.id, -1)
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰁔"
                            label: "Down"
                            enabled: rowIndex >= 0 && rowIndex < Helpers.orderedControlCenterToggles(ControlCenterRegistry).length - 1
                            onClicked: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterToggleOrder", modelData.id, 1)
                        }

                        SharedWidgets.ToggleSwitch {
                            checked: !hidden
                            onToggled: Helpers.toggleHiddenListValue(Config, "controlCenterHiddenToggles", modelData.id)
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS
            visible: PluginService.controlCenterPlugins.length > 0

            Text {
                text: "Plugin Widgets"
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
            }

            Text {
                text: "Manage third-party widgets exposed inside the Control Center."
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: Helpers.orderedControlCenterPlugins(PluginService)

                delegate: SettingsListRow {
                    required property var modelData
                    readonly property bool hidden: Array.isArray(Config.controlCenterHiddenPlugins) && Config.controlCenterHiddenPlugins.indexOf(modelData.id) !== -1
                    readonly property int rowIndex: Helpers.orderedControlCenterPlugins(PluginService).findIndex(function (item) {
                        return item.id === modelData.id;
                    })
                    minimumHeight: root.compactMode ? 80 : 64
                    active: !hidden

                    Rectangle {
                        width: root.compactMode ? 30 : 34
                        height: width
                        radius: Colors.radiusSmall
                        color: hidden ? Colors.withAlpha(Colors.text, 0.06) : Colors.withAlpha(Colors.primary, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "󰏗"
                            color: hidden ? Colors.textDisabled : Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeMedium
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXXS

                        Text {
                            text: modelData.name || modelData.id
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: hidden ? "Hidden" : "Visible"
                            color: hidden ? Colors.textDisabled : Colors.success
                            font.pixelSize: Colors.fontSizeXS
                        }
                    }

                    RowLayout {
                        spacing: Colors.spacingS

                        SettingsActionButton {
                            compact: true
                            iconName: "󰁍"
                            label: "Up"
                            enabled: rowIndex > 0
                            onClicked: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterPluginOrder", modelData.id, -1)
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰁔"
                            label: "Down"
                            enabled: rowIndex >= 0 && rowIndex < Helpers.orderedControlCenterPlugins(PluginService).length - 1
                            onClicked: Helpers.moveOrderedValue(Config, ControlCenterRegistry, PluginService, "controlCenterPluginOrder", modelData.id, 1)
                        }

                        SharedWidgets.ToggleSwitch {
                            checked: !hidden
                            onToggled: Helpers.toggleHiddenListValue(Config, "controlCenterHiddenPlugins", modelData.id)
                        }
                    }
                }
            }
        }
    }
}
