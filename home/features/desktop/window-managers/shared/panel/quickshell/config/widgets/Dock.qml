import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../launcher"

PanelWindow {
  id: dockWindow
  anchors {
    bottom: true
  }
  
  // Center it by not anchoring left or right
  implicitWidth: dockContainer.implicitWidth + 24
  implicitHeight: 70
  margins.bottom: 12
  
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.namespace: "quickshell"
  
  Rectangle {
    id: dockContainer
    anchors.centerIn: parent
    width: row.implicitWidth + 40
    height: 56
    color: "#a6101014"
    radius: 18
    border.color: "#33ffffff"
    border.width: 1

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 12

      // 1. Launcher
      DockIcon {
        iconText: "󱗼"
        command: ["quickshell", "ipc", "call", "Launcher", "open"]
      }
      
      // 2. Terminal
      DockIcon {
        iconText: ""
        command: ["kitty"]
      }

      // 3. File Manager
      DockIcon {
        iconText: "󰉋"
        command: ["nemo"]
      }

      // 4. Firefox
      DockIcon {
        iconText: "󰈹"
        command: ["librewolf"]
      }

      // 5. Discord
      DockIcon {
        iconText: ""
        command: ["vesktop"]
      }

      // 6. Spotify
      DockIcon {
        iconText: "󰓇"
        command: ["spotify-launcher"]
      }
    }
  }

  component DockIcon: Item {
    property string iconText: "?"
    property var command: []
    
    width: 40
    height: 40

    Rectangle {
      anchors.fill: parent
      radius: 10
      color: mouseArea.containsMouse ? "#33ffffff" : "transparent"
      scale: mouseArea.containsMouse ? 1.2 : 1.0
      
      Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
      Behavior on color { ColorAnimation { duration: 150 } }
      
      Text {
        anchors.centerIn: parent
        text: iconText
        color: "#ffffff"
        font.pixelSize: 24
        font.family: "JetBrainsMono Nerd Font"
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (command[0] === "quickshell") {
           Quickshell.execDetached(command);
        } else {
           var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: true; command: ' + JSON.stringify(command) + ' }', dockWindow);
           proc.startDetached();
        }
      }
    }
  }
}
