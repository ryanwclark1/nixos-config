import Quickshell // SystemClock
import Quickshell.Bluetooth
import Quickshell.Wayland
import QtQuick
import QtQml
import "."
import "widgets"
import "../modules"
import "../services"
import "../widgets"

Item {
  id: root

  property color background: Colors.background
  property color foreground: Colors.text
  property bool use24hClock: true
  property bool btMenuVisible: false
  property var manager: null
  signal notifClicked()
  signal controlClicked()

  implicitHeight: Config.barHeight

  Rectangle {
    anchors.fill: parent
    color: root.background
    opacity: Config.barOpacity
    radius: Config.barFloating ? 12 : 0
    
    WlLayerSurface {
      anchors.fill: parent
      layer: WlLayerSurface.Top
      blur: Config.blurEnabled
      mask: Region {
        rects: [ Qt.rect(0, 0, parent.width, parent.height) ]
      }
    }
  }

  // LEFT MODULES
  Row {
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    spacing: 12

    Logo {}
    Workspaces {}
    Taskbar {}
    SystemMonitor {}
  }

  // CENTER MODULES
  CenterModules {
    anchors.centerIn: parent
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // RIGHT MODULES
  Row {
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    spacing: 12

    // System Control Trigger (WiFi, Battery, Audio)
    MouseArea {
      height: 24
      width: statusRow.width + 10
      hoverEnabled: true
      onClicked: root.controlClicked()
      onEntered: statusBg.color = Colors.surface
      onExited: statusBg.color = "transparent"

      Rectangle {
        id: statusBg
        anchors.fill: parent
        color: "transparent"
        radius: 4
      }

      Row {
        id: statusRow
        anchors.centerIn: parent
        spacing: 12
        NetworkWidget {}
        BatteryWidget {}
        AudioWidget {}
      }
    }

    Text {
      color: root.foreground
      font.pixelSize: 12
      text: Qt.formatDateTime(
        clock.date,
        root.use24hClock ? "HH:mm" : "h:mm ap"
      )
      anchors.verticalCenter: parent.verticalCenter
    }

    TrayWidget {}

    Rectangle {
      width: 24
      height: 20
      color: "transparent"
      radius: 4
      anchors.verticalCenter: parent.verticalCenter

      Text {
        anchors.centerIn: parent
        color: root.foreground
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        text: root.manager && root.manager.dndEnabled ? "󰂛" : "󰂚"
      }
      
      // Unread badge
      Rectangle {
        width: 6
        height: 6
        radius: 3
        color: Colors.error
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        visible: root.manager && root.manager.notifications && root.manager.notifications.count > 0 && !(root.manager && root.manager.dndEnabled)
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.notifClicked()
        onEntered: parent.color = Colors.surface
        onExited: parent.color = "transparent"
      }
    }
  }
}
