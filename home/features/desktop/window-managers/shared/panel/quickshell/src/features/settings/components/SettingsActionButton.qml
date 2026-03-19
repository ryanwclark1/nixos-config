import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    property string label: ""
    property string iconName: ""
    property bool emphasized: false
    property bool compact: false
    property bool enabled: true

    signal clicked(var mouse)

    implicitHeight: Math.max(compact ? 34 : 40, buttonRow.implicitHeight + (compact ? 12 : 14))
    implicitWidth: buttonRow.implicitWidth + (compact ? 18 : 24)
    radius: compact ? Colors.radiusSmall : Colors.radiusMedium
    color: root.emphasized ? Colors.primary : Colors.modalFieldSurface
    border.color: root.emphasized ? Colors.primary : Colors.border
    border.width: 1
    opacity: root.enabled ? 1.0 : 0.45

    Behavior on color {
        enabled: !Colors.isTransitioning
        CAnim {}
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
        anchors.fill: parent
        anchors.leftMargin: compact ? 9 : 12
        anchors.rightMargin: compact ? 9 : 12
        anchors.topMargin: compact ? 6 : 7
        anchors.bottomMargin: compact ? 6 : 7
        spacing: Colors.spacingS

        Text {
            visible: root.iconName !== ""
            text: root.iconName
            color: root.emphasized ? Colors.text : Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: compact ? Colors.fontSizeMedium : Colors.fontSizeLarge
            Layout.alignment: root.label === "" ? Qt.AlignHCenter | Qt.AlignVCenter : Qt.AlignVCenter
        }

        Text {
            id: labelText
            visible: root.label !== ""
            Layout.fillWidth: true
            text: root.label
            color: root.emphasized ? Colors.text : Colors.text
            font.pixelSize: compact ? Colors.fontSizeSmall : Colors.fontSizeMedium
            font.weight: root.emphasized ? Font.Bold : Font.Medium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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
