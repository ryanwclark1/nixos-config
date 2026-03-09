import Quickshell
import QtQuick

Rectangle {
  id: root

  radius: 6
  height: 20
  width: Math.max(34, label.implicitWidth + 12)
  color: "#2a2d31"

  Text {
    id: label
    anchors.centerIn: parent
    color: "#e6e6e6"
    font.pixelSize: 10
    text: "Notif"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Quickshell.execDetached([ "swaync-client", "-t" ])
  }
}
