import QtQuick
import "../services"

Item {
    id: root

    property string text: ""
    property string shortcut: ""
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

        readonly property int _paddingH: Appearance.spacingM
        readonly property int _paddingV: Appearance.spacingXS
        readonly property int _gap: Appearance.spacingS

        width: Math.min(280, tooltipRow.implicitWidth + _paddingH * 2)
        height: tooltipRow.implicitHeight + _paddingV * 2

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

        radius: Appearance.radiusXS
        color: Colors.withAlpha(Colors.surface, 0.95)
        border.color: Colors.border
        border.width: 1

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutCubic } }

        Row {
            id: tooltipRow
            anchors.centerIn: parent
            spacing: Appearance.spacingXS

            Text {
                id: tooltipLabel
                width: Math.min(200, implicitWidth)
                text: root.text
                color: Colors.text
                font.pixelSize: Appearance.fontSizeSmall
                wrapMode: Text.WordWrap
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                visible: root.shortcut !== ""
                anchors.verticalCenter: parent.verticalCenter
                radius: Appearance.radiusMicro
                color: Colors.withAlpha(Colors.text, 0.12)
                width: shortcutLabel.implicitWidth + Appearance.spacingXS * 2
                height: shortcutLabel.implicitHeight + 4

                Text {
                    id: shortcutLabel
                    anchors.centerIn: parent
                    text: root.shortcut
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    font.family: Appearance.fontMono
                }
            }
        }
    }
}
