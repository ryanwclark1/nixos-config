import QtQuick
import "../services"

MouseArea {
  id: root

  property string tooltipText: ""
  property var anchorWindow: null
  property color normalColor: Colors.bgWidget
  property color hoverColor: Colors.highlightLight
  property real hoverScale: 1.04
  property real horizontalPadding: 8

  default property alias content: contentContainer.data

  height: 28
  width: contentContainer.childrenRect.width + horizontalPadding * 2
  hoverEnabled: true

  scale: containsMouse ? hoverScale : 1.0
  Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

  Rectangle {
    id: bg
    anchors.fill: parent
    color: root.containsMouse ? root.hoverColor : root.normalColor
    radius: height / 2
    Behavior on color { ColorAnimation { duration: 160 } }
  }

  Item {
    id: contentContainer
    anchors.centerIn: parent
    width: childrenRect.width
    height: childrenRect.height
  }

  BarTooltip {
    anchorItem: root
    anchorWindow: root.anchorWindow
    hovered: root.containsMouse
    text: root.tooltipText
  }
}
