import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    property string aboutKernel: ""
    property string aboutHostname: ""
    property string aboutUptime: ""
    readonly property string aboutTheme: Config.themeName ? String(Config.themeName) : "pywal"

    Process {
        id: aboutInfoProc
        command: ["sh", "-c", "uname -r; echo '---'; hostname; echo '---'; uptime -p"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = (this.text || "").split("---");
                root.aboutKernel = parts[0] ? parts[0].trim() : "";
                root.aboutHostname = parts[1] ? parts[1].trim() : "";
                root.aboutUptime = parts[2] ? parts[2].trim() : "";
            }
        }
    }

    Process {
        id: restartShellProc
        command: ["sh", "-c", "quickshell --restart || quickshell-restart || qs --restart || true"]
        running: false
    }

    Component.onCompleted: {
        if (!aboutInfoProc.running)
            aboutInfoProc.running = true;
    }

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "About"
        iconName: "󰭹"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Shell Identity"
            description: "Current host and shell identity, plus the active theme/runtime context."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󱗼",
                            label: "Shell",
                            value: "QML Desktop Shell"
                        },
                        {
                            icon: "󰍹",
                            label: "Host",
                            value: root.aboutHostname || "…"
                        },
                        {
                            icon: "󰌢",
                            label: "Kernel",
                            value: root.aboutKernel || "…"
                        },
                        {
                            icon: "󰏘",
                            label: "Theme",
                            value: root.aboutTheme
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
            title: "System Runtime"
            description: "Live host details and operational actions for the running shell session."

            SettingsCard {
                title: "System Info"
                iconName: "󰘚"
                description: "Live host information from the current session."

                Repeater {
                    model: [
                        {
                            icon: "󰍹",
                            label: "Hostname",
                            value: root.aboutHostname || "…"
                        },
                        {
                            icon: "󰌢",
                            label: "Kernel",
                            value: root.aboutKernel || "…"
                        },
                        {
                            icon: "󱑎",
                            label: "Uptime",
                            value: root.aboutUptime || "…"
                        }
                    ]

                    delegate: SettingsDataRow {
                        iconName: modelData.icon
                        label: modelData.label
                        value: modelData.value
                        monoValue: true
                    }
                }
            }

            SettingsCard {
                title: "Actions"
                iconName: "settings-cog-multiple.svg"
                description: "Restart QuickShell when visual or runtime state drifts."

                SettingsActionButton {
                    Layout.fillWidth: true
                    label: "Restart Shell"
                    iconName: "settings-cog-multiple.svg"
                    emphasized: true
                    onClicked: {
                        if (root.settingsRoot)
                            root.settingsRoot.close();
                        restartShellProc.running = true;
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Credits"
            description: "A concise read on the shell stack and the theming source currently driving it."

            SettingsCard {
                title: "Credits"
                iconName: "󰀾"
                description: "Rendering stack and active theming source."

                Text {
                    text: "Built with Quickshell"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "Powered by Qt / QML"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeMedium
                }
                Text {
                    text: "Icons: Nerd Fonts"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeMedium
                }
                Text {
                    text: Config.themeName ? "Theme: " + Config.themeName : "Theming: pywal"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeMedium
                }
            }
        }
    }
}
