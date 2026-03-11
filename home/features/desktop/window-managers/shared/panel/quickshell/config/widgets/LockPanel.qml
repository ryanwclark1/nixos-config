import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../services"
import "../modules"

Item {
  id: root
  anchors.fill: parent

  property var lockContext: null
  property bool compact: Config.lockScreenCompact

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
        Quickshell.execDetached(["loginctl", "terminate-session", "self"]); break;
      case "suspend":
        Quickshell.execDetached(["systemctl", "suspend"]); break;
      case "hibernate":
        Quickshell.execDetached(["systemctl", "hibernate"]); break;
      case "reboot":
        Quickshell.execDetached(["systemctl", "reboot"]); break;
      case "shutdown":
        Quickshell.execDetached(["systemctl", "poweroff"]); break;
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
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: compact ? 2 : 5

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(lockClock.date, "HH:mm")
        color: Colors.fgMain
        font.pixelSize: compact ? 80 : 120
        font.weight: Font.Bold
      }
      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(lockClock.date, "dddd, MMMM d")
        color: Colors.fgSecondary
        font.pixelSize: compact ? 18 : 24
      }
    }

    Item { Layout.fillHeight: true; Layout.preferredHeight: compact ? 20 : 60 }

    // Auth area
    ColumnLayout {
      id: authArea
      Layout.alignment: Qt.AlignHCenter
      spacing: 16
      Layout.preferredWidth: 300

      property real shakeOffset: 0
      transform: Translate { x: authArea.shakeOffset }

      // Password input
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        color: Colors.highlightLight
        radius: 12
        border.color: pwInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 10

          Text {
            text: "󰌾"
            color: Colors.fgDim
            font.family: Colors.fontMono
            font.pixelSize: 18
          }

          TextInput {
            id: pwInput
            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
            color: Colors.text
            font.pixelSize: 18
            echoMode: TextInput.Password
            focus: true

            onTextChanged: {
              if (lockContext) lockContext.currentText = text;
            }

            Keys.onReturnPressed: {
              if (lockContext) lockContext.tryUnlock();
            }
            Keys.onEscapePressed: {
              if (root.timerActive) {
                root.cancelTimer();
              } else {
                text = "";
              }
            }
          }

          // Submit button
          Rectangle {
            width: 28; height: 28; radius: 14
            color: submitMa.containsMouse ? Colors.primary : Colors.withAlpha(Colors.primary, 0.6)
            visible: pwInput.text.length > 0

            Text {
              anchors.centerIn: parent
              text: "󰁔"
              color: Colors.background
              font.family: Colors.fontMono
              font.pixelSize: 14
            }

            MouseArea {
              id: submitMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: { if (lockContext) lockContext.tryUnlock(); }
            }
          }
        }

        // Placeholder
        Text {
          anchors.centerIn: parent
          text: "Unlock..."
          color: Colors.fgDim
          font.pixelSize: 16
          visible: !pwInput.text && !pwInput.activeFocus
        }
      }

      // Error message
      Text {
        Layout.alignment: Qt.AlignHCenter
        text: lockContext ? lockContext.errorMessage : ""
        color: Colors.error
        font.pixelSize: 12
        font.weight: Font.Medium
        visible: lockContext ? lockContext.showError : false
      }

      // Unlock in progress indicator
      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Authenticating..."
        color: Colors.fgDim
        font.pixelSize: 11
        visible: lockContext ? lockContext.unlockInProgress : false
      }

      // Countdown display
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        visible: root.timerActive
        width: countdownRow.implicitWidth + 24
        height: 36
        radius: 18
        color: Colors.withAlpha(Colors.error, 0.15)
        border.color: Colors.error
        border.width: 1

        RowLayout {
          id: countdownRow
          anchors.centerIn: parent
          spacing: 8

          Text {
            text: root.pendingAction.charAt(0).toUpperCase() + root.pendingAction.slice(1) + " in " + Math.ceil(root.timeRemaining / 1000) + "s"
            color: Colors.error
            font.pixelSize: 13
            font.weight: Font.Medium
          }

          Rectangle {
            width: 20; height: 20; radius: 10
            color: cancelMa.containsMouse ? Colors.error : "transparent"
            border.color: Colors.error; border.width: 1

            Text {
              anchors.centerIn: parent
              text: "󰅖"
              color: Colors.error
              font.family: Colors.fontMono
              font.pixelSize: 10
            }

            MouseArea {
              id: cancelMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.cancelTimer()
            }
          }
        }
      }
    }

    Item { Layout.fillHeight: true }

    // Bottom bar: media + weather + session buttons
    RowLayout {
      Layout.fillWidth: true
      Layout.margins: compact ? 20 : 40
      spacing: 20

      // Media controls (optional)
      Loader {
        active: Config.lockScreenMediaControls && !compact && SystemStatus.hasActivePlayer
        Layout.maximumWidth: 350
        sourceComponent: MediaWidget {}
      }

      Item { Layout.fillWidth: true }

      // Weather (optional)
      Loader {
        active: Config.lockScreenWeather && !compact && WeatherService.temp !== ""
        sourceComponent: RowLayout {
          spacing: 8
          Text {
            text: Colors.weatherIcon(WeatherService.condition)
            color: Colors.fgSecondary
            font.family: Colors.fontMono
            font.pixelSize: 20
          }
          Text {
            text: (WeatherService.temp || "") + " " + (WeatherService.condition || "")
            color: Colors.fgSecondary
            font.pixelSize: 14
          }
        }
      }

      // Battery
      Text {
        visible: UPower.displayDevice && UPower.displayDevice.isPresent
        text: UPower.displayDevice ? "󰁹 " + Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
        color: Colors.fgSecondary
        font.family: Colors.fontMono
        font.pixelSize: 14
      }

      // Session buttons (optional)
      Loader {
        active: Config.lockScreenSessionButtons
        sourceComponent: RowLayout {
          spacing: 8

          SessionButton { icon: "󰍃"; label: "Logout"; action: "logout" }
          SessionButton { icon: "󰤄"; label: "Suspend"; action: "suspend" }
          SessionButton { icon: "󰜗"; label: "Reboot"; action: "reboot" }
          SessionButton { icon: "󰐥"; label: "Shutdown"; action: "shutdown" }
        }
      }
    }
  }

  // Shake animation on auth failure
  Connections {
    target: lockContext
    function onFailed() {
      shakeAnim.start();
      pwInput.text = "";
    }
    function onUnlocked() {
      pwInput.text = "";
    }
  }

  SequentialAnimation {
    id: shakeAnim
    PropertyAnimation { target: authArea; property: "shakeOffset"; to: 10; duration: 50 }
    PropertyAnimation { target: authArea; property: "shakeOffset"; to: -10; duration: 50 }
    PropertyAnimation { target: authArea; property: "shakeOffset"; to: 0; duration: 50 }
  }

  // Focus password input when visible
  onVisibleChanged: {
    if (visible) pwInput.forceActiveFocus();
  }

  component SessionButton: Rectangle {
    property string icon: ""
    property string label: ""
    property string action: ""

    width: 36; height: 36; radius: 18
    color: sessionMa.containsMouse ? Colors.withAlpha(Colors.text, 0.15) : Colors.withAlpha(Colors.text, 0.05)
    border.color: (root.timerActive && root.pendingAction === action) ? Colors.error : Colors.border
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: parent.icon
      color: (root.timerActive && root.pendingAction === parent.action) ? Colors.error : Colors.fgSecondary
      font.family: Colors.fontMono
      font.pixelSize: 16
    }

    MouseArea {
      id: sessionMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.startTimer(parent.action)
    }

    BarTooltip {
      text: parent.label
      anchorItem: parent
      show: sessionMa.containsMouse
    }
  }
}
