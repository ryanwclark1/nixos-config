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
        
        onEntered: root.hoveredWorkspace = modelData
        onExited: root.hoveredWorkspace = null
      }

      // Previews still work the same
      PopupWindow {
        id: previewWindow
        visible: root.hoveredWorkspace === modelData && !modelData.active
        parentWindow: toplevel
        relativeX: wsButton.mapToItem(null, 0, 0).x - 150 + (wsButton.width / 2)
        relativeY: Config.barHeight + Config.barMargin + 8
        width: 300; height: 180; color: "transparent"

        Rectangle {
          anchors.fill: parent; color: Colors.bgGlass; border.color: modelData.hasFullscreen ? Colors.accent : Colors.primary; border.width: 2; radius: 12; clip: true

          opacity: previewWindow.visible ? 1.0 : 0.0; scale: previewWindow.visible ? 1.0 : 0.8
          Behavior on opacity { NumberAnimation { duration: 150 } }
          Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

          ColumnLayout {
            Rectangle {
              Layout.fillWidth: true; Layout.fillHeight: true; color: "#111111"; radius: 8; clip: true
              ScreencopyView {
                anchors.fill: parent
                captureSource: (modelData.monitor && modelData.monitor.wayland) ? modelData.monitor.wayland : null
                live: true
              }
              Rectangle { anchors.fill: parent; color: "#44000000" }
            }
            Text {
              text: "WORKSPACE " + modelData.name; color: Colors.fgMain; font.pixelSize: 9; font.weight: Font.Black; font.letterSpacing: 1; Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: 4
            }
          }
        }
      }
    }
  }
}
