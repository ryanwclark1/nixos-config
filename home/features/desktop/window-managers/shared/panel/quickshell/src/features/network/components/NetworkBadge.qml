import QtQuick
import "../../../shared"
import "../../../services"

Rectangle {
    id: root

    required property string text
    required property color badgeColor
    required property color textColor
    property color borderColor: Colors.withAlpha(badgeColor, 0.35)
    property int fontWeight: Font.DemiBold
    property real fontScale: 1.0
    property real iconScale: 1.0

    radius: Appearance.radiusXS * iconScale
    color: Colors.withAlpha(badgeColor, 0.14)
    border.color: root.borderColor
    border.width: 1
    implicitHeight: 18 * iconScale
    implicitWidth: badgeLabel.implicitWidth + 10 * iconScale
    anchors.verticalCenter: parent.verticalCenter

    Text {
        id: badgeLabel
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.pixelSize: Appearance.fontSizeXS * root.fontScale
        font.weight: root.fontWeight
    }
}
