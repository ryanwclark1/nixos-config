import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
    id: overviewWindow

    required property bool isVisible
    signal closeRequested()
    default property alias content: contentArea.data

    visible: isVisible

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: -1

    onVisibleChanged: if (visible)
        mainRect.forceActiveFocus()

    Rectangle {
        id: mainRect
        anchors.fill: parent
        color: Colors.bgGlass
        focus: true

        opacity: 0.0
        Component.onCompleted: {
            opacity = 1.0;
            forceActiveFocus();
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.durationNormal
                easing.type: Easing.InOutQuad
            }
        }

        Keys.onEscapePressed: overviewWindow.closeRequested()

        MouseArea {
            anchors.fill: parent
            onClicked: overviewWindow.closeRequested()
        }

        Item {
            id: contentArea
            anchors.fill: parent
            anchors.margins: 40
        }
    }
}
