import QtQuick
import QtQuick.Layouts
import "."
import "../services"

Item {
  id: root

  property real pad: Colors.paddingMedium
  property real hoverScale: 1.01

  default property alias content: container.data

  Layout.fillWidth: true

  // Pseudo-shadow
  Rectangle {
    z: -1
    x: 2; y: 2
    width: card.width; height: card.height
    radius: card.radius
    color: Colors.background
    opacity: 0.15
  }

  Rectangle {
    id: card
    anchors.fill: parent
    color: "transparent"
    radius: Colors.radiusMedium
    clip: true

    scale: cardHover.hovered ? root.hoverScale : 1.0
    Behavior on scale { NumberAnimation { id: cardScaleAnim; duration: Colors.durationSlow; easing.type: Easing.OutQuint } }
    layer.enabled: cardScaleAnim.running

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: parent.radius
      color: Colors.bgWidget
      border.color: cardHover.hovered ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

      gradient: SurfaceGradient {}
    }

    // Inner subtle highlight border
    InnerHighlight { highlightOpacity: 0.15; hoveredOpacity: 0.3; hovered: cardHover.hovered }

    HoverHandler { id: cardHover }

    ColumnLayout {
      id: container
      anchors.fill: parent
      anchors.margins: root.pad
    }
  }
}
