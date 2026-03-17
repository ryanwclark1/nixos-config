import QtQuick
import "../services"

Rectangle {
    id: root

    required property string text
    required property color badgeColor
    required property color textColor
    property color borderColor: Colors.withAlpha(badgeColor, 0.35)
    property int fontWeight: Font.DemiBold

    radius: Colors.radiusXS
    color: Colors.withAlpha(badgeColor, 0.14)
    border.color: root.borderColor
    border.width: 1
    implicitHeight: 18
    implicitWidth: badgeLabel.implicitWidth + 10
    anchors.verticalCenter: parent.verticalCenter

    Text {
        id: badgeLabel
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.pixelSize: Colors.fontSizeXS
        font.weight: root.fontWeight
    }
}
