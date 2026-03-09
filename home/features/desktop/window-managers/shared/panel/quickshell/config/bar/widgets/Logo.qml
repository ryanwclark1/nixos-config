import QtQuick
import Quickshell

Item {
  width: 30
  height: 30

  Image {
    anchors.centerIn: parent
    sourceSize: Qt.size(20, 20)
    source: Quickshell.iconPath("nix-snowflake") || ""
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: console.log("Toggle dashboard") // Map to dashboard later
  }
}
