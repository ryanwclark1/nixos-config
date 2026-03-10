import Quickshell
import QtQuick
import "../../services"

Row {
  id: root

  property var state: null
  property color activeColor: Colors.highlight
  property color inactiveColor: Colors.surface
  property color textColor: Colors.fgMain

  spacing: 6

  Repeater {
    model: root.state ? root.state.workspaces : []
    delegate: Rectangle {
      radius: 6
      height: 20
      width: Math.max(22, label.implicitWidth + 10)
      color: (root.state && modelData.id === root.state.activeWorkspace) ? root.activeColor : root.inactiveColor

      Text {
        id: label
        anchors.centerIn: parent
        color: root.textColor
        font.pixelSize: 11
        text: modelData.name
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached([
          "hyprctl",
          "dispatch",
          "workspace",
          String(modelData.id)
        ])
      }
    }
  }
}
