import QtQuick
import Quickshell
import "../services"

Rectangle {
  id: root

  property string toggleMethod

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
    onClicked: (mouse) => { stateLayer.burst(mouse.x, mouse.y); Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", root.toggleMethod]); }
  }
}
