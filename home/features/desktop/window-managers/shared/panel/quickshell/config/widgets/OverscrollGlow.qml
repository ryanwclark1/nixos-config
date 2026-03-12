import QtQuick
import "../services"

// Translucent gradient indicators at Flickable edges during overscroll.
// Attach to any vertical Flickable for visual feedback at bounds.
Item {
  id: root

  property Flickable flickable
  property color glowColor: Colors.primary
  readonly property real maxHeight: 60

  anchors.fill: flickable

  // Top glow — visible when pulling down past the top
  Rectangle {
    id: topGlow
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: Math.min(root.maxHeight, Math.abs(root.flickable.verticalOvershoot) * 0.6)
    visible: root.flickable.verticalOvershoot < 0
    gradient: Gradient {
      GradientStop { position: 0.0; color: Colors.withAlpha(root.glowColor, 0.15) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }

  // Bottom glow — visible when pulling up past the bottom
  Rectangle {
    id: bottomGlow
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Math.min(root.maxHeight, Math.abs(root.flickable.verticalOvershoot) * 0.6)
    visible: root.flickable.verticalOvershoot > 0
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Colors.withAlpha(root.glowColor, 0.15) }
    }
  }
}
