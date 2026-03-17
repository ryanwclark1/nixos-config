import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property bool active: false

  Layout.fillWidth: true
  implicitHeight: 44
  radius: Colors.radiusMedium
  color: root.active
    ? Colors.withAlpha(Colors.warning, 0.10)
    : Colors.cardSurface
  border.color: root.active ? Colors.withAlpha(Colors.warning, 0.3) : Colors.border
  border.width: 1
  Behavior on color { ColorAnimation { duration: Colors.durationNormal } }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Colors.spacingM
    spacing: Colors.paddingSmall

    Text {
      text: root.icon
      color: root.active ? Colors.warning : Colors.textDisabled
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeXL
    }

    Text {
      text: root.label
      color: Colors.text
      font.pixelSize: Colors.fontSizeMedium
      Layout.fillWidth: true
    }

    // Blinking active indicator
    Rectangle {
      width: 8; height: 8; radius: Colors.radiusXS
      color: root.active ? Colors.warning : Colors.textDisabled
      opacity: root.active ? 1.0 : 0.3
      Behavior on color { ColorAnimation { duration: Colors.durationNormal } }

      SequentialAnimation on opacity {
        running: root.active
        loops: Animation.Infinite
        NumberAnimation { from: 1.0; to: 0.3; duration: Colors.durationPulse; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.3; to: 1.0; duration: Colors.durationPulse; easing.type: Easing.InOutSine }
      }
    }

    Text {
      text: root.active ? "Active" : "Idle"
      color: root.active ? Colors.warning : Colors.textDisabled
      font.pixelSize: Colors.fontSizeSmall
      font.weight: Font.Medium
    }
  }
}
