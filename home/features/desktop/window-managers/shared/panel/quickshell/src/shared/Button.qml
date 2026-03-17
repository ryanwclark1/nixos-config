import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias text: label.text
    property real fontSize: Colors.fontSizeMedium
    property bool hovered: buttonMouse.containsMouse
    signal clicked

    implicitWidth: Math.max(96, label.implicitWidth + (Colors.spacingM * 2))
    implicitHeight: 36
    radius: Colors.radiusMedium
    color: hovered ? Colors.primaryFaint : Colors.cardSurface
    border.color: hovered ? Colors.primaryRing : Colors.border
    border.width: 1

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
        onClicked: root.clicked()
    }
}
