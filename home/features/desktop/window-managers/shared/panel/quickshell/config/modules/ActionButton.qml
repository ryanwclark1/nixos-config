import QtQuick
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root

  property string label: ""
  property var command: []
  property var action: null

  radius: Colors.radiusXXS
  height: 22
  width: Math.max(32, textLabel.implicitWidth + 16)
  color: btnMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.15) : Colors.withAlpha(Colors.surface, 0.6)
  border.color: btnMouse.containsMouse ? Colors.primary : Colors.border
  border.width: 1
  opacity: enabled ? 1.0 : 0.4
  scale: btnMouse.pressed ? 0.96 : 1.0
  Behavior on color { ColorAnimation { duration: Colors.durationFast } }
  Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }
  Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutBack } }

  // Inner highlight
  Rectangle {
    anchors.fill: parent
    anchors.margins: 1
    radius: parent.radius - 1
    color: "transparent"
    border.color: Colors.borderLight
    border.width: 1
    opacity: btnMouse.containsMouse ? 0.25 : 0.1
  }

  Text {
    id: textLabel
    anchors.centerIn: parent
    color: Colors.text
    font.pixelSize: Colors.fontSizeXS
    text: root.label
  }

  SharedWidgets.StateLayer {
    id: stateLayer
    hovered: btnMouse.containsMouse
    pressed: btnMouse.pressed
    disabled: !root.enabled
  }

  MouseArea {
    id: btnMouse
    anchors.fill: parent
    hoverEnabled: root.enabled
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: (mouse) => {
      if (!root.enabled) return;
      stateLayer.burst(mouse.x, mouse.y);
      if (root.action) root.action();
      else if (root.command && root.command.length > 0) Quickshell.execDetached(root.command);
    }
  }
}
