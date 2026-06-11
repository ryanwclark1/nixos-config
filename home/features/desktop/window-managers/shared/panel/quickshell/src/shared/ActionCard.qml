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

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.description: root.tooltipText || root.label
    Accessible.onPressAction: root.clicked(width / 2, height / 2)

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            actionSL.burst(width / 2, height / 2);
            root.clicked(width / 2, height / 2);
            event.accepted = true;
        }
    }

    readonly property color effectiveColor: danger ? Colors.error : accentColor

    width: compact ? actionRow.implicitWidth + Appearance.spacingL * 2 : 140
    height: compact ? 28 : 36
    radius: Appearance.radiusSmall
    color: Colors.withAlpha(effectiveColor, actionMouse.containsMouse ? 0.18 : 0.10)
    border.color: root.activeFocus ? Colors.primary : effectiveColor
    border.width: root.activeFocus ? 2 : 1

    RowLayout {
        id: actionRow
        anchors.centerIn: parent
        spacing: Appearance.spacingS

        Loader {
            sourceComponent: String(root.icon).endsWith(".svg") ? _svgIcon : _nerdIcon
        }
        Component {
            id: _svgIcon
            SvgIcon { source: root.icon; color: root.effectiveColor; size: root.compact ? Appearance.fontSizeSmall : Appearance.fontSizeMedium }
        }
        Component {
            id: _nerdIcon
            Text {
                text: root.icon
                color: root.effectiveColor
                font.family: Appearance.fontMono
                font.pixelSize: root.compact ? Appearance.fontSizeSmall : Appearance.fontSizeMedium
            }
        }

        Text {
            text: root.label
            color: root.effectiveColor
            font.pixelSize: root.compact ? Appearance.fontSizeSmall : Appearance.fontSizeSmall
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
        hoverPoint: Qt.point(actionMouse.mouseX, actionMouse.mouseY)
        shown: actionMouse.containsMouse && root.tooltipText !== ""
    }
}
