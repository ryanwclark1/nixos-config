import Quickshell // SystemClock
import Quickshell.Bluetooth
import Quickshell.Wayland
import QtQuick
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
    color: Colors.bgGlass
    opacity: Config.barOpacity
    radius: Config.barFloating ? Colors.radiusMedium : 0
    border.color: Config.barFloating ? Colors.border : "transparent"
    border.width: Config.barFloating ? 1 : 0
  }

  // LEFT MODULES
  Row {
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    spacing: 12

    Logo {
      scale: logoMouse.containsMouse ? 1.1 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      MouseArea { id: logoMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Launcher", "toggle"]) }
    }
    Workspaces {
      scale: wsMouse.containsMouse ? 1.02 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      MouseArea { id: wsMouse; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true; onEntered: {} }
    }
    Taskbar {}
    SystemMonitor {
      scale: smMouse.containsMouse ? 1.02 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      MouseArea { id: smMouse; anchors.fill: parent; hoverEnabled: true; onEntered: {} }
    }
  }

  // CENTER MODULES
  CenterModules {
    anchors.centerIn: parent
    scale: cmMouse.containsMouse ? 1.02 : 1.0
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    MouseArea { id: cmMouse; anchors.fill: parent; hoverEnabled: true; onEntered: {} }
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
      id: controlTrigger
      height: 28
      width: statusRow.width + 16
      hoverEnabled: true
      onClicked: root.controlClicked()
      onEntered: statusBg.color = Qt.rgba(255, 255, 255, 0.15)
      onExited: statusBg.color = Colors.bgWidget

      scale: containsMouse ? 1.05 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

      Rectangle {
        id: statusBg
        anchors.fill: parent
        color: Colors.bgWidget
        radius: height / 2
      }

      Row {
        id: statusRow
        anchors.centerIn: parent
        spacing: 10
        NetworkWidget {}
        BatteryWidget {}
        AudioWidget {}
      }
    }

    Rectangle {
      width: clockText.width + 16
      height: 28
      radius: height / 2
      color: Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter
      
      scale: clockMouse.containsMouse ? 1.05 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

      Text {
        id: clockText
        anchors.centerIn: parent
        color: Colors.fgMain
        font.pixelSize: 14
        font.weight: Font.Bold
        text: Qt.formatDateTime(
          clock.date,
          root.use24hClock ? "HH:mm" : "h:mm ap"
        )
      }
      
      MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Calendar", "toggle"])
      }
    }

    TrayWidget {}

    Rectangle {
      width: 32
      height: 28
      color: Colors.bgWidget
      radius: height / 2
      anchors.verticalCenter: parent.verticalCenter
      
      scale: notifMouse.containsMouse ? 1.1 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

      Text {
        anchors.centerIn: parent
        color: Colors.fgMain
        font.pixelSize: 16
        font.family: Colors.fontMono
        text: root.manager && root.manager.dndEnabled ? "󰂛" : "󰂚"
      }
      
      // Unread badge
      Rectangle {
        width: 8
        height: 8
        radius: 4
        color: Colors.error
        anchors.top: parent.top
        anchors.right: parent.right
        visible: root.manager && root.manager.notifications && root.manager.notifications.count > 0 && !(root.manager && root.manager.dndEnabled)
      }

      MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.notifClicked()
        onEntered: parent.color = Qt.rgba(255, 255, 255, 0.15)
        onExited: parent.color = Colors.bgWidget
      }
    }
  }
}
