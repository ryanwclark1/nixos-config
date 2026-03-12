import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

Rectangle {
  id: root
  height: 24
  width: wsRow.width + 12
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
    spacing: Colors.spacingXS
    anchors.centerIn: parent

    Repeater {
      model: Hyprland.workspaces

      Item {
        id: wsContainer
        // Filter out special workspaces (negative IDs)
        visible: modelData.id > 0
        width: visible ? wsPill.width : 0
        height: visible ? wsRow.height : 0

        Rectangle {
          id: wsPill
          anchors.centerIn: parent

          width: modelData.focused ? 20 : 16
          height: 16
          radius: height / 2

          color: modelData.focused
            ? Colors.primary
            : (wsMouse.containsMouseFinal
              ? Colors.withAlpha(Colors.primary, 0.3)
              : Colors.withAlpha(Colors.fgDim, 0.15))

          Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 160 } }

          Text {
            anchors.centerIn: parent
            text: modelData.name
            color: modelData.focused ? Colors.bgMain : Colors.text
            font.pixelSize: 9
            font.weight: modelData.focused ? Font.Bold : Font.Medium
            opacity: modelData.focused ? 1.0 : 0.7

            Behavior on opacity { NumberAnimation { duration: 160 } }
          }
        }

        MouseArea {
          id: wsMouse
          anchors.centerIn: parent
          width: wsPill.width + 4
          height: wsRow.height
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton

          // Expose hover state for the pill color binding
          readonly property bool containsMouseFinal: containsMouse

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
