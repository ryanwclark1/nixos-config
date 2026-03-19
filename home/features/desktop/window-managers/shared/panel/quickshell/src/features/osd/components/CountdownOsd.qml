import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../../services"

Scope {
    id: root

    property int remaining: 0
    property bool active: false

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osdWindow
            property var modelData
            screen: modelData

            visible: root.active || fadeOut.running
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "countdown-osd"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            // Fade out when countdown finishes
            NumberAnimation on opacity {
                id: fadeOut
                from: 1; to: 0
                duration: 200
                running: false
                onFinished: osdWindow.opacity = 1
            }

            Connections {
                target: root
                function onActiveChanged() {
                    if (!root.active && osdWindow.visible)
                        fadeOut.start();
                }
            }

            Item {
                anchors.centerIn: parent

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Colors.spacingM

                    // Countdown circle
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 80; height: 80
                        radius: 40
                        color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.85)
                        border.color: Colors.primary
                        border.width: 2

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: root.remaining
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeDisplay
                            font.weight: Font.Bold
                            font.family: Colors.fontMono

                            // Scale-bounce on each tick
                            property real animScale: 1.0
                            scale: animScale

                            NumberAnimation on animScale {
                                id: tickAnim
                                from: 1.3; to: 1.0
                                duration: Colors.animFastSpatial.duration
                                easing.type: Easing.OutBack
                            }
                        }

                        Connections {
                            target: root
                            function onRemainingChanged() {
                                if (root.remaining > 0)
                                    tickAnim.restart();
                            }
                        }
                    }

                    // Cancel hint
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Click to cancel"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ScreenshotService.cancelDelay()
            }

            Keys.onEscapePressed: ScreenshotService.cancelDelay()
        }
    }
}
