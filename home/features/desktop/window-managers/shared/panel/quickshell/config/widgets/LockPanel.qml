import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../services"
import "../modules"

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
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: compact ? 2 : 5

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(lockClock.date, "HH:mm")
        color: Colors.text
        font.pixelSize: compact ? 80 : 120
        font.weight: Font.Bold
      }
      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(lockClock.date, "dddd, MMMM d")
        color: Colors.textSecondary
        font.pixelSize: compact ? 18 : 24
      }
    }

    Item { Layout.fillHeight: true; Layout.preferredHeight: compact ? 20 : 60 }

    // Auth area
    ColumnLayout {
      id: authArea
      Layout.alignment: Qt.AlignHCenter
      spacing: Colors.spacingL
      Layout.preferredWidth: 300

      property real shakeOffset: 0
      transform: Translate { x: authArea.shakeOffset }

      // Password input
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        color: Colors.highlightLight
        radius: Colors.radiusCard
        border.color: pwInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: Colors.spacingM
          spacing: Colors.paddingSmall

          Text {
            text: "󰌾"
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeXL
          }

          TextInput {
            id: pwInput
            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
            color: Colors.text
            font.pixelSize: Colors.fontSizeXL
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
            width: 28; height: 28; radius: Colors.radiusMedium
            color: Colors.withAlpha(Colors.primary, 0.6)
            visible: pwInput.text.length > 0

            Text {
              anchors.centerIn: parent
              text: "󰁔"
              color: Colors.background
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeMedium
            }

            StateLayer {
              id: submitStateLayer
              hovered: submitMa.containsMouse
              pressed: submitMa.pressed
              stateColor: Colors.primary
            }

            MouseArea {
              id: submitMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                submitStateLayer.burst(mouse.x, mouse.y);
                if (lockContext) lockContext.tryUnlock();
              }
            }
          }
        }

        // Placeholder
        Text {
          anchors.centerIn: parent
          text: "Unlock..."
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeLarge
          visible: !pwInput.text && !pwInput.activeFocus
        }
      }

      // Error message
      Text {
        Layout.alignment: Qt.AlignHCenter
        text: lockContext ? lockContext.errorMessage : ""
        color: Colors.error
        font.pixelSize: Colors.fontSizeSmall
        font.weight: Font.Medium
        visible: lockContext ? lockContext.showError : false
      }

      // Unlock in progress indicator
      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Authenticating..."
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeSmall
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
          spacing: Colors.spacingS

          Text {
            text: root.pendingAction.charAt(0).toUpperCase() + root.pendingAction.slice(1) + " in " + Math.ceil(root.timeRemaining / 1000) + "s"
            color: Colors.error
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.Medium
          }

          Rectangle {
            width: 20; height: 20; radius: Colors.radiusSmall
            color: "transparent"
            border.color: Colors.error; border.width: 1

            StateLayer {
              id: cancelStateLayer
              hovered: cancelMa.containsMouse
              pressed: cancelMa.pressed
              stateColor: Colors.error
            }

            Text {
              anchors.centerIn: parent
              text: "󰅖"
              color: Colors.error
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeXS
            }

            MouseArea {
              id: cancelMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                cancelStateLayer.burst(mouse.x, mouse.y);
                root.cancelTimer();
              }
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
      spacing: Colors.spacingLG

      // Media controls (optional)
      Loader {
        active: Config.lockScreenMediaControls && !compact && SystemStatus.hasActivePlayer
        Layout.maximumWidth: 350
        sourceComponent: Rectangle {
          implicitWidth: 320
          implicitHeight: 60
          radius: Colors.radiusCard
          color: Colors.withAlpha(Colors.background, 0.4)
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.paddingSmall

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingXXS
              Text {
                text: MediaService.trackTitle || ""
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
              Text {
                text: MediaService.trackArtist || ""
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            Text {
              text: MediaService.isPlaying ? "󰏤" : "󰐊"
              color: Colors.text
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeHuge
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: MediaService.playPause()
              }
            }
          }
        }
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
        sourceComponent: RowLayout {
          spacing: Colors.spacingS

          SessionButton {
            readonly property var actionMeta: SystemActionRegistry.actionById("logout") || ({})
            icon: String(actionMeta.icon || "")
            label: String(actionMeta.label || actionMeta.name || "")
            action: "logout"
          }
          SessionButton { icon: "󰤄"; label: "Suspend"; action: "suspend" }
          Repeater {
            model: root.lockPowerButtons
            delegate: SessionButton {
              required property var modelData
              icon: String(modelData.icon || "")
              label: String(modelData.label || modelData.name || "")
              action: String(modelData.id || "")
            }
          }
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

    width: 36; height: 36; radius: height / 2
    color: Colors.withAlpha(Colors.text, 0.05)
    border.color: (root.timerActive && root.pendingAction === action) ? Colors.error : Colors.border
    border.width: 1
    Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

    StateLayer {
      id: sessionStateLayer
      hovered: sessionMa.containsMouse
      pressed: sessionMa.pressed
    }

    Text {
      anchors.centerIn: parent
      text: parent.icon
      color: (root.timerActive && root.pendingAction === parent.action) ? Colors.error : Colors.textSecondary
      Behavior on color { ColorAnimation { duration: Colors.durationFast } }
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeLarge
    }

    MouseArea {
      id: sessionMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: (mouse) => {
        sessionStateLayer.burst(mouse.x, mouse.y);
        root.startTimer(parent.action);
      }
    }

    BarTooltip {
      text: parent.label
      anchorItem: parent
      hovered: sessionMa.containsMouse
    }
  }
}
