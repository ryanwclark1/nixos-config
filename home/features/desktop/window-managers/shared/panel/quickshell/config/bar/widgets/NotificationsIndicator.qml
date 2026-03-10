import Quickshell
import QtQuick
import "../../services"

Rectangle {
  id: root

  radius: 6
  height: 20
  width: Math.max(34, label.implicitWidth + 12)
  color: Colors.surface

  Text {
    id: label
    anchors.centerIn: parent
    color: Colors.fgMain
    font.pixelSize: 10
    text: "Notif"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: Quickshell.execDetached([ "swaync-client", "-t" ])
  }
}
