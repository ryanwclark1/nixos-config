import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Plugins"
        iconName: "󰏗"

        SettingsCard {
            title: "Plugin Manager"
            iconName: "󰏗"
            description: "Discover and toggle installed bar and desktop widget plugins."

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: PluginService.plugins.length + " plugin" + (PluginService.plugins.length !== 1 ? "s" : "") + " found"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    Text {
                        text: PluginService.plugins.filter(function (p) {
                            return p.enabled;
                        }).length + " enabled"
                        color: Colors.fgSecondary
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }

                SettingsActionButton {
                    label: "Scan"
                    iconName: "󰑐"
                    compact: true
                    onClicked: PluginService.scanPlugins()
                }
            }

            ColumnLayout {
                visible: PluginService.plugins.length === 0
                Layout.fillWidth: true
                Layout.topMargin: 24
                spacing: Colors.spacingM

                Text {
                    text: "󰏗"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeHuge
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "No plugins found"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeLarge
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Add a folder with manifest.json to get started"
                    color: Colors.fgDim
                    font.pixelSize: Colors.fontSizeSmall
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Repeater {
                model: PluginService.plugins

                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: pluginCardRow.implicitHeight + 28
                    radius: Colors.radiusMedium
                    color: Colors.bgWidget
                    border.color: modelData.enabled ? Colors.primary : Colors.border
                    border.width: 1
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 180
                        }
                    }

                    RowLayout {
                        id: pluginCardRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: Colors.spacingM
                        }
                        spacing: Colors.spacingM

                        Rectangle {
                            width: 38
                            height: 38
                            radius: Colors.radiusSmall
                            color: modelData.enabled ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12) : Colors.withAlpha(Colors.text, 0.06)
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.type === "bar-widget" ? "󰖯" : "󰖲"
                                color: modelData.enabled ? Colors.primary : Colors.fgDim
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeXL
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                spacing: Colors.spacingS

                                Text {
                                    text: modelData.name
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    implicitWidth: verLabel.implicitWidth + 10
                                    height: 18
                                    radius: height / 2
                                    color: Colors.withAlpha(Colors.text, 0.08)
                                    Text {
                                        id: verLabel
                                        anchors.centerIn: parent
                                        text: "v" + modelData.version
                                        color: Colors.fgSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        font.family: Colors.fontMono
                                    }
                                }

                                Rectangle {
                                    implicitWidth: typeLabel.implicitWidth + 10
                                    height: 18
                                    radius: height / 2
                                    color: modelData.type === "bar-widget" ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14) : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14)
                                    Text {
                                        id: typeLabel
                                        anchors.centerIn: parent
                                        text: modelData.type === "bar-widget" ? "Bar" : "Desktop"
                                        color: modelData.type === "bar-widget" ? Colors.accent : Colors.primary
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Text {
                                visible: modelData.description.length > 0
                                text: modelData.description
                                color: Colors.fgSecondary
                                font.pixelSize: Colors.fontSizeSmall
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "by " + modelData.author
                                color: Colors.fgDim
                                font.pixelSize: Colors.fontSizeXS
                            }
                        }

                        SharedWidgets.DankToggle {
                            checked: modelData.enabled
                            Layout.alignment: Qt.AlignVCenter
                            onToggled: {
                                if (modelData.enabled)
                                    PluginService.disablePlugin(modelData.id);
                                else
                                    PluginService.enablePlugin(modelData.id);
                            }
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Installation"
            iconName: "󰋗"
            description: "Plugin format and discovery location."

            Text {
                text: "Plugin directory:  ~/.config/quickshell/plugins/"
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeSmall
                font.family: Colors.fontMono
                Layout.fillWidth: true
                wrapMode: Text.WrapAnywhere
            }

            Text {
                text: "Each plugin is a folder containing a manifest.json and a QML file.\n" + "manifest.json fields:  id, name, description, author, version, type (\"bar-widget\" or \"desktop-widget\"), main"
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeSmall
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
