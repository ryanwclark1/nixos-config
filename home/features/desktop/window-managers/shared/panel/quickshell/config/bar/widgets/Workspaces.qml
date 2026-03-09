import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland._Screencopy
import Quickshell.Wayland

Row {
  id: root
  spacing: 8
  anchors.verticalCenter: parent.verticalCenter

  property var hoveredWorkspace: null

  Repeater {
    model: Hyprland.workspaces

    Rectangle {
      id: wsButton
      width: 28
      height: 28
      radius: 6
      color: modelData.active ? "#4caf50" : (modelData.hasFullscreen ? "#ff9800" : (modelData.urgent ? "#f44336" : "#1affffff"))
      border.color: modelData.active ? "#4caf50" : "#33ffffff"
      border.width: 1

      Text {
        anchors.centerIn: parent
        text: modelData.name
        color: modelData.active ? "#ffffff" : "#e6e6e6"
        font.pixelSize: 12
        font.weight: modelData.active ? Font.Bold : Font.Normal
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        
        onClicked: (mouse) => {
          if (mouse.button === Qt.LeftButton) {
            modelData.activate();
          } else if (mouse.button === Qt.MiddleButton) {
            // Close all windows on this workspace
            Quickshell.execDetached(["sh", "-c", "hyprctl clients -j | jq -r '.[] | select(.workspace.id == " + modelData.id + ") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"]);
          }
        }
        
        onWheel: (wheel) => {
          if (wheel.angleDelta.y > 0) {
            Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e-1"]);
          } else {
            Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e+1"]);
          }
        }
        
        onEntered: root.hoveredWorkspace = modelData
        onExited: root.hoveredWorkspace = null
      }

      // Live Preview Popup
      PopupWindow {
        id: previewWindow
        visible: root.hoveredWorkspace === modelData && !modelData.active

        anchor.window: toplevel
        anchor.rect.x: wsButton.x + (wsButton.width / 2) - 150
        anchor.rect.y: 40
        
        implicitWidth: 300
        implicitHeight: 180
        color: "transparent"

        Rectangle {
          anchors.fill: parent
          color: "#cc101014"
          border.color: modelData.hasFullscreen ? "#ff9800" : "#4caf50"
          border.width: 2
          radius: 12
          clip: true

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4
            
            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              color: "#111111"
              radius: 8
              clip: true
              
              ScreencopyView {
                anchors.fill: parent
                captureSource: (modelData.monitor && modelData.monitor.wayland) ? modelData.monitor.wayland : null
                live: true
              }
              
              Rectangle {
                anchors.fill: parent
                color: "#44000000"
              }

              // Middle-click on preview to close focused window on that workspace
              MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                onClicked: {
                   Quickshell.execDetached(["sh", "-c", "hyprctl activewindow -j | jq -r '.address' | xargs -I {} hyprctl dispatch closewindow address:{}"]);
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignHCenter
              Layout.bottomMargin: 4
              spacing: 8

              Text {
                text: "WORKSPACE " + modelData.name
                color: "#ffffff"
                font.pixelSize: 9
                font.weight: Font.Black
                font.letterSpacing: 1
              }

              // Tip for users
              Text {
                text: "• MIDDLE-CLICK TO CLOSE WINDOW"
                color: "#88ffffff"
                font.pixelSize: 7
                font.weight: Font.Bold
              }
            }
          }
        }
      }
    }
  }
}
