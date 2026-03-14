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
    id: logoBg
    anchors.fill: parent
    radius: Colors.radiusSmall
    color: "transparent"

    SharedWidgets.StateLayer {
      id: stateLayer
      hovered: mouseArea.containsMouse
      pressed: mouseArea.pressed
      stateColor: Colors.primary
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
    font.pixelSize: Colors.fontSizeXL
    visible: !logoImage.visible
  }

  scale: mouseArea.containsMouse ? 1.06 : 1.0
  layer.enabled: mouseArea.containsMouse
  Behavior on scale {
    NumberAnimation {
      duration: Colors.durationFast
      easing.type: Easing.OutCubic
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => { stateLayer.burst(mouse.x, mouse.y); Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "openDrun"]); }
  }

  SharedWidgets.BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: mouseArea.containsMouse
    text: root.tooltipText
  }
}
