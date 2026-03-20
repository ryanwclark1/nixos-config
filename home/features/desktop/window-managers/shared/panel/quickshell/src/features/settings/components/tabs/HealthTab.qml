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

    Component.onCompleted: SystemStatus.refreshHealth()

    readonly property color statusColor: {
        switch (SystemStatus.overallStatus) {
            case "healthy": return Colors.primary;
            case "warning": return Colors.warning;
            case "manual_review_required": return Colors.warning;
            case "failure": return Colors.error;
            default: return Colors.primary;
        }
    }

    readonly property string statusLabel: {
        switch (SystemStatus.overallStatus) {
            case "healthy": return "Healthy";
            case "warning": return "Warning";
            case "manual_review_required": return "Manual Review Required";
            case "failure": return "Failure";
            default: return SystemStatus.overallStatus;
        }
    }

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Diagnostics"
        iconName: "󰓅"

        // Overall Status
        SettingsCard {
            title: "Overall Status"
            iconName: "heart.svg"
            description: "Current health state of the shell."

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: root.statusColor

                    SequentialAnimation on opacity {
                        running: SystemStatus.overallStatus !== "healthy"
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.5; to: 1.0; duration: Appearance.durationLong; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.0; to: 0.5; duration: Appearance.durationLong; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    text: root.statusLabel
                    color: root.statusColor
                    font.pixelSize: Appearance.fontSizeLarge
                    font.weight: Font.Bold
                }
            }

            SettingsDataRow {
                iconName: "󱑎"
                label: "Last Check"
                value: SystemStatus.lastHealthCheckTime.getTime() > 0
                    ? Qt.formatDateTime(SystemStatus.lastHealthCheckTime, "hh:mm:ss") : "Never"
                monoValue: true
            }

            SettingsDataRow {
                iconName: "chat.svg"
                label: "Active Incidents"
                value: SystemStatus.activeIncidents.length.toString()
                monoValue: true
            }

            SettingsDataRow {
                iconName: "󰑣"
                label: "Health Scripts"
                value: SystemStatus._helperScriptsAvailable ? "Available" : "Unavailable"
                monoValue: true
            }
        }

        // Active Incidents
        SettingsCard {
            title: "Active Incidents"
            iconName: "󰀦"
            description: SystemStatus.activeIncidents.length > 0
                ? SystemStatus.activeIncidents.length + " active incident(s) detected."
                : "No active incidents."

            Repeater {
                model: SystemStatus.activeIncidents

                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: incidentCol.implicitHeight + Appearance.spacingM * 2
                    radius: Appearance.radiusXS
                    color: Colors.withAlpha(Colors.warning, 0.08)
                    border.color: Colors.withAlpha(Colors.warning, 0.2)
                    border.width: 1

                    ColumnLayout {
                        id: incidentCol
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingM
                        spacing: Appearance.spacingXS

                        Text {
                            text: modelData.signature || "Unknown incident"
                            color: Colors.warning
                            font.pixelSize: Appearance.fontSizeMedium
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: !!(modelData.message || modelData.description)
                            text: modelData.message || modelData.description || ""
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Text {
                visible: SystemStatus.activeIncidents.length === 0
                text: "All checks passed — no incidents to display."
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeSmall
            }
        }

        // System Vitals
        SettingsCard {
            title: "System Vitals"
            iconName: "board.svg"
            description: "Current resource usage and temperatures."

            Repeater {
                model: [
                    { icon: "", label: "CPU Usage", value: SystemStatus.cpuUsage, warn: SystemStatus.cpuPercent >= 0.85 },
                    { icon: "", label: "CPU Temp", value: SystemStatus.cpuTemp, warn: SystemStatus.cpuTempNum > 85 },
                    { icon: "board.svg", label: "RAM Usage", value: SystemStatus.ramUsage, warn: SystemStatus.ramPercent >= 0.9 },
                    { icon: "developer-board.svg", label: "GPU Usage", value: SystemStatus.gpuUsage, warn: SystemStatus.gpuPercent >= 0.9 },
                    { icon: "developer-board.svg", label: "GPU Temp", value: SystemStatus.gpuTemp, warn: SystemStatus.gpuTempNum > 80 },
                    { icon: "hard-drive.svg", label: "Disk", value: SystemStatus.diskUsage, warn: SystemStatus.diskPercent >= 0.9 },
                    { icon: "download.svg", label: "Network Down", value: SystemStatus.netDown, warn: false },
                    { icon: "upload.svg", label: "Network Up", value: SystemStatus.netUp, warn: false }
                ]

                delegate: SettingsDataRow {
                    iconName: modelData.icon
                    label: modelData.label
                    value: modelData.value + (modelData.warn ? "  ⚠" : "")
                    monoValue: true
                }
            }
        }

        // Actions
        SettingsCard {
            title: "Actions"
            iconName: "settings-cog-multiple.svg"
            description: "Health management and recovery actions."

            SettingsActionButton {
                Layout.fillWidth: true
                label: SystemStatus.isHealthChecking ? "Checking…" : "Run Health Check"
                iconName: "󰓅"
                emphasized: true
                enabled: !SystemStatus.isHealthChecking
                onClicked: SystemStatus.refreshHealth()
            }

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Apply Safe Fixes"
                iconName: "checkmark.svg"
                visible: SystemStatus.activeIncidents.length > 0
                onClicked: SystemStatus.applySafeFixes()
            }
        }
    }
}
