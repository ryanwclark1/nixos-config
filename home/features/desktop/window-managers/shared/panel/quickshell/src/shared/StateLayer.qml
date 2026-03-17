import QtQuick
import "."
import "../services"

// Transparent overlay providing consistent hover/press/disabled visual states.
// Place inside any interactive component and bind hovered/pressed/disabled.
// Uses opacity blending of stateColor — never changes the parent's background.
Rectangle {
  id: root

  property bool hovered: false
  property bool pressed: false
  property bool disabled: false
  property color stateColor: Colors.text
  property bool enableRipple: true

  anchors.fill: parent
  radius: parent && parent.radius !== undefined ? parent.radius : 0
  color: Qt.rgba(stateColor.r, stateColor.g, stateColor.b,
    disabled ? 0 : pressed ? 0.12 : hovered ? 0.08 : 0)

  Behavior on color { ColorAnimation { duration: Colors.durationFast } }

  // Integrated click ripple (triggered externally via burst())
  ClickRipple {
    id: ripple
    color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.12)
    visible: root.enableRipple && !root.disabled
  }

  function burst(x, y) {
    if (!disabled && enableRipple) ripple.burst(x, y);
  }
}
