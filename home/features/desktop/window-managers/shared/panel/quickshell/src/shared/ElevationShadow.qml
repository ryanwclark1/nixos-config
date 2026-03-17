import QtQuick
import "../services"

Rectangle {
  id: root

  property real elevation: 8
  property real shadowRadius: parent ? parent.radius || 0 : 0

  z: -1
  anchors.fill: parent
  anchors.topMargin: elevation * 0.6
  anchors.leftMargin: elevation * 0.15
  anchors.rightMargin: elevation * 0.15
  anchors.bottomMargin: -elevation * 0.2

  radius: shadowRadius
  color: "black"
  opacity: 0.22
}
