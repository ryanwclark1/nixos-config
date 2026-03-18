import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
  id: root
  property real value: 0        // 0.0 – 1.0
  property color barColor: Colors.primary
  readonly property real safeRadius: typeof Colors.radiusMicro === "number" ? Colors.radiusMicro : 0

  Layout.fillWidth: true
  height: 4
  color: Colors.cardSurface
  radius: root.safeRadius
  border.color: Colors.withAlpha("#000000", 0.1)
  border.width: 1

  Rectangle {
    width: parent.width * Math.max(0, Math.min(1, root.value))
    height: parent.height
    color: root.barColor
    radius: root.safeRadius
    Behavior on width { Anim {} }

    // Subtle highlight on the progress bar itself
    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius > 0 ? parent.radius - 1 : 0
      color: "transparent"
      border.color: Colors.withAlpha("#ffffff", 0.15)
      border.width: 1
    }
  }
}
