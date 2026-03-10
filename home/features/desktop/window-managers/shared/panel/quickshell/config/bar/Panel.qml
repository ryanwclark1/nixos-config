import Quickshell // SystemClock
import Quickshell.Wayland
import QtQuick
import "."
import "widgets"
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

Item {
  id: root

  property bool btMenuVisible: false
  property var manager: null
  property var anchorWindow: null
  readonly property real networkTriggerX: networkTrigger.mapToItem(root, 0, 0).x
  readonly property real networkTriggerBottomY: networkTrigger.mapToItem(root, 0, networkTrigger.height).y
  readonly property real networkTriggerWidth: networkTrigger.width
  readonly property real audioTriggerX: audioTrigger.mapToItem(root, 0, 0).x
  readonly property real audioTriggerBottomY: audioTrigger.mapToItem(root, 0, audioTrigger.height).y
  readonly property real audioTriggerWidth: audioTrigger.width
  signal notifClicked()
  signal networkClicked()
  signal audioClicked()
  signal commandClicked()

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
      tooltipText: "Application launcher"
      anchorWindow: root.anchorWindow
    }
    Workspaces {
      anchorWindow: root.anchorWindow
    }
    Taskbar {
      anchorWindow: root.anchorWindow
    }
    SystemMonitor {
      anchorWindow: root.anchorWindow
    }
  }

  // CENTER MODULES
  CenterModules {
    anchors.centerIn: parent
    anchorWindow: root.anchorWindow
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

    MouseArea {
      id: networkTrigger
      height: 28
      width: networkRow.width + 16
      hoverEnabled: true
      onClicked: root.networkClicked()

      scale: containsMouse ? 1.05 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

      Rectangle {
        id: networkBg
        anchors.fill: parent
        color: networkTrigger.containsMouse ? Colors.highlightLight : Colors.bgWidget
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 160 } }
      }

      Row {
        id: networkRow
        anchors.centerIn: parent
        spacing: 8
        SharedWidgets.NetworkWidget {
          id: networkWidget
        }
      }

      SharedWidgets.BarTooltip {
        anchorItem: networkTrigger
        anchorWindow: root.anchorWindow
        hovered: networkTrigger.containsMouse
        text: networkWidget.tooltipText
      }
    }

    MouseArea {
      id: audioTrigger
      height: 28
      width: audioRow.width + 16
      hoverEnabled: true
      onClicked: root.audioClicked()

      scale: containsMouse ? 1.05 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

      Rectangle {
        id: audioBg
        anchors.fill: parent
        color: audioTrigger.containsMouse ? Colors.highlightLight : Colors.bgWidget
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 160 } }
      }

      Row {
        id: audioRow
        anchors.centerIn: parent
        spacing: 8
        SharedWidgets.AudioWidget {
          id: audioWidget
        }
      }

      SharedWidgets.BarTooltip {
        anchorItem: audioTrigger
        anchorWindow: root.anchorWindow
        hovered: audioTrigger.containsMouse
        text: audioWidget.tooltipText
      }
    }

    MouseArea {
      id: commandTrigger
      height: 28
      width: commandRow.width + 16
      hoverEnabled: true
      onClicked: root.commandClicked()

      scale: containsMouse ? 1.05 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

      Rectangle {
        id: commandBg
        anchors.fill: parent
        color: commandTrigger.containsMouse ? Colors.highlightLight : Colors.bgWidget
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 160 } }
      }

      Row {
        id: commandRow
        anchors.centerIn: parent
        spacing: 8

        SharedWidgets.BatteryWidget {
          id: batteryWidget
        }

        Text {
          color: Colors.fgMain
          font.pixelSize: 16
          font.family: Colors.fontMono
          text: "󰒓"
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      SharedWidgets.BarTooltip {
        anchorItem: commandTrigger
        anchorWindow: root.anchorWindow
        hovered: commandTrigger.containsMouse
        text: batteryWidget.visible ? (batteryWidget.tooltipText + " • System controls") : "System controls"
      }
    }

    Rectangle {
      width: clockText.width + 16
      height: 28
      radius: height / 2
      color: clockMouse.containsMouse ? Colors.highlightLight : Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter
      
      scale: clockMouse.containsMouse ? 1.05 : 1.0
      Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 160 } }

      Text {
        id: clockText
        anchors.centerIn: parent
        color: Colors.fgMain
        font.pixelSize: 14
        font.weight: Font.Bold
        text: Qt.formatDateTime(clock.date, "HH:mm")
      }
      
      MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Calendar", "toggle"])
      }

      SharedWidgets.BarTooltip {
        anchorItem: parent
        anchorWindow: root.anchorWindow
        hovered: clockMouse.containsMouse
        text: "Calendar"
      }
    }

    SharedWidgets.TrayWidget {
      anchorWindow: root.anchorWindow
    }

    Rectangle {
      width: 32
      height: 28
      color: notifMouse.containsMouse ? Colors.highlightLight : Colors.bgWidget
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
      }

      Behavior on color { ColorAnimation { duration: 160 } }

      SharedWidgets.BarTooltip {
        anchorItem: parent
        anchorWindow: root.anchorWindow
        hovered: notifMouse.containsMouse
        text: root.manager && root.manager.dndEnabled ? "Notifications paused" : "Notifications"
      }
    }
  }
}
