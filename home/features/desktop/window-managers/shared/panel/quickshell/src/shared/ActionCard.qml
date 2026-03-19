import QtQuick
import QtQuick.Layouts
import "."
import "../services"

Rectangle {
    id: root

    required property string icon
    required property string label
    property color accentColor: Colors.primary
    property bool compact: false
    property bool danger: false
    property string tooltipText: ""
    property string tooltipShortcut: ""
    signal clicked(real mouseX, real mouseY)

    readonly property color effectiveColor: danger ? Colors.error : accentColor

    width: compact ? actionRow.implicitWidth + Colors.spacingL * 2 : 140
    height: compact ? 28 : 36
    radius: Colors.radiusSmall
    color: Colors.withAlpha(effectiveColor, actionMouse.containsMouse ? 0.18 : 0.10)
    border.color: effectiveColor
    border.width: 1

    RowLayout {
        id: actionRow
        anchors.centerIn: parent
        spacing: Colors.spacingS

        Text {
            text: root.icon
            color: root.effectiveColor
            font.family: Colors.fontMono
            font.pixelSize: root.compact ? Colors.fontSizeSmall : Colors.fontSizeMedium
        }

        Text {
            text: root.label
            color: root.effectiveColor
            font.pixelSize: root.compact ? Colors.fontSizeSmall : Colors.fontSizeSmall
            font.weight: Font.Bold
        }
    }

    StateLayer {
        id: actionSL
        hovered: actionMouse.containsMouse
        pressed: actionMouse.pressed
        stateColor: root.effectiveColor
    }

    MouseArea {
        id: actionMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            actionSL.burst(mouse.x, mouse.y);
            root.clicked(mouse.x, mouse.y);
        }
    }

    Tooltip {
        text: root.tooltipText
        shortcut: root.tooltipShortcut
        shown: actionMouse.containsMouse && root.tooltipText !== ""
    }
}
