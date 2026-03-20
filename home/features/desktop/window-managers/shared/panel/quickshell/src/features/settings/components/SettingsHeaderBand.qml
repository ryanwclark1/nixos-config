import QtQuick
import "../../../services"

Item {
    id: root

    property color accentColor: Colors.primary
    property real parentRadius: Appearance.radiusLarge
    property real bandHeight: 0
    property real dividerY: bandHeight
    property bool showDivider: false
    property real surfaceStrength: 1.0
    property real accentStrength: 1.0
    property color dividerColor: Colors.withAlpha(accentColor, 0.16)

    readonly property real inset: 1
    readonly property real washRadius: Math.max(0, parentRadius - inset)
    readonly property real resolvedHeight: Math.max(1, height)
    readonly property real resolvedBandHeight: Math.max(Appearance.spacingL * 2, bandHeight)
    readonly property real bandDepth: Math.max(0.16, Math.min(0.72, resolvedBandHeight / resolvedHeight))
    readonly property real plateauEnd: Math.min(0.58, Math.max(0.14, bandDepth * 0.58))
    readonly property real taperStart: Math.min(0.84, Math.max(plateauEnd + 0.05, bandDepth * 0.86))
    readonly property real taperEnd: Math.min(0.96, Math.max(taperStart + 0.06, bandDepth + 0.08))
    readonly property real surfaceLeadAlpha: Math.min(0.22, 0.14 * surfaceStrength + 0.04)
    readonly property real surfaceMidAlpha: Math.min(0.12, 0.08 * surfaceStrength + 0.02)
    readonly property real accentLeadAlpha: Math.min(0.18, 0.11 * accentStrength + 0.03)
    readonly property real accentMidAlpha: Math.min(0.12, 0.07 * accentStrength + 0.015)
    readonly property real accentTailAlpha: Math.min(0.05, 0.03 * accentStrength + 0.01)

    anchors.fill: parent
    visible: root.bandHeight > 0

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.inset
        radius: root.washRadius
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Colors.withAlpha(Colors.surface, root.surfaceLeadAlpha) }
            GradientStop { position: root.plateauEnd; color: Colors.withAlpha(Colors.surface, root.surfaceMidAlpha) }
            GradientStop { position: root.taperEnd; color: Colors.withAlpha(Colors.surface, 0.0) }
            GradientStop { position: 1.0; color: Colors.withAlpha(Colors.surface, 0.0) }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.inset
        radius: root.washRadius
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Colors.withAlpha(root.accentColor, root.accentLeadAlpha) }
            GradientStop { position: root.plateauEnd; color: Colors.withAlpha(root.accentColor, root.accentMidAlpha) }
            GradientStop { position: root.taperStart; color: Colors.withAlpha(root.accentColor, root.accentTailAlpha) }
            GradientStop { position: root.taperEnd; color: Colors.withAlpha(root.accentColor, 0.0) }
            GradientStop { position: 1.0; color: Colors.withAlpha(root.accentColor, 0.0) }
        }
    }

    Rectangle {
        visible: root.showDivider
        anchors.left: parent.left
        anchors.right: parent.right
        y: Math.max(root.inset, Math.min(root.height - height, root.dividerY - height * 0.5))
        height: 1
        color: root.dividerColor
    }
}
