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
        command: ["sh", "-c", "uname -r; echo '---'; hostname; echo '---'; cat /proc/uptime 2>/dev/null | cut -d' ' -f1"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = (this.text || "").split("---");
                root.aboutKernel = parts[0] ? parts[0].trim() : "";
                root.aboutHostname = parts[1] ? parts[1].trim() : "";
                
                var uptimeSecs = parseFloat(String(parts[2] || "").trim() || "0");
                if (isNaN(uptimeSecs) || uptimeSecs === 0) {
                    root.aboutUptime = "…";
                } else {
                    var d = Math.floor(uptimeSecs / 86400);
                    var h = Math.floor((uptimeSecs % 86400) / 3600);
                    var m = Math.floor((uptimeSecs % 3600) / 60);
                    var dStr = d > 0 ? d + (d === 1 ? " day" : " days") : "";
                    var hStr = h > 0 ? h + (h === 1 ? " hour" : " hours") : "";
                    var mStr = m + (m === 1 ? " minute" : " minutes");
                    
                    var p = [];
                    if (dStr) p.push(dStr);
                    if (hStr) p.push(hStr);
                    p.push(mStr);
                    
                    root.aboutUptime = "up " + p.join(", ");
                }
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
        iconName: "info.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Shell Identity"
            description: "Current host and shell identity, plus the active theme/runtime context."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingM

                Repeater {
                    model: [
                        {
                            icon: "widgets.svg",
                            label: "Shell",
                            value: "QML Desktop Shell"
                        },
                        {
                            icon: "desktop.svg",
                            label: "Host",
                            value: root.aboutHostname || "…"
                        },
                        {
                            icon: "laptop.svg",
                            label: "Kernel",
                            value: root.aboutKernel || "…"
                        },
                        {
                            icon: "color-palette.svg",
                            label: "Theme",
                            value: root.aboutTheme
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
            title: "System Runtime"
            description: "Live host details and operational actions for the running shell session."

            SettingsCard {
                title: "System Info"
                iconName: "server.svg"
                description: "Live host information from the current session."

                Repeater {
                    model: [
                        {
                            icon: "desktop.svg",
                            label: "Hostname",
                            value: root.aboutHostname || "…"
                        },
                        {
                            icon: "laptop.svg",
                            label: "Kernel",
                            value: root.aboutKernel || "…"
                        },
                        {
                            icon: "heart-pulse.svg",
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
                iconName: "info.svg"
                description: "Rendering stack and active theming source."

                Text {
                    text: "Built with Quickshell"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeMedium
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "Powered by Qt / QML"
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeMedium
                }
                Text {
                    text: "Icons: Nerd Fonts"
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeMedium
                }
                Text {
                    text: Config.themeName ? "Theme: " + Config.themeName : "Theming: pywal"
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeMedium
                }
            }
        }
    }
}
