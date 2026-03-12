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
    color: Colors.bgWidget
    radius: Colors.radiusMedium
    border.color: cardHover.hovered ? Colors.primary : Colors.border
    border.width: 1
    clip: true

    scale: cardHover.hovered ? root.hoverScale : 1.0
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on border.color { ColorAnimation { duration: 160 } }

    HoverHandler { id: cardHover }

    ColumnLayout {
      id: container
      anchors.fill: parent
      anchors.margins: root.pad
    }
  }
}
