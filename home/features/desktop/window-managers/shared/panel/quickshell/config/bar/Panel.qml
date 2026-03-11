import Quickshell // SystemClock
import Quickshell.Bluetooth
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "."
import "widgets"
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

Item {
  id: root

  Component.onCompleted: RecordingService.subscribe()
  Component.onDestruction: RecordingService.unsubscribe()

  property var manager: null
  property var anchorWindow: null
  readonly property real networkTriggerBottomY: networkTrigger.mapToItem(root, 0, networkTrigger.height).y
  readonly property real btTriggerBottomY: btTrigger.mapToItem(root, 0, btTrigger.height).y
  readonly property real audioTriggerBottomY: audioTrigger.mapToItem(root, 0, audioTrigger.height).y
  readonly property real musicTriggerBottomY: musicTrigger.visible ? musicTrigger.mapToItem(root, 0, musicTrigger.height).y : audioTriggerBottomY
  readonly property real recordingTriggerBottomY: recordingTrigger.visible ? recordingTrigger.mapToItem(root, 0, recordingTrigger.height).y : audioTriggerBottomY
  readonly property real batteryTriggerBottomY: batteryTrigger.visible ? batteryTrigger.mapToItem(root, 0, batteryTrigger.height).y : audioTriggerBottomY
  readonly property real clipboardTriggerBottomY: clipboardTrigger.mapToItem(root, 0, clipboardTrigger.height).y
  readonly property real weatherTriggerBottomY: weatherTrigger.mapToItem(root, 0, weatherTrigger.height).y
  readonly property real systemMonitorBottomY: systemMonitor.mapToItem(root, 0, systemMonitor.height).y
  signal notifClicked()
  signal networkClicked()
  signal audioClicked()
  signal commandClicked()
  signal musicClicked()
  signal recordingClicked()
  signal batteryClicked()
  signal clipboardClicked()
  signal bluetoothClicked()
  signal weatherClicked()
  signal systemStatsClicked()

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
      id: systemMonitor
      anchorWindow: root.anchorWindow
      onStatsClicked: root.systemStatsClicked()
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

    SharedWidgets.BarPill {
      id: weatherTrigger
      anchorWindow: root.anchorWindow
      tooltipText: WeatherService.condition || "Weather"
      onClicked: root.weatherClicked()

      Row {
        spacing: 6

        Text {
          text: Colors.weatherIcon(WeatherService.condition)
          color: Colors.accent
          font.family: Colors.fontMono
          font.pixelSize: 14
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: WeatherService.temp
          color: Colors.fgMain
          font.pixelSize: 11
          font.weight: Font.Medium
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    SharedWidgets.BarPill {
      id: networkTrigger
      anchorWindow: root.anchorWindow
      tooltipText: networkWidget.tooltipText
      onClicked: root.networkClicked()

      Row {
        spacing: 8
        SharedWidgets.NetworkWidget {
          id: networkWidget
        }
      }
    }

    SharedWidgets.BarPill {
      id: btTrigger
      anchorWindow: root.anchorWindow
      tooltipText: {
        if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled) return "Bluetooth off";
        var count = 0;
        for (var i = 0; i < Bluetooth.devices.values.length; i++) {
          if (Bluetooth.devices.values[i].connected) count++;
        }
        return count > 0 ? count + " device" + (count > 1 ? "s" : "") + " connected" : "Bluetooth";
      }
      onClicked: root.bluetoothClicked()

      Row {
        spacing: 6

        Text {
          text: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? "󰂯" : "󰂲"
          color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Colors.primary : Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: 14
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    SharedWidgets.BarPill {
      id: audioTrigger
      anchorWindow: root.anchorWindow
      tooltipText: audioWidget.tooltipText
      onClicked: root.audioClicked()

      Row {
        spacing: 8
        SharedWidgets.AudioWidget {
          id: audioWidget
        }
      }
    }

    // Music trigger — only visible when an MPRIS player is active
    SharedWidgets.BarPill {
      id: musicTrigger
      visible: SystemStatus.hasActivePlayer
      anchorWindow: root.anchorWindow
      tooltipText: SystemStatus.activeMprisPlayers.length > 0
        ? (SystemStatus.activeMprisPlayers[0].trackTitle || "Music") + (SystemStatus.activeMprisPlayers[0].trackArtist ? " - " + SystemStatus.activeMprisPlayers[0].trackArtist : "")
        : "Music controls"
      onClicked: root.musicClicked()

      Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

      Row {
        spacing: 6

        Text {
          text: "󰝚"
          color: Colors.primary
          font.family: Colors.fontMono
          font.pixelSize: 14
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          width: Math.min(musicTitleText.contentWidth, 100)
          height: 20
          clip: true
          anchors.verticalCenter: parent.verticalCenter

          Text {
            id: musicTitleText
            text: SystemStatus.activeMprisPlayers.length > 0 ? (SystemStatus.activeMprisPlayers[0].trackTitle || "") : ""
            color: Colors.fgMain
            font.pixelSize: 11
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }

    // Recording trigger — only visible when recording is in progress
    SharedWidgets.BarPill {
      id: recordingTrigger
      visible: SystemStatus.isRecording
      anchorWindow: root.anchorWindow
      normalColor: Colors.withAlpha(Colors.error, 0.15)
      hoverColor: Colors.withAlpha(Colors.error, 0.25)
      tooltipText: "Screen recording in progress"
      onClicked: root.recordingClicked()

      Row {
        spacing: 6

        Rectangle {
          width: 8; height: 8; radius: 4
          color: Colors.error
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation on opacity {
            running: SystemStatus.isRecording
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
            NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
          }
        }

        Text {
          text: "REC"
          color: Colors.error
          font.pixelSize: 10
          font.weight: Font.Bold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    // Battery trigger — only visible when battery is present
    SharedWidgets.BarPill {
      id: batteryTrigger
      visible: batteryWidget.showBattery
      anchorWindow: root.anchorWindow
      tooltipText: batteryWidget.tooltipText
      onClicked: root.batteryClicked()

      Row {
        spacing: 4
        SharedWidgets.BatteryWidget {
          id: batteryWidget
        }
      }
    }

    // Settings trigger — opens ControlCenter
    SharedWidgets.BarPill {
      id: settingsTrigger
      anchorWindow: root.anchorWindow
      tooltipText: "System controls"
      onClicked: root.commandClicked()

      Text {
        color: Colors.fgMain
        font.pixelSize: 16
        font.family: Colors.fontMono
        text: "󰒓"
      }
    }

    SharedWidgets.BarPill {
      anchorWindow: root.anchorWindow
      tooltipText: "Calendar"
      onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Calendar", "toggle"])

      Text {
        id: clockText
        color: Colors.fgMain
        font.pixelSize: 14
        font.weight: Font.Bold
        text: String(clock.hours).padStart(2, '0') + ":" + String(clock.minutes).padStart(2, '0')
      }
    }

    SharedWidgets.TrayWidget {
      anchorWindow: root.anchorWindow
    }

    SharedWidgets.BarPill {
      id: clipboardTrigger
      anchorWindow: root.anchorWindow
      tooltipText: "Clipboard history"
      onClicked: root.clipboardClicked()

      Text {
        text: "󰅍"
        color: Colors.fgMain
        font.family: Colors.fontMono
        font.pixelSize: 16
      }
    }

    Rectangle {
      id: notifBg
      width: 32
      height: 28
      color: notifMouse.containsMouse ? Colors.highlightLight : Colors.bgWidget
      radius: height / 2
      anchors.verticalCenter: parent.verticalCenter

      scale: notifMouse.containsMouse ? 1.06 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 160 } }

      readonly property bool hasDnd: !!(root.manager && root.manager.dndEnabled)
      readonly property bool hasUnread: !!(root.manager && root.manager.notifications && root.manager.notifications.count > 0)

      Text {
        anchors.centerIn: parent
        color: Colors.fgMain
        font.pixelSize: 16
        font.family: Colors.fontMono
        text: notifBg.hasDnd ? "󰂛" : "󰂚"
      }

      // Unread badge
      Rectangle {
        width: 8
        height: 8
        radius: 4
        color: Colors.error
        anchors.top: parent.top
        anchors.right: parent.right
        visible: notifBg.hasUnread && !notifBg.hasDnd
      }

      MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.notifClicked()
      }

      SharedWidgets.BarTooltip {
        anchorItem: parent
        anchorWindow: root.anchorWindow
        hovered: notifMouse.containsMouse
        text: root.manager && root.manager.dndEnabled ? "Notifications paused" : "Notifications"
      }
    }
  }
}
