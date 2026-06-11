import QtQuick
import "../services"

Rectangle {
    id: root

    property alias text: label.text
    property real fontSize: Appearance.fontSizeMedium
    property bool hovered: buttonMouse.containsMouse
    signal clicked

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.onPressAction: root.clicked()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    implicitWidth: Math.max(96, label.implicitWidth + (Appearance.spacingM * 2))
    implicitHeight: 36
    radius: Appearance.radiusMedium
    color: hovered ? Colors.primaryFaint : Colors.cardSurface
    border.color: root.activeFocus ? Colors.primary : (hovered ? Colors.primaryRing : Colors.border)
    border.width: root.activeFocus ? 2 : 1

    Text {
        id: label
        anchors.centerIn: parent
        color: Colors.text
        font.pixelSize: root.fontSize
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.clicked();
        }
    }
}
