import QtQuick
import "../../../services"

Rectangle {
    id: root

    property Item dragTarget: null
    property bool enabled: true
    property int handleSize: 28
    property int hitSize: 40
    property int dragAxis: Drag.YAxis
    property string iconText: "󰆾"
    property bool topAligned: false
    readonly property bool dragActive: dragArea.drag.active
    readonly property bool pressed: dragArea.pressed
    readonly property bool containsMouse: dragArea.containsMouse

    signal released(bool wasDragging)

    implicitWidth: handleSize
    implicitHeight: handleSize
    radius: Colors.radiusSmall
    color: root.pressed ? Colors.withAlpha(Colors.primary, 0.18) : (root.containsMouse ? Colors.withAlpha(Colors.text, 0.10) : "transparent")
    border.color: root.containsMouse ? Colors.border : "transparent"
    border.width: root.containsMouse ? 1 : 0
    opacity: root.enabled ? 1.0 : 0.45

    Behavior on color {
        ColorAnimation {
            duration: Colors.durationFast
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.iconText
        color: root.pressed ? Colors.primary : Colors.textSecondary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeMedium
    }

    MouseArea {
        id: dragArea
        anchors.centerIn: parent
        width: root.hitSize
        height: root.hitSize
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: root.enabled ? root.dragTarget : undefined
        drag.axis: root.dragAxis
        preventStealing: true
        onReleased: {
            root.released(drag.active);
        }
    }
}
