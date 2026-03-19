import QtQuick
import "../services"

Item {
    id: root

    property color accentColor: Colors.primary
    property real parentRadius: Colors.radiusLarge
    property real opacityValue: 0.78
    readonly property real inset: 1
    readonly property real washRadius: Math.max(0, parentRadius - inset)
    readonly property real fadeDepth: Math.max(0.2, Math.min(0.34, 0.18 + (parentRadius / 140)))
    readonly property real leadAlpha: Math.min(0.22, 0.18 * opacityValue + 0.04)
    readonly property real midAlpha: Math.min(0.14, 0.11 * opacityValue + 0.015)
    readonly property real tailAlpha: Math.min(0.06, 0.04 * opacityValue + 0.01)

    anchors.fill: parent
    anchors.margins: inset

    Rectangle {
        anchors.fill: parent
        radius: root.washRadius
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Colors.withAlpha(root.accentColor, root.leadAlpha) }
            GradientStop { position: root.fadeDepth * 0.38; color: Colors.withAlpha(root.accentColor, root.midAlpha) }
            GradientStop { position: root.fadeDepth; color: Colors.withAlpha(root.accentColor, root.tailAlpha) }
            GradientStop { position: Math.min(1.0, root.fadeDepth + 0.12); color: Colors.withAlpha(root.accentColor, 0.0) }
            GradientStop { position: 1.0; color: Colors.withAlpha(root.accentColor, 0.0) }
        }
    }
}
