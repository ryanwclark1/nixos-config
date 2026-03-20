import QtQuick
import "."
import "../services"

Rectangle {
  id: root

  property string text: ""
  property color chipColor: Colors.primary
  property bool interactive: false

  signal clicked()

  radius: Appearance.radiusCard
  color: Colors.withAlpha(root.chipColor, 0.16)
  border.color: Colors.withAlpha(root.chipColor, 0.25)
  border.width: 1
  implicitWidth: chipLabel.implicitWidth + 16
  implicitHeight: 24

  // Inner highlight
  Rectangle {
    anchors.fill: parent
    anchors.margins: 1
    radius: parent.radius - 1
    color: "transparent"
    border.color: Colors.withAlpha("#ffffff", 0.1)
    border.width: 1
    opacity: 0.5
  }

  Text {
    id: chipLabel
    anchors.centerIn: parent
    text: root.text
    color: root.chipColor
    font.pixelSize: Appearance.fontSizeXS
    font.weight: Font.Medium
  }

  StateLayer {
    id: stateLayer
    visible: root.interactive
    hovered: chipMouse.containsMouse
    pressed: chipMouse.pressed
    stateColor: root.chipColor
  }

  MouseArea {
    id: chipMouse
    anchors.fill: parent
    visible: root.interactive
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => { stateLayer.burst(mouse.x, mouse.y); root.clicked(); }
  }
}
