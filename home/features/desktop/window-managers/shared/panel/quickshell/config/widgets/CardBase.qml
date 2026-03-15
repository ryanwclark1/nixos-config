import QtQuick
import QtQuick.Layouts
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
    Behavior on scale { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutQuint } }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: parent.radius
      color: Colors.bgWidget
      border.color: cardHover.hovered ? Colors.primary : Colors.border
      border.width: 1
      Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
        GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
      }
    }

    // Inner subtle highlight border
    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.color: Colors.borderLight
      border.width: 1
      opacity: cardHover.hovered ? 0.3 : 0.15
      Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
    }

    HoverHandler { id: cardHover }

    ColumnLayout {
      id: container
      anchors.fill: parent
      anchors.margins: root.pad
    }
  }
}
