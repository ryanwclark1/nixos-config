import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

Rectangle {
  id: root
  height: 24
  width: wsRow.width + 16
  radius: height / 2
  color: Colors.bgWidget
  anchors.verticalCenter: parent.verticalCenter

  property var anchorWindow: null

  scale: rootMouse.containsMouse ? 1.03 : 1.0
  Behavior on scale {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }
  Behavior on color {
    ColorAnimation {
      duration: 160
    }
  }

  // rootMouse must be declared before wsRow so it sits behind
  // the workspace items in z-order and doesn't intercept events
  MouseArea {
    id: rootMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }

  Row {
    id: wsRow
    spacing: 8
    anchors.centerIn: parent

    Repeater {
      model: Hyprland.workspaces

      Item {
        id: wsContainer
        width: wsButton.width
        height: wsRow.height

        Rectangle {
          id: wsButton
          anchors.centerIn: parent

          // focused = on the currently focused monitor
          // active = visible on any monitor (secondary highlight)
          width: modelData.focused ? 20 : (modelData.active ? 14 : 8)
          height: 8
          radius: 4

          color: modelData.focused ? Colors.primary : (modelData.active ? Colors.accent : (modelData.urgent ? Colors.error : Colors.fgDim))
          opacity: modelData.focused ? 1.0 : (modelData.active ? 0.8 : 0.6)

          Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 200 } }
        }

        MouseArea {
          id: wsMouse
          anchors.centerIn: parent
          width: parent.width + 8
          height: wsRow.height
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton

          onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) modelData.activate();
            else if (mouse.button === Qt.MiddleButton) {
              Quickshell.execDetached(["sh", "-c", "hyprctl clients -j | jq -r '.[] | select(.workspace.id == " + modelData.id + ") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"]);
            }
          }
        }
      }
    }
  }
}
