import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
  id: root
  property real value: 0        // 0.0 – 1.0
  property color barColor: Colors.primary

  Layout.fillWidth: true
  height: 4
  color: Colors.surface
  radius: 2

  Rectangle {
    width: parent.width * Math.max(0, Math.min(1, root.value))
    height: parent.height
    color: root.barColor
    radius: 2
  }
}
