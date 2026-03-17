import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets"

RowLayout {
    id: root
    required property var lockPowerButtons
    required property string pendingAction
    required property bool timerActive
    signal actionRequested(string action)
    spacing: Colors.spacingS

    SessionButton {
        readonly property var actionMeta: SystemActionRegistry.actionById("logout") || ({})
        icon: String(actionMeta.icon || "")
        label: String(actionMeta.label || actionMeta.name || "")
        action: "logout"
    }
    SessionButton { icon: "󰤄"; label: "Suspend"; action: "suspend" }
    Repeater {
        model: root.lockPowerButtons
        delegate: SessionButton {
            required property var modelData
            icon: String(modelData.icon || "")
            label: String(modelData.label || modelData.name || "")
            action: String(modelData.id || "")
        }
    }

    component SessionButton: Rectangle {
        property string icon: ""
        property string label: ""
        property string action: ""

        width: 36; height: 36; radius: height / 2
        color: Colors.withAlpha(Colors.text, 0.05)
        border.color: (root.timerActive && root.pendingAction === action) ? Colors.error : Colors.border
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

        StateLayer {
            id: sessionStateLayer
            hovered: sessionMa.containsMouse
            pressed: sessionMa.pressed
        }

        Text {
            anchors.centerIn: parent
            text: parent.icon
            color: (root.timerActive && root.pendingAction === parent.action) ? Colors.error : Colors.textSecondary
            Behavior on color { ColorAnimation { duration: Colors.durationFast } }
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
        }

        MouseArea {
            id: sessionMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                sessionStateLayer.burst(mouse.x, mouse.y);
                root.actionRequested(parent.action);
            }
        }

        BarTooltip {
            text: parent.label
            anchorItem: parent
            hovered: sessionMa.containsMouse
        }
    }
}
