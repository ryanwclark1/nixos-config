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
    color: Colors.bgGlass
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
      width: statusRow.width + 16
      hoverEnabled: true
      onClicked: root.controlClicked()
      onEntered: statusBg.color = Qt.rgba(255, 255, 255, 0.15)
      onExited: statusBg.color = Colors.bgWidget

      Rectangle {
        id: statusBg
        anchors.fill: parent
        color: Colors.bgWidget
        radius: height / 2
      }

      Row {
        id: statusRow
        anchors.centerIn: parent
        spacing: 8
        NetworkWidget {}
        BatteryWidget {}
        AudioWidget {}
      }
    }

    Rectangle {
      width: clockText.width + 16
      height: 24
      radius: height / 2
      color: Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: clockText
        anchors.centerIn: parent
        color: Colors.fgMain
        font.pixelSize: 12
        font.weight: Font.Medium
        text: Qt.formatDateTime(
          clock.date,
          root.use24hClock ? "HH:mm" : "h:mm ap"
        )
      }
    }

    TrayWidget {}

    Rectangle {
      width: 28
      height: 24
      color: Colors.bgWidget
      radius: height / 2
      anchors.verticalCenter: parent.verticalCenter

      Text {
        anchors.centerIn: parent
        color: Colors.fgMain
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
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
        anchors.topMargin: 0
        anchors.rightMargin: 0
        visible: root.manager && root.manager.notifications && root.manager.notifications.count > 0 && !(root.manager && root.manager.dndEnabled)
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.notifClicked()
        onEntered: parent.color = Qt.rgba(255, 255, 255, 0.15)
        onExited: parent.color = Colors.bgWidget
      }
    }
  }
}
