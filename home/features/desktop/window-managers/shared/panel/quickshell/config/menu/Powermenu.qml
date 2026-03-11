import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

PanelWindow {
  id: root

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  color: "transparent"

  property bool isVisible: false
  visible: isVisible

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell"

  // ── Countdown state ────────────────────────────
  property string pendingAction: ""
  property var pendingCmd: null
  property bool timerActive: false
  property int timeRemaining: 0

  function startTimer(key, cmd) {
    if (timerActive && pendingAction === key) {
      // Double-click confirm: execute immediately
      executeAction(cmd);
      return;
    }
    pendingAction = key;
    pendingCmd = cmd;
    timeRemaining = Config.powermenuCountdown;
    timerActive = true;
  }

  function cancelTimer() {
    pendingAction = "";
    pendingCmd = null;
    timerActive = false;
    timeRemaining = 0;
  }

  function executeAction(cmd) {
    cancelTimer();
    root.isVisible = false;
    Quickshell.execDetached(cmd);
  }

  Timer {
    id: countdownTimer
    interval: 100
    running: root.timerActive
    repeat: true
    onTriggered: {
      root.timeRemaining -= 100;
      if (root.timeRemaining <= 0) {
        var cmd = root.pendingCmd;
        root.executeAction(cmd);
      }
    }
  }

  // Reset countdown when menu closes
  onIsVisibleChanged: if (!isVisible) cancelTimer()

  Item {
    anchors.fill: parent
    visible: root.isVisible
    focus: root.isVisible

    Keys.onEscapePressed: {
      if (root.timerActive) root.cancelTimer();
      else root.isVisible = false;
    }

    // Backdrop to close
    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (root.timerActive) root.cancelTimer();
        else root.isVisible = false;
      }

      Rectangle {
        anchors.fill: parent
        color: Colors.background
        opacity: root.isVisible ? 0.4 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
      }
    }

    // Power Menu Content
    ColumnLayout {
      id: contentCol
      anchors.centerIn: parent
      spacing: 40
      scale: root.isVisible ? 1.0 : 0.9
      Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
      opacity: root.isVisible ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

      Text {
        text: "Power Menu"
        color: Colors.fgMain
        font.pixelSize: 32
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignHCenter
      }

      RowLayout {
        spacing: 20

        Repeater {
          model: [
            { key: "shutdown", icon: "󰐥", label: "Shutdown", color: Colors.error, cmd: ["systemctl", "poweroff"] },
            { key: "reboot", icon: "󰑐", label: "Reboot", color: Colors.accent, cmd: ["systemctl", "reboot"] },
            { key: "lock", icon: "󰌾", label: "Lock", color: Colors.primary, cmd: ["hyprlock"] },
            { key: "logout", icon: "󰗽", label: "Logout", color: Colors.fgSecondary, cmd: ["hyprctl", "dispatch", "exit"] }
          ]

          delegate: Rectangle {
            id: btn
            width: 120; height: 120
            radius: 20

            property bool isPending: root.timerActive && root.pendingAction === modelData.key

            color: mouseArea.containsMouse ? Colors.highlight : Colors.highlightLight
            border.color: isPending ? Colors.primary : (mouseArea.containsMouse ? modelData.color : Colors.border)
            border.width: isPending ? 3 : 2

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 10
              Text {
                text: btn.isPending ? Math.ceil(root.timeRemaining / 1000).toString() : modelData.icon
                color: btn.isPending ? Colors.primary : modelData.color
                font.family: btn.isPending ? undefined : Colors.fontMono
                font.pixelSize: btn.isPending ? 36 : 40
                font.weight: btn.isPending ? Font.Bold : Font.Normal
                Layout.alignment: Qt.AlignHCenter
              }
              Text {
                text: modelData.label
                color: Colors.fgMain
                font.pixelSize: 12
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.startTimer(modelData.key, modelData.cmd)
            }
          }
        }
      }

      Text {
        text: root.timerActive ? "Click again to confirm, ESC to cancel" : "Press ESC to cancel"
        color: root.timerActive ? Colors.primary : Colors.fgDim
        font.pixelSize: 12
        Layout.alignment: Qt.AlignHCenter
        Behavior on color { ColorAnimation { duration: 200 } }
      }
    }
  }
}
