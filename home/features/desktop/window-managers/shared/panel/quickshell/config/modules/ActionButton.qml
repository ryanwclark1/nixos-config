import Quickshell
import QtQuick

Rectangle {
  id: root

  property string label: ""
  property var command: []

  radius: 6
  height: 20
  width: Math.max(28, textLabel.implicitWidth + 12)
  color: "#2a2d31"

  Text {
    id: textLabel
    anchors.centerIn: parent
    color: "#e6e6e6"
    font.pixelSize: 10
    text: root.label
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Quickshell.execDetached(root.command)
  }
}
