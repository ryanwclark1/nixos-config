import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: Colors.spacingM

    property bool showContent: false
    property int baseIndex: 15
    property int staggerDelay: 35

    opacity: showContent ? 1.0 : 0.0
    scale: showContent ? 1.0 : 0.96
    transform: Translate { y: showContent ? 0 : 8 }
    visible: opacity > 0
    
    Behavior on opacity { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutCubic } } }
    Behavior on scale { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutBack } } }
    Behavior on transform { SequentialAnimation { PauseAnimation { duration: showContent ? (root.baseIndex * root.staggerDelay) : 0 } NumberAnimation { duration: Colors.durationNormal + (root.baseIndex * 20); easing.type: Easing.OutCubic } } }

    Text {
        text: "DEVOPS & SERVICES"
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.Bold
        font.letterSpacing: 1.0
    }

    // ── Summary Row ────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingM

        // Docker Summary
        Rectangle {
            Layout.fillWidth: true; height: 54; radius: Colors.radiusMedium
            color: Colors.withAlpha(Colors.surface, 0.3)
            border.color: Colors.border; border.width: 1
            RowLayout {
                anchors.fill: parent; anchors.margins: Colors.paddingSmall
                Text { text: "󰡨"; color: ServiceUnitService.dockerContainers.length > 0 ? Colors.primary : Colors.textDisabled; font.pixelSize: 20; font.family: Colors.fontMono }
                Text { text: ServiceUnitService.dockerContainers.length + " Docker"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold }
            }
        }

        // SSH Summary
        Rectangle {
            Layout.fillWidth: true; height: 54; radius: Colors.radiusMedium
            color: Colors.withAlpha(Colors.surface, 0.3)
            border.color: Colors.border; border.width: 1
            RowLayout {
                anchors.fill: parent; anchors.margins: Colors.paddingSmall
                Text { text: "󰣀"; color: ServiceUnitService.sshActiveCount > 0 ? Colors.accent : Colors.textDisabled; font.pixelSize: 20; font.family: Colors.fontMono }
                Text { text: ServiceUnitService.sshActiveCount + " SSH"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold }
            }
        }
    }

    // ── Active Item List ────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingXS
        visible: ServiceUnitService.dockerContainers.length > 0 || ServiceUnitService.sshActiveCount > 0

        Repeater {
            model: ServiceUnitService.dockerContainers.slice(0, 3)
            delegate: Rectangle {
                Layout.fillWidth: true; implicitHeight: 42; radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.2); border.color: Colors.border; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 8
                    Text { text: "󰡨"; color: Colors.primary; font.pixelSize: 16; font.family: Colors.fontMono }
                    Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeXS; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    
                    Row {
                        spacing: 2
                        SharedWidgets.IconButton {
                            icon: "󰆍"; size: 28; iconSize: 14; iconColor: Colors.textDisabled
                            onClicked: Quickshell.execDetached(["ghostty", "-e", "docker", "exec", "-it", modelData.id, "sh"])
                        }
                        SharedWidgets.IconButton {
                            icon: "󰋚"; size: 28; iconSize: 14; iconColor: Colors.textDisabled
                            onClicked: {
                                logOverlay.title = "Docker: " + modelData.name;
                                logOverlay.command = ServiceUnitService.getLogStreamCommand("docker", modelData.id);
                                logOverlay.visible = true;
                            }
                        }
                    }
                }
            }
        }

        Repeater {
            model: ServiceUnitService.sshSessions.slice(0, 2)
            delegate: Rectangle {
                Layout.fillWidth: true; implicitHeight: 42; radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.2); border.color: Colors.border; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 8
                    Text { text: "󰣀"; color: Colors.accent; font.pixelSize: 16; font.family: Colors.fontMono }
                    Text { text: modelData; color: Colors.text; font.pixelSize: Colors.fontSizeXS; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    
                    Row {
                        spacing: 2
                        SharedWidgets.IconButton {
                            icon: "󰆍"; size: 28; iconSize: 14; iconColor: Colors.textDisabled
                            onClicked: {
                                var host = modelData.split("@")[1] || modelData;
                                Quickshell.execDetached(["ghostty", "-e", "ssh", host]);
                            }
                        }
                        SharedWidgets.IconButton {
                            icon: "󰋚"; size: 28; iconSize: 14; iconColor: Colors.textDisabled
                            onClicked: {
                                logOverlay.title = "SSH: " + modelData;
                                // For SSH, we might just tail secure or similar if we had perms, 
                                // but here we'll just show systemd logs for sshd as a demo
                                logOverlay.command = ServiceUnitService.getLogStreamCommand("system", "sshd");
                                logOverlay.visible = true;
                            }
                        }
                    }
                }
            }
        }
    }

    // Live Log Overlay
    SharedWidgets.LiveLogOverlay {
        id: logOverlay
        Layout.fillWidth: true
        Layout.preferredHeight: 300
        visible: false
        onCloseRequested: {
            visible = false;
            command = [];
        }
    }

    Text {
        visible: ServiceUnitService.dockerContainers.length === 0 && ServiceUnitService.sshActiveCount === 0
        text: "No active containers or sessions"
        color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.alignment: Qt.AlignHCenter
    }
}
