import QtQuick
import "../../../shared"
import "../../../services"

Rectangle {
    id: root

    property bool active: false
    property string label: ""
    property bool compact: false

    implicitHeight: label !== "" ? (compact ? 20 : 24) : (compact ? 8 : 12)
    radius: Appearance.radiusXXS
    color: root.active ? Colors.primaryMarked : Colors.withAlpha(Colors.primary, 0.06)
    border.color: root.active ? Colors.primary : Colors.border
    border.width: 1
    opacity: root.active || root.label !== "" ? 1.0 : 0.0

    Behavior on opacity {
        enabled: !Colors.isTransitioning
        CAnim {}
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Appearance.spacingS
        anchors.verticalCenter: parent.verticalCenter
        visible: root.label !== ""
        text: root.label
        color: root.active ? Colors.primary : Colors.textSecondary
        font.pixelSize: Appearance.fontSizeXS
        font.weight: root.active ? Font.Medium : Font.Normal
        elide: Text.ElideRight
        width: Math.max(0, parent.width - Appearance.spacingS * 2)
    }
}
