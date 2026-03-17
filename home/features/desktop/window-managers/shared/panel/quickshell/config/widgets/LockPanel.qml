import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../services"
import "../system/sections"
import "lock"

Item {
  id: root
  anchors.fill: parent
  Ref { service: MediaService; active: Config.lockScreenMediaControls }
  Ref { service: WeatherService; active: Config.lockScreenWeather }

  property var lockContext: null
  property bool compact: Config.lockScreenCompact
  readonly property var lockPowerButtons: SystemActionRegistry.actionsByIds([
    "reboot",
    "shutdown"
  ])

  // Session action countdown
  property string pendingAction: ""
  property bool timerActive: false
  property int timeRemaining: 0

  function startTimer(action) {
    if (timerActive && pendingAction === action) {
      executeAction(action);
      return;
    }
    pendingAction = action;
    timeRemaining = Config.lockScreenCountdown;
    timerActive = true;
    countdownTimer.start();
  }

  function cancelTimer() {
    timerActive = false;
    pendingAction = "";
    timeRemaining = 0;
    countdownTimer.stop();
  }

    function executeAction(action) {
        countdownTimer.stop();
        switch (action) {
      case "logout":
        SystemActionRegistry.execute(action); break;
      case "suspend":
        Quickshell.execDetached(["systemctl", "suspend"]); break;
      case "hibernate":
        Quickshell.execDetached(["systemctl", "hibernate"]); break;
      case "reboot":
        SystemActionRegistry.execute(action); break;
      case "shutdown":
        SystemActionRegistry.execute(action); break;
    }
    cancelTimer();
  }

  Timer {
    id: countdownTimer
    interval: 100
    repeat: true
    onTriggered: {
      root.timeRemaining -= interval;
      if (root.timeRemaining <= 0) root.executeAction(root.pendingAction);
    }
  }

  SystemClock {
    id: lockClock
    precision: SystemClock.Minutes
  }

  // Background overlay
  Rectangle {
    anchors.fill: parent
    color: Colors.background
    opacity: 0.7
  }

  // Main layout
  ColumnLayout {
    anchors.fill: parent
    spacing: 0

    Item { Layout.fillHeight: true; Layout.preferredHeight: compact ? 40 : 80 }

    // Clock
    LockClock {
      Layout.alignment: Qt.AlignHCenter
      lockClock: lockClock
      compact: root.compact
    }

    Item { Layout.fillHeight: true; Layout.preferredHeight: compact ? 20 : 60 }

    // Auth area
    LockAuthArea {
      id: authArea
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 300
      lockContext: root.lockContext
      timerActive: root.timerActive
      pendingAction: root.pendingAction
      timeRemaining: root.timeRemaining
      compact: root.compact
      onCancelRequested: root.cancelTimer()
    }

    Item { Layout.fillHeight: true }

    // Bottom bar: media + weather + session buttons
    RowLayout {
      Layout.fillWidth: true
      Layout.margins: compact ? 20 : 40
      spacing: Colors.spacingLG

      // Media controls (optional)
      Loader {
        active: Config.lockScreenMediaControls && !compact && SystemStatus.hasActivePlayer
        Layout.maximumWidth: 350
        sourceComponent: LockMediaCard {}
      }

      Item { Layout.fillWidth: true }

      // Weather (optional)
      Loader {
        active: Config.lockScreenWeather && !compact && WeatherService.temp !== ""
        sourceComponent: RowLayout {
          spacing: Colors.spacingS
          Text {
            text: Colors.weatherIcon(WeatherService.condition)
            color: Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeXL
          }
          Text {
            text: (WeatherService.temp || "") + " " + (WeatherService.condition || "")
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeMedium
          }
        }
      }

      // Battery
      Text {
        visible: UPower.displayDevice && UPower.displayDevice.isPresent
        text: UPower.displayDevice ? "󰁹 " + Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
        color: Colors.textSecondary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeMedium
      }

      // Session buttons (optional)
      Loader {
        active: Config.lockScreenSessionButtons
        sourceComponent: LockSessionBar {
          lockPowerButtons: root.lockPowerButtons
          pendingAction: root.pendingAction
          timerActive: root.timerActive
          onActionRequested: (action) => root.startTimer(action)
        }
      }
    }
  }

  // Shake animation on auth failure
  Connections {
    target: lockContext
    function onFailed() {
      authArea.shake();
      authArea.clearInput();
    }
    function onUnlocked() {
      authArea.clearInput();
    }
  }

  // Focus password input when visible
  onVisibleChanged: {
    if (visible) authArea.forceActiveFocus();
  }
}
