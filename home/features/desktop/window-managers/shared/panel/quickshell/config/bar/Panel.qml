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

  SharedWidgets.Ref { service: RecordingService }
  SharedWidgets.Ref { service: PrivacyService }
  SharedWidgets.Ref { service: PrinterService }

  property var manager: null
  property var anchorWindow: null
  readonly property real networkTriggerBottomY: networkTrigger.mapToItem(root, 0, networkTrigger.height).y
  readonly property real btTriggerBottomY: btTrigger.mapToItem(root, 0, btTrigger.height).y
  readonly property real audioTriggerBottomY: audioTrigger.mapToItem(root, 0, audioTrigger.height).y
  readonly property real musicTriggerBottomY: musicTrigger.visible ? musicTrigger.mapToItem(root, 0, musicTrigger.height).y : audioTriggerBottomY
  readonly property real recordingTriggerBottomY: recordingTrigger.visible ? recordingTrigger.mapToItem(root, 0, recordingTrigger.height).y : audioTriggerBottomY
  readonly property real privacyTriggerBottomY: privacyTrigger.visible ? privacyTrigger.mapToItem(root, 0, privacyTrigger.height).y : audioTriggerBottomY
  readonly property real batteryTriggerBottomY: batteryTrigger.visible ? batteryTrigger.mapToItem(root, 0, batteryTrigger.height).y : audioTriggerBottomY
  readonly property real clipboardTriggerBottomY: clipboardTrigger.mapToItem(root, 0, clipboardTrigger.height).y
  readonly property real weatherTriggerBottomY: weatherTrigger.mapToItem(root, 0, weatherTrigger.height).y
  readonly property real systemMonitorBottomY: systemMonitor.mapToItem(root, 0, systemMonitor.height).y
  readonly property real printerTriggerBottomY: printerTrigger.visible ? printerTrigger.mapToItem(root, 0, printerTrigger.height).y : audioTriggerBottomY

  // X-center positions for icon-aligned popup placement
  readonly property real networkTriggerCenterX: networkTrigger.mapToItem(root, networkTrigger.width / 2, 0).x
  readonly property real btTriggerCenterX: btTrigger.mapToItem(root, btTrigger.width / 2, 0).x
  readonly property real audioTriggerCenterX: audioTrigger.mapToItem(root, audioTrigger.width / 2, 0).x
  readonly property real musicTriggerCenterX: musicTrigger.visible ? musicTrigger.mapToItem(root, musicTrigger.width / 2, 0).x : audioTriggerCenterX
  readonly property real recordingTriggerCenterX: recordingTrigger.visible ? recordingTrigger.mapToItem(root, recordingTrigger.width / 2, 0).x : audioTriggerCenterX
  readonly property real privacyTriggerCenterX: privacyTrigger.visible ? privacyTrigger.mapToItem(root, privacyTrigger.width / 2, 0).x : audioTriggerCenterX
  readonly property real batteryTriggerCenterX: batteryTrigger.visible ? batteryTrigger.mapToItem(root, batteryTrigger.width / 2, 0).x : audioTriggerCenterX
  readonly property real clipboardTriggerCenterX: clipboardTrigger.mapToItem(root, clipboardTrigger.width / 2, 0).x
  readonly property real weatherTriggerCenterX: weatherTrigger.mapToItem(root, weatherTrigger.width / 2, 0).x
  readonly property real systemMonitorCenterX: systemMonitor.mapToItem(root, systemMonitor.width / 2, 0).x
  readonly property real printerTriggerCenterX: printerTrigger.visible ? printerTrigger.mapToItem(root, printerTrigger.width / 2, 0).x : audioTriggerCenterX
  readonly property real cavaTriggerBottomY: centerModules.cavaPill.mapToItem(root, 0, centerModules.cavaPill.height).y
  readonly property real cavaTriggerCenterX: centerModules.cavaPill.mapToItem(root, centerModules.cavaPill.width / 2, 0).x
  // Date/time trigger geometry is computed from direct coordinates so popup anchoring
  // stays correct as the center row content shifts.
  readonly property real dateTimeTriggerBottomY: centerModules.y + centerModules.dateTimePill.y + centerModules.dateTimePill.height
  readonly property real dateTimeTriggerCenterX: centerModules.x + centerModules.dateTimePill.x + (centerModules.dateTimePill.width / 2)
  readonly property string fullCavaData: centerModules.fullCavaData
  signal cavaClicked()
  signal dateTimeClicked()
  signal notifClicked()
  signal networkClicked()
  signal audioClicked()
  signal commandClicked()
  signal musicClicked()
  signal recordingClicked()
  signal privacyClicked()
  signal batteryClicked()
  signal clipboardClicked()
  signal bluetoothClicked()
  signal weatherClicked()
  signal systemStatsClicked()
  signal notepadClicked()
  signal printerClicked()

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
    anchors.leftMargin: Colors.spacingM
    anchors.verticalCenter: parent.verticalCenter
    spacing: Colors.spacingM

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
    id: centerModules
    anchors.centerIn: parent
    anchorWindow: root.anchorWindow
    onCavaClicked: root.cavaClicked()
    onDateTimeClicked: root.dateTimeClicked()
  }

  // RIGHT MODULES
  Row {
    anchors.right: parent.right
    anchors.rightMargin: Colors.spacingM
    anchors.verticalCenter: parent.verticalCenter
    spacing: Colors.spacingM

    SharedWidgets.BarPill {
      id: weatherTrigger
      anchorWindow: root.anchorWindow
      tooltipText: WeatherService.condition || "Weather"
      onClicked: root.weatherClicked()

      Row {
        spacing: Colors.spacingS

        Text {
          text: Colors.weatherIcon(WeatherService.condition)
          color: Colors.accent
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: WeatherService.temp
          color: Colors.text
          font.pixelSize: Colors.fontSizeSmall
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
        spacing: Colors.spacingS
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
        spacing: Colors.spacingS

        Text {
          text: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? "󰂯" : "󰂲"
          color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Colors.primary : Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
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
        spacing: Colors.spacingS
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
      tooltipText: {
        var players = SystemStatus.activeMprisPlayers;
        if (!players || players.length === 0) return "Music controls";
        var p = players[0];
        return (p.trackTitle || "Music") + (p.trackArtist ? " - " + p.trackArtist : "");
      }
      onClicked: root.musicClicked()

      Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

      Row {
        spacing: Colors.spacingS

        Text {
          text: "󰝚"
          color: Colors.primary
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
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
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }

    // Privacy indicator — visible when mic, camera, or screenshare is active
    SharedWidgets.BarPill {
      id: privacyTrigger
      visible: PrivacyService.anyActive
      anchorWindow: root.anchorWindow
      normalColor: Colors.withAlpha(Colors.warning, 0.15)
      hoverColor: Colors.withAlpha(Colors.warning, 0.28)
      tooltipText: PrivacyService.activeLabel || "Privacy"
      onClicked: root.privacyClicked()

      Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

      Row {
        spacing: Colors.spacingXS

        // Animated dot indicator
        Rectangle {
          width: 7; height: 7; radius: 3.5
          color: Colors.warning
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation on opacity {
            running: PrivacyService.anyActive
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.25; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.25; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
          }
        }

        Text {
          text: PrivacyService.activeIcon
          color: Colors.warning
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
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
        spacing: Colors.spacingS

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
          font.pixelSize: Colors.fontSizeXS
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
        spacing: Colors.spacingXS
        SharedWidgets.BatteryWidget {
          id: batteryWidget
        }
      }
    }

    // Printer trigger — only visible when at least one printer is configured
    SharedWidgets.BarPill {
      id: printerTrigger
      visible: PrinterService.hasPrinters
      anchorWindow: root.anchorWindow
      tooltipText: PrinterService.activeJobs > 0
        ? PrinterService.activeJobs + " print job" + (PrinterService.activeJobs !== 1 ? "s" : "") + " active"
        : (PrinterService.defaultPrinter ? PrinterService.defaultPrinter : "Printers")
      onClicked: root.printerClicked()

      Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

      Row {
        spacing: Colors.spacingXS

        Text {
          text: "󰐪"
          color: PrinterService.activeJobs > 0 ? Colors.warning : Colors.text
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
          Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Active jobs badge — only shown when jobs are in flight
        Rectangle {
          visible: PrinterService.activeJobs > 0
          width: printerJobsBadge.contentWidth + 8
          height: 16
          radius: Colors.radiusXS
          color: Colors.withAlpha(Colors.warning, 0.20)
          anchors.verticalCenter: parent.verticalCenter

          Text {
            id: printerJobsBadge
            anchors.centerIn: parent
            text: PrinterService.activeJobs
            color: Colors.warning
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
          }
        }
      }
    }

    // Bar plugin extension point — renders enabled bar-widget plugins
    Repeater {
      model: PluginService.barPlugins
      delegate: Loader {
        required property var modelData
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        source: modelData.path + modelData.mainFile
        onStatusChanged: {
          if (status === Loader.Error)
            console.warn("PluginService: failed to load bar plugin " + modelData.id + " from " + source);
        }
      }
    }

    // Notepad trigger — opens slideout notepad
    SharedWidgets.BarPill {
      id: notepadTrigger
      anchorWindow: root.anchorWindow
      tooltipText: "Notepad"
      onClicked: root.notepadClicked()

      Text {
        color: Colors.text
        font.pixelSize: Colors.fontSizeLarge
        font.family: Colors.fontMono
        text: "󰠮"
      }
    }

    // Settings trigger — opens ControlCenter
    SharedWidgets.BarPill {
      id: settingsTrigger
      anchorWindow: root.anchorWindow
      tooltipText: "System controls"
      onClicked: root.commandClicked()

      Text {
        color: Colors.text
        font.pixelSize: Colors.fontSizeXL
        font.family: Colors.fontMono
        text: "󰒓"
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
        color: Colors.text
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeXL
      }
    }

    SharedWidgets.BarPill {
      id: notifBg
      anchorWindow: root.anchorWindow
      tooltipText: root.manager && root.manager.dndEnabled ? "Notifications paused" : "Notifications"
      onClicked: root.notifClicked()

      readonly property bool hasDnd: !!(root.manager && root.manager.dndEnabled)
      readonly property bool hasUnread: !!(root.manager && root.manager.notifications && root.manager.notifications.count > 0)

      Text {
        color: Colors.text
        font.pixelSize: Colors.fontSizeXL
        font.family: Colors.fontMono
        text: notifBg.hasDnd ? "󰂛" : "󰂚"
      }

      // Unread badge — reparented to BarPill root so anchors work correctly
      Rectangle {
        parent: notifBg
        width: 8
        height: 8
        radius: 4
        color: Colors.error
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        visible: notifBg.hasUnread && !notifBg.hasDnd
        z: 10
      }
    }
  }
}
