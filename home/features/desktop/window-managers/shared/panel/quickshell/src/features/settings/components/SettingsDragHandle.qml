import QtQuick
import "../../../shared"
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
    radius: Appearance.radiusSmall
    color: root.dragActive ? Colors.primaryStrong : (root.pressed ? Colors.primaryMid : (root.containsMouse ? Colors.withAlpha(Colors.primary, 0.18) : Colors.withAlpha(Colors.text, 0.05)))
    border.color: root.dragActive ? Colors.primary : (root.containsMouse ? Colors.primaryRing : Colors.border)
    border.width: root.dragActive || root.containsMouse ? 1 : 0
    opacity: root.enabled ? 1.0 : 0.45

    Behavior on color {
        enabled: !Colors.isTransitioning
        CAnim {}
    }

    Text {
        anchors.centerIn: parent
        text: root.iconText
        color: root.dragActive ? Colors.text : (root.pressed ? Colors.primary : Colors.textSecondary)
        font.family: Appearance.fontMono
        font.pixelSize: Appearance.fontSizeMedium
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
