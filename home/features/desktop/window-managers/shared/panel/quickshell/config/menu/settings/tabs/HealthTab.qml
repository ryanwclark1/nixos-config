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

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "System Health"

        SettingsCard {
            title: "Status Overview"
            description: "Real-time health status of the shell and its components."

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXL

                // Status Indicator
                Rectangle {
                    width: 120; height: 120; radius: 60
                    color: {
                        switch (SystemStatus.overallStatus) {
                            case "healthy": return Colors.withAlpha(Colors.success, 0.15);
                            case "warning": return Colors.withAlpha(Colors.warning, 0.15);
                            case "manual_review_required": return Colors.withAlpha(Colors.error, 0.15);
                            default: return Colors.withAlpha(Colors.textDisabled, 0.15);
                        }
                    }
                    border.color: {
                        switch (SystemStatus.overallStatus) {
                            case "healthy": return Colors.success;
                            case "warning": return Colors.warning;
                            case "manual_review_required": return Colors.error;
                            default: return Colors.textDisabled;
                        }
                    }
                    border.width: 3

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                switch (SystemStatus.overallStatus) {
                                    case "healthy": return "󰄬";
                                    case "warning": return "󰀪";
                                    case "manual_review_required": return "󰅚";
                                    default: return "󰓅";
                                }
                            }
                            color: parent.parent.border.color
                            font.pixelSize: 48
                            font.family: Colors.fontMono
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: SystemStatus.overallStatus.replace(/_/g, " ").toUpperCase()
                            color: Colors.text
                            font.pixelSize: 10
                            font.weight: Font.Black
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Text {
                        text: "System checks are performed automatically every 5 minutes."
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Last check: " + SystemStatus.lastHealthCheckTime.toLocaleString(Qt.locale(), "hh:mm:ss")
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                    }

                    RowLayout {
                        spacing: Colors.spacingM
                        SettingsActionButton {
                            label: "Refresh Now"
                            iconName: "󰑐"
                            onClicked: SystemStatus.refreshHealth()
                            enabled: !SystemStatus.isHealthChecking
                        }
                        SettingsActionButton {
                            label: "Apply Safe Fixes"
                            iconName: "󰁨"
                            onClicked: SystemStatus.applySafeFixes()
                            visible: SystemStatus.overallStatus === "safe_fix_pending"
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Active Incidents"
            description: "Detailed report of detected issues and required actions."
            visible: SystemStatus.activeIncidents.length > 0

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Repeater {
                    model: SystemStatus.activeIncidents
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: incidentRow.implicitHeight + 24
                        radius: Colors.radiusMedium
                        color: Colors.withAlpha(modelData.severity === "error" ? Colors.error : Colors.warning, 0.1)
                        border.color: Colors.withAlpha(modelData.severity === "error" ? Colors.error : Colors.warning, 0.3)
                        border.width: 1

                        RowLayout {
                            id: incidentRow
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingM

                            Rectangle {
                                width: 32; height: 32; radius: 16
                                color: parent.parent.border.color
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.severity === "error" ? "󰅚" : "󰀪"
                                    color: "white"
                                    font.pixelSize: 18
                                    font.family: Colors.fontMono
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: modelData.signature
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: modelData.summary
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            SettingsActionButton {
                                label: "Fix"
                                iconName: "󰁨"
                                compact: true
                                visible: !!modelData.safe_fix_available
                                onClicked: SystemStatus.applySafeFixes()
                            }
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Plugin Diagnostics"
            description: "Manifest validation and runtime health for installed plugins."
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingL
                    
                    Repeater {
                        model: [
                            { l: "PASS", v: SystemStatus.pluginDiagnostics.summary ? SystemStatus.pluginDiagnostics.summary.pass : 0, c: Colors.success },
                            { l: "FAIL", v: SystemStatus.pluginDiagnostics.summary ? SystemStatus.pluginDiagnostics.summary.fail : 0, c: Colors.error },
                            { l: "WARN", v: SystemStatus.pluginDiagnostics.summary ? SystemStatus.pluginDiagnostics.summary.warn : 0, c: Colors.warning }
                        ]
                        delegate: RowLayout {
                            spacing: Colors.spacingXS
                            Rectangle { width: 8; height: 8; radius: 4; color: modelData.c }
                            Text { text: modelData.v + " " + modelData.l; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingXS

                    Repeater {
                        model: SystemStatus.pluginDiagnostics.entries || []
                        delegate: SettingsListRow {
                            active: modelData.status === "FAIL"
                            rowContent: [
                                Text {
                                    text: modelData.status === "PASS" ? "󰄬" : (modelData.status === "FAIL" ? "󰅚" : "󰀪")
                                    color: modelData.status === "PASS" ? Colors.success : (modelData.status === "FAIL" ? Colors.error : Colors.warning)
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeMedium
                                },
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold }
                                    Text { text: modelData.message; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            ]
                        }
                    }
                }
            }
        }
    }
}
