import Quickshell
import QtQuick
import "../services"

Rectangle {
  id: root

  property string label: ""
  property var command: []

  radius: 6
  height: 20
  width: Math.max(28, textLabel.implicitWidth + 12)
  color: Colors.surface

  Text {
    id: textLabel
    anchors.centerIn: parent
    color: Colors.fgMain
    font.pixelSize: 10
    text: root.label
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Quickshell.execDetached(root.command)
  }
}
