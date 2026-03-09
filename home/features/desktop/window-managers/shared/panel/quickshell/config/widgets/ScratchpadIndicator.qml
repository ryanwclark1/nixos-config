import Quickshell
import QtQuick

Rectangle {
  id: root

  property var state: null

  radius: 6
  height: 20
  width: Math.max(40, label.implicitWidth + 12)
  color: root.state && root.state.specialWorkspaceActive ? "#3a3f44" : "#2a2d31"
  visible: root.state && root.state.specialWorkspace !== ""

  Text {
    id: label
    anchors.centerIn: parent
    color: "#e6e6e6"
    font.pixelSize: 10
    text: "Scratch"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Quickshell.execDetached([ "hyprctl", "dispatch", "togglespecialworkspace" ])
  }
}
