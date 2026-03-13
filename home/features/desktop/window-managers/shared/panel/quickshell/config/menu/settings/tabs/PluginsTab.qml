import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    function pluginErrorEntries() {
        var map = PluginService.pluginErrors || ({});
        var entries = [];
        for (var key in map) {
            entries.push({
                id: key,
                error: String(map[key] || "")
            });
        }
        entries.sort(function(a, b) { return String(a.id).localeCompare(String(b.id)); });
        return entries;
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Plugins"
        iconName: "󰏗"

        SettingsCard {
            title: "Plugin Manager"
            iconName: "󰏗"
            description: "Discover and toggle installed bar and desktop widget plugins."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                ColumnLayout {
                    spacing: 2
                    width: root.compactMode ? parent.width : Math.max(0, parent.width - scanPluginsButton.implicitWidth - Colors.spacingM)

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

                    Text {
                        visible: Object.keys(PluginService.pluginErrors || ({ })).length > 0
                        text: Object.keys(PluginService.pluginErrors || ({ })).length + " invalid plugin manifest" + (Object.keys(PluginService.pluginErrors || ({ })).length !== 1 ? "s" : "")
                        color: Colors.warning
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }

                SettingsActionButton {
                    id: scanPluginsButton
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

                delegate: SettingsListRow {
                    active: modelData.enabled
                    radius: Colors.radiusMedium
                    contentInset: Colors.spacingM
                    rowSpacing: root.compactMode ? Colors.spacingS : Colors.spacingM
                    minimumHeight: root.compactMode ? 92 : 66

                    Rectangle {
                        width: root.compactMode ? 32 : 38
                        height: root.compactMode ? 32 : 38
                        radius: Colors.radiusSmall
                        color: modelData.enabled ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12) : Colors.withAlpha(Colors.text, 0.06)
                        Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: modelData.type === "bar-widget"
                                  ? "󰖯"
                                  : modelData.type === "desktop-widget"
                                    ? "󰖲"
                                    : modelData.type === "launcher-provider"
                                      ? "󰀻"
                                      : modelData.type === "daemon"
                                        ? "󰒓"
                                        : "󰏗"
                            color: modelData.enabled ? Colors.primary : Colors.fgDim
                            font.family: Colors.fontMono
                            font.pixelSize: root.compactMode ? Colors.fontSizeLarge : Colors.fontSizeXL
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

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Colors.spacingS

                            Text {
                                text: modelData.name
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.DemiBold
                                width: parent.width
                                elide: Text.ElideRight
                                wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Colors.spacingS

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
                                color: modelData.type === "bar-widget"
                                       ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                                       : modelData.type === "desktop-widget"
                                         ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14)
                                         : Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.14)
                                Text {
                                    id: typeLabel
                                    anchors.centerIn: parent
                                    text: modelData.type === "bar-widget"
                                          ? "Bar"
                                          : modelData.type === "desktop-widget"
                                            ? "Desktop"
                                            : modelData.type === "launcher-provider"
                                              ? "Launcher"
                                              : modelData.type === "daemon"
                                                ? "Daemon"
                                                : "Multi"
                                    color: modelData.type === "bar-widget"
                                           ? Colors.accent
                                           : modelData.type === "desktop-widget"
                                             ? Colors.primary
                                             : Colors.warning
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
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            text: "by " + modelData.author
                            color: Colors.fgDim
                            font.pixelSize: Colors.fontSizeXS
                        }
                    }

                    SharedWidgets.DankToggle {
                        checked: modelData.enabled
                        Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                        onToggled: {
                            if (modelData.enabled)
                                PluginService.disablePlugin(modelData.id);
                            else
                                PluginService.enablePlugin(modelData.id);
                        }
                    }
                }
            }

            ColumnLayout {
                visible: root.pluginErrorEntries().length > 0
                Layout.fillWidth: true
                spacing: Colors.spacingS
                Layout.topMargin: Colors.spacingM

                Text {
                    text: "Invalid plugin manifests"
                    color: Colors.warning
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: root.pluginErrorEntries()

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        radius: Colors.radiusSmall
                        color: Colors.withAlpha(Colors.warning, 0.10)
                        border.color: Colors.withAlpha(Colors.warning, 0.35)
                        border.width: 1
                        implicitHeight: issueText.implicitHeight + 14

                        Text {
                            id: issueText
                            anchors.fill: parent
                            anchors.margins: 7
                            text: modelData.id + ": " + modelData.error
                            color: Colors.warning
                            font.pixelSize: Colors.fontSizeXS
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Installation"
            iconName: "󰋗"
            description: "Plugin format and discovery location."

            SettingsInfoCallout {
                iconName: "󰏗"
                title: "Plugin directory"
                body: "~/.config/quickshell/plugins/"

                Text {
                    text: "Each plugin is a folder containing a manifest.json and one or more QML entry points."
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: "Manifest v2 fields: id, name, description, author, version, type, permissions, entryPoints { barWidget|desktopWidget|launcherProvider|daemon|settings }"
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: "Reference schema: config/plugins/manifest-v2.schema.json"
                    color: Colors.fgDim
                    font.pixelSize: Colors.fontSizeXS
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
