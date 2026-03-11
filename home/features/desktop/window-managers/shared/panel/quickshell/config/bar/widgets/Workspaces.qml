import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"
import "../../widgets" as SharedWidgets

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

          // Dynamic width for active workspace
          width: modelData.active ? 20 : 8
          height: 8
          radius: 4

          color: modelData.active ? Colors.primary : (modelData.hasFullscreen ? Colors.accent : (modelData.urgent ? Colors.error : Colors.fgDim))
          opacity: modelData.active ? 1.0 : 0.6

          // Smooth width transition
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

        SharedWidgets.BarTooltip {
          anchorItem: wsContainer
          anchorWindow: root.anchorWindow
          hovered: wsMouse.containsMouse
          text: (modelData.name ? "Workspace " + modelData.name : "Workspace " + modelData.id) + (modelData.urgent ? " (urgent)" : "")
          yOffset: 10
        }
      }
    }
  }

  MouseArea {
    id: rootMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    propagateComposedEvents: true
  }

}
