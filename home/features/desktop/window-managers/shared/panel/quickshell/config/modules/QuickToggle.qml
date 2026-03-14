import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property bool active: false
  signal clicked()

  Layout.fillWidth: true
  Layout.preferredHeight: 60
  radius: Colors.radiusMedium
  color: active ? Colors.primary : Colors.bgWidget
  border.color: active ? Colors.primary : Colors.border
  border.width: 1

  opacity: enabled ? 1.0 : 0.4
  scale: toggleMouse.pressed ? 0.95 : 1.0
  Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutBack } }
  Behavior on color { ColorAnimation { duration: Colors.durationFast } }
  Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Colors.spacingM
    spacing: Colors.spacingM

    Rectangle {
      id: iconCircle
      width: 36; height: 36
      radius: height / 2
      color: active ? Colors.withAlpha(Colors.text, 0.2) : Colors.surface
      scale: toggleMouse.containsMouse ? 1.1 : 1.0
      Behavior on scale { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack } }

      Text {
        anchors.centerIn: parent
        text: root.icon
        color: active ? Colors.text : Colors.primary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeXL
      }
    }

    Column {
      Layout.fillWidth: true
      spacing: Colors.spacingXXS
      Text {
        text: root.label
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.Bold
        elide: Text.ElideRight
      }
      Text {
        text: active ? "On" : "Off"
        color: active ? Colors.withAlpha(Colors.text, 0.7) : Colors.fgSecondary
        font.pixelSize: Colors.fontSizeXS
      }
    }
  }

  SharedWidgets.StateLayer {
    id: stateLayer
    hovered: toggleMouse.containsMouse
    pressed: toggleMouse.pressed
    disabled: !root.enabled
  }

  MouseArea {
    id: toggleMouse
    anchors.fill: parent
    hoverEnabled: root.enabled
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: (mouse) => { if (!root.enabled) return; stateLayer.burst(mouse.x, mouse.y); root.clicked(); }
  }
}
