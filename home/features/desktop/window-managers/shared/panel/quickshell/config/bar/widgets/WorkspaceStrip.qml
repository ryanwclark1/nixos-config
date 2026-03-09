import Quickshell
import QtQuick

Row {
  id: root

  property var state: null
  property color activeColor: "#3a3f44"
  property color inactiveColor: "#2a2d31"
  property color textColor: "#e6e6e6"

  spacing: 6

  Repeater {
    model: root.state ? root.state.workspaces : []
    delegate: Rectangle {
      radius: 6
      height: 20
      width: Math.max(22, label.implicitWidth + 10)
      color: modelData.id === root.state.activeWorkspace ? root.activeColor : root.inactiveColor

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
