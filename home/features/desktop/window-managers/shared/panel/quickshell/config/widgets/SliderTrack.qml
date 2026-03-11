import QtQuick
import "../services"

Rectangle {
  id: root

  property real value: 0
  property bool muted: false
  property string icon: ""
  property string mutedIcon: ""
  property color activeColor: Colors.primary
  property color mutedColor: Colors.error
  property real minThumbWidth: 28
  property real minVisibleValue: 0.1

  signal sliderMoved(real newValue)

  height: 28
  color: sliderMouse.containsMouse ? Colors.surface : Colors.bgWidget
  radius: 14
  border.color: sliderMouse.containsMouse ? (root.muted ? root.mutedColor : root.activeColor) : Colors.border
  border.width: 1

  Behavior on color { ColorAnimation { duration: 150 } }
  Behavior on border.color { ColorAnimation { duration: 150 } }

  Rectangle {
    height: parent.height
    width: Math.max(root.minThumbWidth, parent.width * (root.muted ? 0 : root.value))
    radius: 14
    color: root.muted ? root.mutedColor : (sliderMouse.containsMouse ? Qt.darker(root.activeColor, 1.08) : root.activeColor)
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
      anchors.centerIn: parent
      text: root.muted ? root.mutedIcon : root.icon
      color: Colors.background
      font.family: Colors.fontMono
      font.pixelSize: 12
      visible: root.muted || root.value > root.minVisibleValue
    }
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    hoverEnabled: true
    onPressed: (mouse) => { root.sliderMoved(Math.max(0, Math.min(1.0, mouse.x / width))); }
    onPositionChanged: (mouse) => { if (pressed) root.sliderMoved(Math.max(0, Math.min(1.0, mouse.x / width))); }
  }
}
