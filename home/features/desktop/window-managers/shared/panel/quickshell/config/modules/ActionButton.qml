import QtQuick
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root

  property string label: ""
  property var command: []
  property var action: null

  radius: 6
  height: 20
  width: Math.max(28, textLabel.implicitWidth + 12)
  color: Colors.surface
  opacity: enabled ? 1.0 : 0.4

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
