import QtQuick
import "../services"

Item {
    id: root

    property color accentColor: Colors.primary
    property real parentRadius: Colors.radiusLarge
    property real thickness: Math.max(3, Math.min(6, Math.round(parentRadius * 0.22)))
    property real opacityValue: 0.78
    readonly property real _containerWidth: parent ? parent.width : 0
    readonly property real edgeInset: Math.max(6, Math.min(parentRadius * 0.9, _containerWidth * 0.18))
    readonly property real stripRadius: Math.max(1, Math.min(thickness / 2, parentRadius * 0.35))

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: edgeInset
    anchors.rightMargin: edgeInset
    anchors.topMargin: 1
    height: thickness

    Rectangle {
        anchors.fill: parent
        radius: root.stripRadius
        color: Colors.withAlpha(root.accentColor, 0.9)
        opacity: root.opacityValue
    }
}
