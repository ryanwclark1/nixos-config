import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
    id: root
    title: "DevOps & Services"
    subtitle: "Containers, Units & Sessions"
    popupMinWidth: 380; popupMaxWidth: 440

    SharedWidgets.Ref { service: ServiceUnitService }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingM

        // ── Docker Containers ──────────────────────
        SharedWidgets.SectionLabel {
            label: "DOCKER CONTAINERS (" + ServiceUnitService.dockerContainers.length + ")"
            visible: ServiceUnitService.dockerStatus !== "missing"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS
            visible: ServiceUnitService.dockerStatus !== "missing"

            Repeater {
                model: ServiceUnitService.dockerContainers
                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: Colors.radiusMedium
                    color: Colors.withAlpha(modelData.state === "running" ? Colors.primary : Colors.surface, 0.12)
                    border.color: modelData.state === "running" ? Colors.primary : Colors.border
                    border.width: 1

                    // Inner highlight
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 1; radius: parent.radius - 1
                        color: "transparent"; border.color: Colors.borderLight; border.width: 1; opacity: 0.15
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: Colors.spacingM
                        spacing: Colors.spacingM

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: modelData.status; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXXS; elide: Text.ElideRight; Layout.fillWidth: true }
                        }

                        Row {
                            spacing: Colors.spacingS
                            SharedWidgets.IconButton {
                                icon: modelData.state === "running" ? "󰓛" : "󰐊"
                                iconColor: modelData.state === "running" ? Colors.warning : Colors.success
                                size: 32; iconSize: 18
                                onClicked: ServiceUnitService.runDockerAction(modelData.id, modelData.state === "running" ? "stop" : "start")
                            }
                            SharedWidgets.IconButton {
                                icon: "󰑐"; iconColor: Colors.textSecondary
                                size: 32; iconSize: 18
                                onClicked: ServiceUnitService.runDockerAction(modelData.id, "restart")
                            }
                        }
                    }
                }
            }
            
            Text {
                visible: ServiceUnitService.dockerContainers.length === 0
                text: "No containers found"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeSmall
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── Active SSH Sessions ─────────────────────
        SharedWidgets.SectionLabel {
            label: "SSH SESSIONS (" + ServiceUnitService.sshActiveCount + ")"
            visible: ServiceUnitService.sshActiveCount > 0
        }

        Flow {
            Layout.fillWidth: true
            spacing: Colors.spacingS
            visible: ServiceUnitService.sshActiveCount > 0

            Repeater {
                model: ServiceUnitService.sshSessions
                delegate: Rectangle {
                    width: sshLabel.implicitWidth + 24; height: 28
                    radius: 14
                    color: Colors.withAlpha(Colors.accent, 0.15)
                    border.color: Colors.accent; border.width: 1
                    
                    Text {
                        id: sshLabel
                        anchors.centerIn: parent
                        text: "󰣀 " + modelData
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeXXS
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // ── Critical System Services ────────────────
        SharedWidgets.SectionLabel { label: "SYSTEM SERVICES" }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            Repeater {
                // Show a few high-level services or just user units for now
                model: ServiceUnitService.userUnits.slice(0, 5)
                delegate: Rectangle {
                    Layout.fillWidth: true; implicitHeight: 46; radius: Colors.radiusSmall
                    color: Colors.withAlpha(Colors.surface, 0.3)
                    border.color: Colors.border; border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.margins: Colors.spacingM
                        spacing: Colors.spacingM
                        
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: modelData.active === "active" ? Colors.success : Colors.error
                        }

                        Text {
                            text: modelData.name.replace(".service", ""); color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }

                        SharedWidgets.IconButton {
                            icon: "󰑐"; size: 28; iconSize: 16
                            onClicked: ServiceUnitService.restartUnit("user", modelData.name)
                        }
                    }
                }
            }
            
            SettingsActionButton {
                Layout.alignment: Qt.AlignHCenter
                label: "Manage All Services"
                iconName: "󰒓"
                onClicked: {
                    root.closeRequested();
                    Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "system"]);
                }
            }
        }
    }
}
