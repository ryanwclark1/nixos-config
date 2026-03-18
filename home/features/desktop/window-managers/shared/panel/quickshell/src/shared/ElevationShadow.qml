import QtQuick
import "."
import "../services"

Rectangle {
  id: root

  property int level: -1  // -1 = use legacy elevation prop
  property real elevation: level >= 0 ? [0, 1, 3, 6, 8, 12][Math.min(level, 5)] : 8
  property real shadowRadius: parent ? parent.radius || 0 : 0

  readonly property real _opacity: level >= 0
      ? [0, 0.12, 0.18, 0.22, 0.26, 0.30][Math.min(level, 5)] : 0.22
  readonly property real _yFactor: level >= 0
      ? [0, 0.4, 0.5, 0.6, 0.65, 0.7][Math.min(level, 5)] : 0.6

  z: -1
  anchors.fill: parent
  anchors.topMargin: elevation * _yFactor
  anchors.leftMargin: elevation * 0.15
  anchors.rightMargin: elevation * 0.15
  anchors.bottomMargin: -elevation * 0.2

  radius: shadowRadius
  color: "black"
  opacity: _opacity

  Behavior on elevation { Anim {} }
  Behavior on opacity { Anim {} }
}
