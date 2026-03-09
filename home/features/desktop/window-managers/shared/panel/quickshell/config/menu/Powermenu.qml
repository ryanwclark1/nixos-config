import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
  id: root
  
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  color: "transparent"
  
  property bool isVisible: false

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  
  Item {
    anchors.fill: parent
    visible: root.isVisible

    // Backdrop to close
    MouseArea {
      anchors.fill: parent
      onClicked: root.isVisible = false
      
      Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.isVisible ? 0.4 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
      }
    }

    // Power Menu Content
    ColumnLayout {
      id: contentCol
      anchors.centerIn: parent
      spacing: 40      
      scale: root.isVisible ? 1.0 : 0.9
      Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
      opacity: root.isVisible ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

      Text {
        text: "Power Menu"
        color: Colors.fgMain
        font.pixelSize: 32
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignHCenter
      }

      RowLayout {
        spacing: 20
        
        Repeater {
          model: [
            { icon: "󰐥", label: "Shutdown", color: Colors.error, cmd: "systemctl poweroff" },
            { icon: "󰑐", label: "Reboot", color: Colors.accent, cmd: "systemctl reboot" },
            { icon: "󰌾", label: "Lock", color: Colors.primary, cmd: "hyprlock" },
            { icon: "󰗽", label: "Logout", color: Colors.fgSecondary, cmd: "hyprctl dispatch exit" }
          ]
          
          delegate: Rectangle {
            id: btn
            width: 120; height: 120
            radius: 20
            color: mouseArea.containsMouse ? "#33ffffff" : "#1affffff"
            border.color: mouseArea.containsMouse ? modelData.color : Colors.border
            border.width: 2
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            ColumnLayout {
              anchors.centerIn: parent
              spacing: 10
              Text {
                text: modelData.icon
                color: modelData.color
                font.family: Colors.fontMono
                font.pixelSize: 40
                Layout.alignment: Qt.AlignHCenter
              }
              Text {
                text: modelData.label
                color: Colors.fgMain
                font.pixelSize: 12
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
              }
            }
            
            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                root.isVisible = false;
                Quickshell.execDetached(modelData.cmd.split(" "));
              }
            }
          }
        }
      }
      
      Text {
        text: "Press ESC to cancel"
        color: Colors.fgDim
        font.pixelSize: 12
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }

  Keys.onEscapePressed: root.isVisible = false
}
