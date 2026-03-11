import Quickshell // SystemClock
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io
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
  readonly property real networkTriggerBottomY: networkTrigger.mapToItem(root, 0, networkTrigger.height).y
  readonly property real audioTriggerBottomY: audioTrigger.mapToItem(root, 0, audioTrigger.height).y
  readonly property real musicTriggerBottomY: musicTrigger.visible ? musicTrigger.mapToItem(root, 0, musicTrigger.height).y : audioTriggerBottomY
  readonly property real recordingTriggerBottomY: recordingTrigger.visible ? recordingTrigger.mapToItem(root, 0, recordingTrigger.height).y : audioTriggerBottomY
  readonly property real batteryTriggerBottomY: batteryTrigger.visible ? batteryTrigger.mapToItem(root, 0, batteryTrigger.height).y : audioTriggerBottomY
  readonly property real clipboardTriggerBottomY: clipboardTrigger.mapToItem(root, 0, clipboardTrigger.height).y
  signal notifClicked()
  signal networkClicked()
  signal audioClicked()
  signal commandClicked()
  signal musicClicked()
  signal recordingClicked()
  signal batteryClicked()
  signal clipboardClicked()

  // Recording detection
  property bool isRecording: false
  Process {
    id: recDetect
    command: ["sh", "-c", "pgrep -x wl-screenrec || pgrep -x wf-recorder || pgrep -f '^gpu-screen-recorder'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: root.isRecording = (this.text || "").trim().length > 0
    }
  }
  Timer { interval: 2000; running: true; repeat: true; onTriggered: { if (!recDetect.running) recDetect.running = true; } }
  Component.onCompleted: recDetect.running = true

  // Active MPRIS players
  readonly property var activeMprisPlayers: {
    var players = [];
    for (var i = 0; i < Mpris.players.length; i++) {
      var p = Mpris.players[i];
      if (p.playbackState !== Mpris.Stopped) players.push(p);
    }
    return players;
  }
  readonly property bool hasActivePlayer: activeMprisPlayers.length > 0

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

      scale: containsMouse ? 1.04 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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

      scale: containsMouse ? 1.04 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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

    // Music trigger — only visible when an MPRIS player is active
    MouseArea {
      id: musicTrigger
      height: 28
      width: musicRow.width + 16
      hoverEnabled: true
      visible: root.hasActivePlayer
      onClicked: root.musicClicked()

      scale: containsMouse ? 1.04 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.fill: parent
        color: musicTrigger.containsMouse ? Colors.highlightLight : Colors.bgWidget
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 160 } }
      }

      Row {
        id: musicRow
        anchors.centerIn: parent
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
            text: root.activeMprisPlayers.length > 0 ? (root.activeMprisPlayers[0].trackTitle || "") : ""
            color: Colors.fgMain
            font.pixelSize: 11
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      SharedWidgets.BarTooltip {
        anchorItem: musicTrigger
        anchorWindow: root.anchorWindow
        hovered: musicTrigger.containsMouse
        text: root.activeMprisPlayers.length > 0
          ? (root.activeMprisPlayers[0].trackTitle || "Music") + (root.activeMprisPlayers[0].trackArtist ? " - " + root.activeMprisPlayers[0].trackArtist : "")
          : "Music controls"
      }
    }

    // Recording trigger — only visible when recording is in progress
    MouseArea {
      id: recordingTrigger
      height: 28
      width: recRow.width + 16
      hoverEnabled: true
      visible: root.isRecording
      onClicked: root.recordingClicked()

      scale: containsMouse ? 1.04 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.fill: parent
        color: recordingTrigger.containsMouse ? Colors.withAlpha(Colors.error, 0.25) : Colors.withAlpha(Colors.error, 0.15)
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 160 } }
      }

      Row {
        id: recRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
          width: 8; height: 8; radius: 4
          color: Colors.error
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation on opacity {
            running: root.isRecording
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

      SharedWidgets.BarTooltip {
        anchorItem: recordingTrigger
        anchorWindow: root.anchorWindow
        hovered: recordingTrigger.containsMouse
        text: "Screen recording in progress"
      }
    }

    // Battery trigger — only visible when battery is present
    MouseArea {
      id: batteryTrigger
      height: 28
      width: batteryRow.width + 16
      hoverEnabled: true
      visible: batteryWidget.showBattery
      onClicked: root.batteryClicked()

      scale: containsMouse ? 1.04 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.fill: parent
        color: batteryTrigger.containsMouse ? Colors.highlightLight : Colors.bgWidget
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 160 } }
      }

      Row {
        id: batteryRow
        anchors.centerIn: parent
        spacing: 4

        SharedWidgets.BatteryWidget {
          id: batteryWidget
        }
      }

      SharedWidgets.BarTooltip {
        anchorItem: batteryTrigger
        anchorWindow: root.anchorWindow
        hovered: batteryTrigger.containsMouse
        text: batteryWidget.tooltipText
      }
    }

    // Settings trigger — opens ControlCenter
    MouseArea {
      id: settingsTrigger
      width: 32
      height: 28
      hoverEnabled: true
      onClicked: root.commandClicked()

      scale: containsMouse ? 1.04 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.fill: parent
        color: settingsTrigger.containsMouse ? Colors.highlightLight : Colors.bgWidget
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 160 } }
      }

      Text {
        anchors.centerIn: parent
        color: Colors.fgMain
        font.pixelSize: 16
        font.family: Colors.fontMono
        text: "󰒓"
      }

      SharedWidgets.BarTooltip {
        anchorItem: settingsTrigger
        anchorWindow: root.anchorWindow
        hovered: settingsTrigger.containsMouse
        text: "System controls"
      }
    }

    Rectangle {
      width: clockText.width + 16
      height: 28
      radius: height / 2
      color: clockMouse.containsMouse ? Colors.highlightLight : Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter
      
      scale: clockMouse.containsMouse ? 1.04 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 160 } }

      Text {
        id: clockText
        anchors.centerIn: parent
        color: Colors.fgMain
        font.pixelSize: 14
        font.weight: Font.Bold
        text: String(clock.hours).padStart(2, '0') + ":" + String(clock.minutes).padStart(2, '0')
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

    // Clipboard trigger
    MouseArea {
      id: clipboardTrigger
      width: 32
      height: 28
      hoverEnabled: true
      onClicked: root.clipboardClicked()

      scale: containsMouse ? 1.04 : 1.0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Rectangle {
        anchors.fill: parent
        color: clipboardTrigger.containsMouse ? Colors.highlightLight : Colors.bgWidget
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 160 } }
      }

      Text {
        anchors.centerIn: parent
        text: "󰅍"
        color: Colors.fgMain
        font.family: Colors.fontMono
        font.pixelSize: 16
      }

      SharedWidgets.BarTooltip {
        anchorItem: clipboardTrigger
        anchorWindow: root.anchorWindow
        hovered: clipboardTrigger.containsMouse
        text: "Clipboard history"
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
