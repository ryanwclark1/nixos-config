import QtQuick
import "."
import "../services"

// Material-style toggle switch.
// Usage:
//   ToggleSwitch {
//     checked: someModel.enabled
//     onToggled: someModel.enabled = !someModel.enabled
//   }
Item {
  id: root

  property bool checked: false
  signal toggled()

  implicitWidth: 44
  implicitHeight: 24

  // ── Track ──────────────────────────────────────────────────────────────
  Rectangle {
    id: track
    anchors.fill: parent
    radius: height / 2
    color: root.checked
      ? Colors.primary
      : Colors.borderLight
    border.color: root.checked ? "transparent" : Colors.border
    border.width: root.checked ? 0 : 1

    Behavior on color { ColorAnimation { duration: Colors.durationFast } }
    Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

    StateLayer {
      id: trackStateLayer
      hovered: mouse.containsMouse
      pressed: mouse.pressed
      stateColor: Colors.background
    }
  }

  // ── Thumb ───────────────────────────────────────────────────────────────
  Rectangle {
    id: thumb

    // Size: 20px checked, 18px unchecked — animate between
    property real thumbSize: root.checked ? 20 : 18

    width: thumbSize
    height: thumbSize
    radius: thumbSize / 2
    color: root.checked ? Colors.background : Colors.textSecondary
    anchors.verticalCenter: parent.verticalCenter

    // Horizontal spring: right edge at (44-2)=42 checked, left at 2 unchecked
    x: root.checked
      ? (root.width - width - 2)
      : 2

    Behavior on x {
      NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
    }
    Behavior on width {
      NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack }
    }
    Behavior on height {
      NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack }
    }
    Behavior on color { ColorAnimation { duration: Colors.durationFast } }

    // Press squish
    scale: mouse.pressed ? 0.88 : 1.0
    Behavior on scale { NumberAnimation { duration: Colors.durationSnap; easing.type: Easing.OutBack } }

    // ── Checkmark icon ────────────────────────────────────────────────────
    Text {
      anchors.centerIn: parent
      text: "󰄬"
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeXS
      color: Colors.primary
      opacity: root.checked ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
    }
  }

  // ── Interaction ─────────────────────────────────────────────────────────
  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
