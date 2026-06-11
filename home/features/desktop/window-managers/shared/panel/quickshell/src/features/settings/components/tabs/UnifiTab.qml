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
        tabId: root.tabId
        title: "UniFi"
        iconName: "brands/ubiquiti-symbolic.svg"

        SettingsCard {
            title: "Cloud API (Site Manager)"
            iconName: "cloud.svg"
            description: "Connect to the UniFi Site Manager cloud API for network overview, device status, and ISP metrics."

            SettingsInfoCallout {
                body: "Create an API key at unifi.ui.com → Settings → API. The key is read-only and scoped to your account."
            }

            SettingsSecretInputRow {
                label: "API Key"
                leadingIcon: "key.svg"
                placeholderText: "Enter your UniFi cloud API key..."
                text: Config.unifiApiKey
                onTextEdited: value => Config.unifiApiKey = value
            }

            SettingsSliderRow {
                label: "Poll Interval"
                icon: "clock.svg"
                description: "How often to refresh data from the cloud API."
                value: Config.unifiPollInterval
                min: 15
                max: 300
                step: 15
                unit: "s"
                onMoved: value => Config.unifiPollInterval = value
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                SettingsActionButton {
                    label: "Test Connection"
                    iconName: "checkmark.svg"
                    enabled: Config.unifiApiKey !== ""
                    onClicked: {
                        UnifiNetworkService.refresh();
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (Config.unifiApiKey === "") return "No API key configured";
                        if (UnifiNetworkService.status === "ready")
                            return "Connected — " + UnifiNetworkService.totalDevices + " devices, " + UnifiNetworkService.sites.length + " sites";
                        if (UnifiNetworkService.status === "error")
                            return "Error: " + UnifiNetworkService.errorMessage;
                        if (UnifiNetworkService.status === "loading")
                            return "Connecting...";
                        return "Not connected";
                    }
                    color: {
                        if (UnifiNetworkService.status === "ready") return Colors.primary;
                        if (UnifiNetworkService.status === "error") return Colors.error;
                        return Colors.textSecondary;
                    }
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        SettingsCard {
            title: "Protect (Cameras)"
            iconName: "brands/unifi-protect-symbolic.svg"
            description: "Connect to your local UniFi Protect controller for camera snapshots and live RTSPS streams."

            SettingsInfoCallout {
                body: "Enter the IP or hostname of your Protect controller (e.g. 192.168.1.1) and an API key generated on the controller under Settings → API."
            }

            SettingsTextInputRow {
                label: "Protect Host"
                leadingIcon: "server.svg"
                placeholderText: "e.g. 192.168.1.1 or protect.local"
                text: Config.unifiProtectHost
                onTextEdited: value => Config.unifiProtectHost = value
            }

            SettingsSecretInputRow {
                label: "Protect API Key"
                leadingIcon: "key.svg"
                placeholderText: "Enter your Protect API key..."
                text: Config.unifiProtectApiKey
                onTextEdited: value => Config.unifiProtectApiKey = value
            }

            SettingsSliderRow {
                label: "Snapshot Interval"
                icon: "clock.svg"
                description: "How often to refresh camera snapshots and status."
                value: Config.unifiProtectPollInterval
                min: 10
                max: 120
                step: 5
                unit: "s"
                onMoved: value => Config.unifiProtectPollInterval = value
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                SettingsActionButton {
                    label: "Test Connection"
                    iconName: "checkmark.svg"
                    enabled: Config.unifiProtectHost !== "" && Config.unifiProtectApiKey !== ""
                    onClicked: {
                        UnifiProtectService.refresh();
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (Config.unifiProtectHost === "" || Config.unifiProtectApiKey === "") return "Host and API key required";
                        if (UnifiProtectService.status === "ready")
                            return "Connected — " + UnifiProtectService.totalCameras + " cameras (" + UnifiProtectService.onlineCameras + " online)";
                        if (UnifiProtectService.status === "error")
                            return "Error: " + UnifiProtectService.errorMessage;
                        if (UnifiProtectService.status === "loading")
                            return "Connecting...";
                        return "Not connected";
                    }
                    color: {
                        if (UnifiProtectService.status === "ready") return Colors.primary;
                        if (UnifiProtectService.status === "error") return Colors.error;
                        return Colors.textSecondary;
                    }
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
