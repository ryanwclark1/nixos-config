import QtQuick
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets

Item {
  id: root
  width: 30
  height: 30

  property var anchorWindow: null
  property string tooltipText: "Applications"

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: mouseArea.containsMouse ? Colors.highlightLight : "transparent"

    Behavior on color {
      ColorAnimation {
        duration: 160
      }
    }
  }

  Image {
    id: logoImage
    anchors.centerIn: parent
    sourceSize: Qt.size(20, 20)
    source: Quickshell.iconPath("nix-snowflake") || ""
    visible: status === Image.Ready
  }

  Text {
    anchors.centerIn: parent
    text: "󱄅"
    color: Colors.primary
    font.family: Colors.fontMono
    font.pixelSize: 18
    visible: !logoImage.visible
  }

  scale: mouseArea.containsMouse ? 1.06 : 1.0
  Behavior on scale {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "openDrun"])
  }

  SharedWidgets.BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: mouseArea.containsMouse
    text: root.tooltipText
  }
}
