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
    onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "openDrun"])
  }
}
