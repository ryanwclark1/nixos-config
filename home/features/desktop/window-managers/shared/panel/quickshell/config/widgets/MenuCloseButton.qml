import QtQuick
import "../services"

Rectangle {
  id: root

  signal clicked()

  width: 30
  height: 30
  radius: height / 2
  color: "transparent"

  Text {
    anchors.centerIn: parent
    text: "󰅖"
    color: Colors.textSecondary
    font.family: Colors.fontMono
    font.pixelSize: Colors.fontSizeLarge
  }

  StateLayer {
    id: stateLayer
    hovered: closeHover.containsMouse
    pressed: closeHover.pressed
  }

  MouseArea {
    id: closeHover
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => { stateLayer.burst(mouse.x, mouse.y); root.clicked(); }
  }
}
