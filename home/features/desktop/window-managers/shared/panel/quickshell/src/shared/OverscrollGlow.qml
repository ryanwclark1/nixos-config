import QtQuick
import "../services"

// Translucent gradient indicators at Flickable edges during overscroll.
// Attach to any vertical Flickable for visual feedback at bounds.
Item {
  id: root

  property Flickable flickable: null
  property color glowColor: Colors.primary
  readonly property real maxHeight: 60
  readonly property real verticalOvershootSafe: flickable ? flickable.verticalOvershoot : 0

  x: flickable ? flickable.x : 0
  y: flickable ? flickable.y : 0
  width: flickable ? flickable.width : 0
  height: flickable ? flickable.height : 0
  visible: flickable !== null

  // Top glow — visible when pulling down past the top
  Rectangle {
    id: topGlow
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: Math.min(root.maxHeight, Math.abs(root.verticalOvershootSafe) * 0.6)
    visible: root.verticalOvershootSafe < 0
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
    height: Math.min(root.maxHeight, Math.abs(root.verticalOvershootSafe) * 0.6)
    visible: root.verticalOvershootSafe > 0
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Colors.withAlpha(root.glowColor, 0.15) }
    }
  }
}
