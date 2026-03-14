import QtQuick
import "../services"

Rectangle {
  id: root

  property string text: ""
  property color chipColor: Colors.primary
  property bool interactive: false

  signal clicked()

  radius: Colors.radiusCard
  color: Colors.withAlpha(root.chipColor, 0.16)
  implicitWidth: chipLabel.implicitWidth + 16
  implicitHeight: 24

  Text {
    id: chipLabel
    anchors.centerIn: parent
    text: root.text
    color: root.chipColor
    font.pixelSize: Colors.fontSizeXS
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
