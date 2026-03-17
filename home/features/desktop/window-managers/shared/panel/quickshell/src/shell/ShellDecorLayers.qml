import QtQuick
import Quickshell
import Quickshell.Wayland
import "../widgets"

Item {
    id: root
    property bool showBorders: false

    Dock {
        id: dock
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property ShellScreen modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }
                color: "transparent"
                exclusiveZone: -1
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                DesktopWidgets {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 80
                    anchors.topMargin: 120
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            ToastOverlay {
                required property ShellScreen modelData
                screenModel: modelData
            }
        }
    }

    Corners {
        id: screenCorners
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            ScreenBorder {
                required property ShellScreen modelData
                screen: modelData
                visible: root.showBorders
            }
        }
    }
}
