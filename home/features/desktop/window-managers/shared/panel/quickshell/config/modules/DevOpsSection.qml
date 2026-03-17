import QtQuick
import QtQuick.Layouts
import Quickshell
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
    transform: Translate {
        y: showContent ? 0 : 8
    }
    visible: opacity > 0

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation {
                duration: showContent ? (root.baseIndex * root.staggerDelay) : 0
            }
            NumberAnimation {
                duration: Colors.durationNormal + (root.baseIndex * 20)
                easing.type: Easing.OutCubic
            }
        }
    }
    Behavior on scale {
        SequentialAnimation {
            PauseAnimation {
                duration: showContent ? (root.baseIndex * root.staggerDelay) : 0
            }
            NumberAnimation {
                duration: Colors.durationNormal + (root.baseIndex * 20)
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
                duration: Colors.durationNormal + (root.baseIndex * 20)
                easing.type: Easing.OutCubic
            }
        }
    }

    Text {
        text: "DEVOPS & SERVICES"
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.Bold
        font.letterSpacing: Colors.letterSpacingWide
    }

    // ── Summary Row ────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingM

        // Docker Summary
        Rectangle {
            Layout.fillWidth: true
            height: 54
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: ServiceUnitService.dockerStatus === "ready" ? Colors.border : Colors.warning
            border.width: 1
            RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.paddingSmall
                Text {
                    text: "󰡨"
                    color: ServiceUnitService.dockerContainers.length > 0 ? Colors.primary : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXL
                    font.family: Colors.fontMono
                }
                Column {
                    Layout.fillWidth: true
                    Text {
                        text: ServiceUnitService.dockerContainers.length + " Docker"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Bold
                    }
                    Text {
                        visible: ServiceUnitService.dockerStatus !== "ready"
                        text: ServiceUnitService.dockerStatus === "missing" ? "Missing" : "Error"
                        color: Colors.warning
                        font.pixelSize: 10
                    }
                }
            }
        }

        // SSH Summary
        Rectangle {
            Layout.fillWidth: true
            height: 54
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: ServiceUnitService.sshStatus === "ready" ? Colors.border : Colors.warning
            border.width: 1
            RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.paddingSmall
                Text {
                    text: "󰣀"
                    color: ServiceUnitService.sshActiveCount > 0 ? Colors.accent : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXL
                    font.family: Colors.fontMono
                }
                Column {
                    Layout.fillWidth: true
                    Text {
                        text: ServiceUnitService.sshActiveCount + " SSH"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Bold
                    }
                    Text {
                        visible: ServiceUnitService.sshStatus !== "ready"
                        text: ServiceUnitService.sshStatus === "missing" ? "Missing" : "Error"
                        color: Colors.warning
                        font.pixelSize: 10
                    }
                }
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
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    Text {
                        text: "󰡨"
                        color: Colors.primary
                        font.pixelSize: Colors.fontSizeLarge
                        font.family: Colors.fontMono
                    }
                    Text {
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Row {
                        spacing: Colors.spacingXXS
                        SharedWidgets.IconButton {
                            icon: "󰆍"
                            size: 28
                            iconSize: 14
                            iconColor: Colors.textDisabled
                            onClicked: {
                                var cmd = "runtime=$(command -v docker || command -v podman); if [ -n \"$runtime\" ]; then \"$runtime\" exec -it " + modelData.id + " sh; else exit 1; fi";
                                Quickshell.execDetached(["sh", "-c", "for t in ghostty kitty foot alacritty wezterm; do if command -v $t >/dev/null 2>&1; then exec $t -e bash -lc '" + cmd.replace(/'/g, "'\\''") + "'; fi; done"]);
                            }
                        }
                        SharedWidgets.IconButton {
                            icon: "󰋚"
                            size: 28
                            iconSize: 14
                            iconColor: Colors.textDisabled
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
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    Text {
                        text: "󰣀"
                        color: Colors.accent
                        font.pixelSize: Colors.fontSizeLarge
                        font.family: Colors.fontMono
                    }
                    Text {
                        text: modelData
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    SharedWidgets.IconButton {
                        icon: "󰆍"
                        size: 28
                        iconSize: 14
                        iconColor: Colors.textDisabled
                        onClicked: {
                            var host = modelData.split("@")[1] || modelData;
                            var cmd = "ssh " + host;
                            Quickshell.execDetached(["sh", "-c", "for t in ghostty kitty foot alacritty wezterm; do if command -v $t >/dev/null 2>&1; then exec $t -e bash -lc '" + cmd.replace(/'/g, "'\\''") + "'; fi; done"]);
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
        font.pixelSize: Colors.fontSizeXS
        Layout.alignment: Qt.AlignHCenter
    }
}
