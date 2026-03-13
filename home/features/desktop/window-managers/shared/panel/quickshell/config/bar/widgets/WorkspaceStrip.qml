import Quickshell
import QtQuick
import "../../services"

Row {
  id: root

  property var state: null
  property color activeColor: Colors.highlight
  property color inactiveColor: Colors.surface
  property color textColor: Colors.text

  spacing: 6

  Repeater {
    model: root.state ? root.state.workspaces : []
    delegate: Rectangle {
      id: wsPill

      readonly property bool isActive: root.state && modelData.id === root.state.activeWorkspace
      readonly property bool isUrgent: !isActive && !!modelData.urgent

      radius: 6
      height: 20
      width: Math.max(22, label.implicitWidth + 10)
      color: isActive ? root.activeColor : root.inactiveColor

      // Smooth color transition for normal active/inactive state changes.
      // Disabled while the urgent animation is running so it doesn't fight the
      // SequentialAnimation below.
      Behavior on color {
        enabled: !wsPill.isUrgent
        ColorAnimation { duration: 160 }
      }

      // Urgent blink: cycle between Colors.error and Colors.warning while
      // the workspace has an urgent window AND is not the focused workspace.
      SequentialAnimation on color {
        id: urgentAnim
        running: wsPill.isUrgent
        loops: Animation.Infinite
        ColorAnimation { to: Colors.error;   duration: 600; easing.type: Easing.InOutSine }
        ColorAnimation { to: Colors.warning; duration: 600; easing.type: Easing.InOutSine }
      }

      Text {
        id: label
        anchors.centerIn: parent
        color: root.textColor
        font.pixelSize: Colors.fontSizeSmall
        text: modelData.name
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: CompositorAdapter.focusWorkspace(modelData.id)
      }
    }
  }
}
