import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
    id: root

    property string label: ""
    property string iconName: ""
    property bool emphasized: false
    property bool compact: false
    property bool enabled: true

    signal clicked(var mouse)

    implicitHeight: compact ? 34 : 40
    implicitWidth: buttonRow.implicitWidth + (compact ? 18 : 24)
    radius: compact ? Colors.radiusSmall : Colors.radiusMedium
    color: root.emphasized ? Colors.primary : Colors.bgWidget
    border.color: root.emphasized ? Colors.primary : Colors.border
    border.width: 1
    opacity: root.enabled ? 1.0 : 0.45

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    SharedWidgets.StateLayer {
        id: stateLayer
        hovered: buttonMouse.containsMouse
        pressed: buttonMouse.pressed
        disabled: !root.enabled
        stateColor: root.emphasized ? Colors.text : Colors.primary
    }

    RowLayout {
        id: buttonRow
        anchors.centerIn: parent
        spacing: Colors.spacingS

        Text {
            visible: root.iconName !== ""
            text: root.iconName
            color: root.emphasized ? Colors.text : Colors.fgSecondary
            font.family: Colors.fontMono
            font.pixelSize: compact ? Colors.fontSizeMedium : Colors.fontSizeLarge
        }

        Text {
            text: root.label
            color: root.emphasized ? Colors.text : Colors.text
            font.pixelSize: compact ? Colors.fontSizeSmall : Colors.fontSizeMedium
            font.weight: root.emphasized ? Font.Bold : Font.Medium
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            stateLayer.burst(mouse.x, mouse.y);
            root.clicked(mouse);
        }
    }
}
