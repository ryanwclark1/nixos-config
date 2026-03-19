import QtQuick
import "../services"

Item {
    id: root

    property string text: ""
    property bool shown: false
    property int preferredSide: Qt.BottomEdge
    property int showDelay: 500

    anchors.fill: parent
    visible: false
    // Render above siblings
    z: 1000

    Timer {
        id: showTimer
        interval: root.showDelay
        onTriggered: root.visible = true
    }

    onShownChanged: {
        if (shown && text !== "") {
            showTimer.restart();
        } else {
            showTimer.stop();
            root.visible = false;
        }
    }

    Rectangle {
        id: bubble

        readonly property int _paddingH: Colors.spacingM
        readonly property int _paddingV: Colors.spacingXS
        readonly property int _gap: 4

        width: Math.min(240, tooltipLabel.implicitWidth + _paddingH * 2)
        height: tooltipLabel.implicitHeight + _paddingV * 2

        // Center horizontally (or vertically for left/right sides), offset past parent edge
        x: {
            switch (root.preferredSide) {
                case Qt.LeftEdge:  return -width - _gap;
                case Qt.RightEdge: return parent.width + _gap;
                default:           return (parent.width - width) / 2;
            }
        }
        y: {
            switch (root.preferredSide) {
                case Qt.TopEdge:   return -height - _gap;
                case Qt.LeftEdge:  // fall-through
                case Qt.RightEdge: return (parent.height - height) / 2;
                default:           return parent.height + _gap;  // Bottom
            }
        }

        radius: Colors.radiusXS
        color: Colors.withAlpha(Colors.surface, 0.95)
        border.color: Colors.border
        border.width: 1

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

        Text {
            id: tooltipLabel
            anchors.centerIn: parent
            width: Math.min(220, implicitWidth)
            text: root.text
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
