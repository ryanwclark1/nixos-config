import QtQuick
import "../../../shared"
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    property int handleSize: 28
    property int hitSize: 40
    property int dragAxis: Drag.YAxis
    property real dragThreshold: 6
    property string iconSource: "re-order-dots-vertical.svg"
    property bool topAligned: false
    readonly property bool dragActive: dragArea.dragging
    readonly property bool pressed: dragArea.pressed
    readonly property bool containsMouse: dragArea.containsMouse
    readonly property real dragOffsetX: dragArea.dragOffsetX
    readonly property real dragOffsetY: dragArea.dragOffsetY

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

    SharedWidgets.SvgIcon {
        anchors.centerIn: parent
        source: root.iconSource
        color: root.dragActive ? Colors.text : (root.pressed ? Colors.primary : Colors.textSecondary)
        size: Appearance.fontSizeMedium
    }

    MouseArea {
        id: dragArea
        anchors.centerIn: parent
        width: root.hitSize
        height: root.hitSize
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true
        property bool dragging: false
        property real pressX: 0
        property real pressY: 0
        property real dragOffsetX: 0
        property real dragOffsetY: 0
        onPressed: mouse => {
            pressX = mouse.x;
            pressY = mouse.y;
            dragging = false;
            dragOffsetX = 0;
            dragOffsetY = 0;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;

            var nextOffsetX = mouse.x - pressX;
            var nextOffsetY = mouse.y - pressY;
            var thresholdPassed = Math.abs(nextOffsetX) >= root.dragThreshold || Math.abs(nextOffsetY) >= root.dragThreshold;

            if (!dragging && thresholdPassed)
                dragging = true;

            if (!dragging)
                return;

            if (root.dragAxis === Drag.XAxis) {
                dragOffsetX = nextOffsetX;
                dragOffsetY = 0;
                return;
            }

            if (root.dragAxis === Drag.YAxis) {
                dragOffsetX = 0;
                dragOffsetY = nextOffsetY;
                return;
            }

            dragOffsetX = nextOffsetX;
            dragOffsetY = nextOffsetY;
        }
        onReleased: {
            root.released(dragging);
            dragging = false;
            dragOffsetX = 0;
            dragOffsetY = 0;
        }
        onCanceled: {
            dragging = false;
            dragOffsetX = 0;
            dragOffsetY = 0;
        }
    }
}
