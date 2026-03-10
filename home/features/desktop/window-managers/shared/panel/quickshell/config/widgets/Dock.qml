import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland._Screencopy
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"

PanelWindow {
  id: dockWindow
  anchors {
    bottom: true
  }
  
  implicitWidth: dockContainer.implicitWidth + 24
  implicitHeight: 80
  margins.bottom: 12
  color: "transparent"

  mask: Region {
    item: dockContainer
  }

  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.namespace: "quickshell"
  
  Rectangle {
    id: dockContainer
    anchors.centerIn: parent
    width: row.implicitWidth + 40
    height: 56
    color: Colors.bgGlass
    radius: 18
    border.color: Colors.border
    border.width: 1

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 12

      DockIcon { iconText: "󱗼"; appClass: "launcher"; command: ["quickshell", "ipc", "call", "Launcher", "open"] }
      DockIcon { iconText: ""; appClass: "kitty"; command: ["kitty"] }
      DockIcon { iconText: "󰉋"; appClass: "nemo"; command: ["nemo"] }
      DockIcon { iconText: "󰈹"; appClass: "librewolf"; command: ["librewolf"] }
      DockIcon { iconText: ""; appClass: "vesktop"; command: ["vesktop"] }
      DockIcon { iconText: "󰓇"; appClass: "spotify"; command: ["spotify-launcher"] }
    }
  }

  component DockIcon: Item {
    property string iconText: "?"
    property string appClass: ""
    property var command: []
    
    width: 40
    height: 40

    // Check if app is running
    property var runningWindow: {
       for (var i = 0; i < Hyprland.toplevels.count; i++) {
          var win = Hyprland.toplevels.get(i);
          if (win.class.toLowerCase().includes(appClass.toLowerCase())) return win;
       }
       return null;
    }

    Rectangle {
      id: iconBg
      anchors.fill: parent
      radius: 10
      color: mouseArea.containsMouse ? Colors.highlight : "transparent"
      scale: mouseArea.containsMouse ? 1.2 : 1.0
      Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
      
      Text {
        anchors.centerIn: parent
        text: iconText
        color: Colors.fgMain
        font.pixelSize: 24
        font.family: Colors.fontMono
      }

      // Running Indicator Dot
      Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: -6
        width: runningWindow ? 4 : 0
        height: 4
        radius: 2
        color: runningWindow && runningWindow.focused ? Colors.primary : Colors.fgSecondary
        Behavior on width { NumberAnimation { duration: 200 } }
      }
    }

    // Hover Preview Popup
    PopupWindow {
      id: hoverPreview
      visible: mouseArea.containsMouse && runningWindow !== null
      
      anchor.window: dockWindow
      anchor.rect.x: iconBg.mapToItem(null, 0, 0).x - 100 + (iconBg.width / 2)
      anchor.rect.y: -160 // Above the dock
      
      implicitWidth: 200; implicitHeight: 140
      color: "transparent"

      Rectangle {
        anchors.fill: parent
        color: Colors.bgGlass
        border.color: Colors.primary
        border.width: 1
        radius: 12
        clip: true

        ColumnLayout {
          anchors.fill: parent; anchors.margins: 4; spacing: 4
          Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: Colors.surface; radius: 8; clip: true
            ScreencopyView {
              anchors.fill: parent
              captureSource: runningWindow ? runningWindow.wayland : null
              live: true
            }
          }
          Text {
            text: runningWindow ? runningWindow.title : ""; color: Colors.fgMain; font.pixelSize: 8; elide: Text.ElideRight; Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 180
          }
        }
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      onClicked: {
        if (runningWindow) {
           runningWindow.focus();
        } else {
           Quickshell.execDetached(command);
        }
      }
    }
  }
}
