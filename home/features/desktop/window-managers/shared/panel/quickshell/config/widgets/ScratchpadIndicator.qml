import Quickshell
import QtQuick
import "../services"

Rectangle {
  id: root

  property var state: null

  radius: 6
  height: 20
  width: Math.max(40, label.implicitWidth + 12)
  color: root.state && root.state.specialWorkspaceActive ? Colors.highlight : Colors.surface
  visible: root.state && root.state.specialWorkspace !== ""

  Text {
    id: label
    anchors.centerIn: parent
    color: Colors.fgMain
    font.pixelSize: 10
    text: "Scratch"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Quickshell.execDetached([ "hyprctl", "dispatch", "togglespecialworkspace", "scratchpad" ])
  }
}
