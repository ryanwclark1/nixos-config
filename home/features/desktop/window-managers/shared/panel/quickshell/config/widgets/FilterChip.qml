import QtQuick
import "../services"

// Interactive chip with selection state, hover, and ripple feedback.
// Use for toggle chips (On/Off), mode selectors, and filter options.
Rectangle {
  id: root

  property string label: ""
  property string icon: ""
  property bool selected: false
  property bool enabled: true
  signal clicked()

  implicitWidth: row.implicitWidth + 24
  implicitHeight: 32
  radius: height / 2
  color: selected ? Colors.highlight : Colors.bgWidget
  border.color: selected ? Colors.primary : Colors.border
  border.width: 1
  opacity: enabled ? 1.0 : 0.4

  Behavior on color { ColorAnimation { duration: 160 } }
  Behavior on border.color { ColorAnimation { duration: 160 } }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 5

    // Checkmark when selected
    Text {
      text: "󰄬"
      color: Colors.primary
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeSmall
      visible: root.selected && root.icon === ""
      anchors.verticalCenter: parent.verticalCenter
    }

    // Leading icon
    Text {
      text: root.icon
      color: root.selected ? Colors.primary : Colors.textSecondary
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeMedium
      visible: root.icon !== ""
      anchors.verticalCenter: parent.verticalCenter
      Behavior on color { ColorAnimation { duration: 160 } }
    }

    Text {
      text: root.label
      color: root.selected ? Colors.primary : Colors.text
      font.pixelSize: Colors.fontSizeSmall
      font.weight: root.selected ? Font.DemiBold : Font.Normal
      anchors.verticalCenter: parent.verticalCenter
      Behavior on color { ColorAnimation { duration: 160 } }
    }
  }

  StateLayer {
    id: stateLayer
    hovered: chipMouse.containsMouse
    pressed: chipMouse.pressed
    disabled: !root.enabled
  }

  MouseArea {
    id: chipMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: {
      if (root.enabled) {
        stateLayer.burst(mouseX, mouseY);
        root.clicked();
      }
    }
  }
}
