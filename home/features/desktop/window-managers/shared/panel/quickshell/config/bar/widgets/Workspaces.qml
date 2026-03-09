import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland._Screencopy
import Quickshell.Wayland
import "../../services"

Row {
  id: root
  spacing: 12
  anchors.verticalCenter: parent.verticalCenter

  property var hoveredWorkspace: null

  Repeater {
    model: Hyprland.workspaces

    Rectangle {
      id: wsButton
      
      // Dynamic width for active workspace
      width: modelData.active ? 24 : 8
      height: 8
      radius: 4
      
      color: modelData.active ? Colors.primary : (modelData.hasFullscreen ? Colors.accent : (modelData.urgent ? Colors.error : Colors.fgDim))
      opacity: modelData.active ? 1.0 : 0.5
      
      // Smooth width transition
      Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 200 } }

      MouseArea {
        anchors.fill: parent
        anchors.margins: -4 // Larger click area
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
