import QtQuick
import "../services"

Rectangle {
  property real highlightOpacity: 0.1
  property real hoveredOpacity: 0    // > 0 enables hover animation
  property bool hovered: false
  anchors.fill: parent; anchors.margins: 1
  radius: parent.radius > 0 ? parent.radius - 1 : 0
  color: "transparent"
  border.color: Colors.borderLight; border.width: 1
  opacity: (hoveredOpacity > 0 && hovered) ? hoveredOpacity : highlightOpacity
  Behavior on opacity { enabled: hoveredOpacity > 0; NumberAnimation { duration: Colors.durationFast } }
}
