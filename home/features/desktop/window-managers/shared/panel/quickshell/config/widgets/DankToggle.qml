import QtQuick
import "../services"

// Material-style toggle switch.
// Usage:
//   DankToggle {
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
      : Colors.withAlpha(Colors.text, 0.12)
    border.color: root.checked ? "transparent" : Colors.border
    border.width: root.checked ? 0 : 1

    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on border.color { ColorAnimation { duration: 160 } }

    StateLayer {
      id: trackStateLayer
      hovered: mouse.containsMouse
      pressed: mouse.pressed
      stateColor: "#ffffff"
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
    color: root.checked ? "#ffffff" : Colors.fgSecondary
    anchors.verticalCenter: parent.verticalCenter

    // Horizontal spring: right edge at (44-2)=42 checked, left at 2 unchecked
    x: root.checked
      ? (root.width - width - 2)
      : 2

    Behavior on x {
      NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
    }
    Behavior on width {
      NumberAnimation { duration: 200; easing.type: Easing.OutBack }
    }
    Behavior on height {
      NumberAnimation { duration: 200; easing.type: Easing.OutBack }
    }
    Behavior on color { ColorAnimation { duration: 160 } }

    // Press squish
    scale: mouse.pressed ? 0.88 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }

    // ── Checkmark icon ────────────────────────────────────────────────────
    Text {
      anchors.centerIn: parent
      text: "󰄬"
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeXS
      color: Colors.primary
      opacity: root.checked ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { duration: 160 } }
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
