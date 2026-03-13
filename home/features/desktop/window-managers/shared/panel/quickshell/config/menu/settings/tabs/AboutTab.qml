import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
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
        tabId: root.tabId
        title: "About"
        iconName: "󰭹"

        SettingsCard {
            title: "QuickShell"
            iconName: "󱗼"
            description: "Core shell runtime and identity."

            Text {
                text: "QML Desktop Shell"
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeMedium
            }
        }

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
            iconName: "󰜉"
            description: "Restart QuickShell when visual or runtime state drifts."

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Restart Shell"
                iconName: "󰜉"
                emphasized: true
                onClicked: {
                    if (root.settingsRoot)
                        root.settingsRoot.close();
                    restartShellProc.running = true;
                }
            }
        }

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
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeMedium
            }
            Text {
                text: "Icons: Nerd Fonts"
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeMedium
            }
            Text {
                text: Config.themeName ? "Theme: " + Config.themeName : "Theming: pywal"
                color: Colors.fgSecondary
                font.pixelSize: Colors.fontSizeMedium
            }
        }
    }
}
