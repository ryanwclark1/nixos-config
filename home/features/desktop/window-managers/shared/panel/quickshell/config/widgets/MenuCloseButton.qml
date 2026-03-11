import QtQuick
import Quickshell
import "../services"

Rectangle {
  id: root

  property string toggleMethod

  width: 30
  height: 30
  radius: 15
  color: closeHover.containsMouse ? Colors.highlightLight : "transparent"

  Text {
    anchors.centerIn: parent
    text: "󰅖"
    color: Colors.textSecondary
    font.family: Colors.fontMono
    font.pixelSize: 16
  }

  MouseArea {
    id: closeHover
    anchors.fill: parent
    hoverEnabled: true
    onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", root.toggleMethod])
  }
}
