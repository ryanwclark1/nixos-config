import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../services/ShellUtils.js" as SU
import "../../../widgets" as SharedWidgets

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: Appearance.spacingM

    property bool showContent: false
    property int baseIndex: 15
    property int staggerDelay: 35

    opacity: showContent ? 1.0 : 0.0
    scale: showContent ? 1.0 : 0.96
    transform: Translate {
        y: showContent ? 0 : 8
    }
    visible: opacity > 0

    Behavior on opacity {
        SequentialAnimation {
            id: devopsFadeAnim
            PauseAnimation {
                duration: showContent ? (root.baseIndex * root.staggerDelay) : 0
            }
            NumberAnimation {
                duration: Appearance.durationNormal + (root.baseIndex * 20)
                easing.type: Easing.OutCubic
            }
        }
    }
    Behavior on scale {
        SequentialAnimation {
            id: devopsScaleAnim
            PauseAnimation {
                duration: showContent ? (root.baseIndex * root.staggerDelay) : 0
            }
            NumberAnimation {
                duration: Appearance.durationNormal + (root.baseIndex * 20)
                easing.type: Easing.OutBack
            }
        }
    }
    Behavior on transform {
        SequentialAnimation {
            PauseAnimation {
                duration: showContent ? (root.baseIndex * root.staggerDelay) : 0
            }
            NumberAnimation {
                duration: Appearance.durationNormal + (root.baseIndex * 20)
                easing.type: Easing.OutCubic
            }
        }
    }
    layer.enabled: devopsFadeAnim.running || devopsScaleAnim.running

    Text {
        text: "DEVOPS & SERVICES"
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
        font.weight: Font.Bold
        font.letterSpacing: Appearance.letterSpacingWide
    }

    // ── Summary Row ────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        // Docker Summary
        Rectangle {
            Layout.fillWidth: true
            height: 54
            radius: Appearance.radiusMedium
            color: Colors.cardSurface
            border.color: ServiceUnitService.dockerStatus === "ready" ? Colors.border : Colors.warning
            border.width: 1
            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.paddingSmall
                Text {
                    text: "󰡨"
                    color: ServiceUnitService.dockerContainers.length > 0 ? Colors.primary : Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXL
                    font.family: Appearance.fontMono
                }
                Column {
                    Layout.fillWidth: true
                    Text {
                        text: ServiceUnitService.dockerContainers.length + " Docker"
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.Bold
                    }
                    Text {
                        visible: ServiceUnitService.dockerStatus !== "ready"
                        text: ServiceUnitService.dockerStatus === "missing" ? "Missing" : "Error"
                        color: Colors.warning
                        font.pixelSize: Appearance.fontSizeCaption
                    }
                }
            }
        }

        // SSH Summary
        Rectangle {
            Layout.fillWidth: true
            height: 54
            radius: Appearance.radiusMedium
            color: Colors.cardSurface
            border.color: ServiceUnitService.sshStatus === "ready" ? Colors.border : Colors.warning
            border.width: 1
            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.paddingSmall
                Text {
                    text: "󰣀"
                    color: ServiceUnitService.sshActiveCount > 0 ? Colors.accent : Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXL
                    font.family: Appearance.fontMono
                }
                Column {
                    Layout.fillWidth: true
                    Text {
                        text: {
                            var count = ServiceUnitService.sshActiveCount;
                            if (count === 0) return "0 SSH";
                            var types = {};
                            var sessions = ServiceUnitService.sshSessions;
                            for (var i = 0; i < sessions.length; i++) {
                                var t = sessions[i].type || "ssh";
                                types[t] = (types[t] || 0) + (sessions[i].count || 1);
                            }
                            var parts = [];
                            var order = ["ssh", "scp", "sftp", "rsync", "sshfs"];
                            for (var j = 0; j < order.length; j++) {
                                if (types[order[j]])
                                    parts.push(types[order[j]] + " " + order[j].toUpperCase());
                            }
                            return parts.join(" · ") || (count + " SSH");
                        }
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.Bold
                    }
                    Text {
                        visible: ServiceUnitService.sshStatus !== "ready"
                        text: ServiceUnitService.sshStatus === "missing" ? "Missing" : "Error"
                        color: Colors.warning
                        font.pixelSize: Appearance.fontSizeCaption
                    }
                }
            }
        }
    }

    // ── Active Item List ────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingXS
        visible: ServiceUnitService.dockerContainers.length > 0 || ServiceUnitService.sshActiveCount > 0

        Repeater {
            model: ServiceUnitService.dockerContainers.slice(0, 3)
            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Appearance.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS
                    Text {
                        text: "󰡨"
                        color: Colors.primary
                        font.pixelSize: Appearance.fontSizeLarge
                        font.family: Appearance.fontMono
                    }
                    Text {
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Row {
                        spacing: Appearance.spacingXXS
                        SharedWidgets.IconButton {
                            icon: "terminal.svg"
                            size: 28
                            iconSize: 14
                            iconColor: Colors.textDisabled
                            tooltipText: "Open shell"
                            onClicked: {
                                var cmd = "runtime=$(command -v docker || command -v podman); if [ -n \"$runtime\" ]; then \"$runtime\" exec -it " + modelData.id + " sh; else exit 1; fi";
                                Quickshell.execDetached(SU.terminalCommand(cmd));
                            }
                        }
                        SharedWidgets.IconButton {
                            icon: "arrow-counterclockwise.svg"
                            size: 28
                            iconSize: 14
                            iconColor: Colors.textDisabled
                            tooltipText: "View logs"
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
            model: ServiceUnitService.sshSessions.slice(0, 4)
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Appearance.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1

                readonly property string sessionType: modelData.type || "ssh"
                readonly property string sessionLabel: modelData.label || ""
                readonly property int sessionCount: modelData.count || 1
                readonly property string typeIcon: {
                    switch (sessionType) {
                    case "scp":   return "󰆏";
                    case "sftp":  return "󰉋";
                    case "rsync": return "󰓦";
                    case "sshfs": return "󰋊";
                    default:      return "󰣀";
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS
                    Text {
                        text: typeIcon
                        color: Colors.accent
                        font.pixelSize: Appearance.fontSizeLarge
                        font.family: Appearance.fontMono
                    }
                    Text {
                        text: sessionLabel + (sessionCount > 1 ? " ×" + sessionCount : "")
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: sessionType !== "ssh"
                        text: sessionType.toUpperCase()
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXXS
                        font.weight: Font.Medium
                    }

                    SharedWidgets.IconButton {
                        visible: sessionType === "ssh"
                        icon: "terminal.svg"
                        size: 28
                        iconSize: 14
                        iconColor: Colors.textDisabled
                        tooltipText: "Open shell"
                        onClicked: {
                            var host = sessionLabel.split("@")[1] || sessionLabel;
                            Quickshell.execDetached(SU.terminalCommand("exec ssh \"$1\"", host));
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
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
        Layout.alignment: Qt.AlignHCenter
    }
}
