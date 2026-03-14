import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

PanelWindow {
  id: root

  property var screenRef: screen || Quickshell.cursorScreen || Config.primaryScreen()
  screen: screenRef
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
  readonly property real usableWidth: screenRef ? Math.max(1, screenRef.width - edgeMargins.left - edgeMargins.right) : width
  readonly property real usableHeight: screenRef ? Math.max(1, screenRef.height - edgeMargins.top - edgeMargins.bottom) : height

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  color: "transparent"

  property bool isVisible: false
  visible: isVisible || _unmapDelay.running
  Timer { id: _unmapDelay; interval: 350 }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell"

  // ── Countdown state ────────────────────────────
  property string pendingAction: ""
  property var pendingCmd: null
  property bool timerActive: false
  property int timeRemaining: 0

  // ── Keyboard navigation ────────────────────────
  property int currentIndex: -1

  readonly property var actions: [
    { key: "shutdown", icon: "󰐥", label: "Shutdown", color: Colors.error, danger: true, cmd: ["systemctl", "poweroff"] },
    { key: "reboot", icon: "󰑐", label: "Reboot", color: Colors.accent, danger: true, cmd: ["systemctl", "reboot"] },
    { key: "lock", icon: "󰌾", label: "Lock", color: Colors.primary, danger: false, cmd: CompositorAdapter.lockCommand() },
    { key: "logout", icon: "󰗽", label: "Logout", color: Colors.textSecondary, danger: false, cmd: CompositorAdapter.logoutCommand() }
  ]

  // ── Uptime ─────────────────────────────────────
  property string uptimeText: ""
  Process {
    id: uptimeProc
    command: ["sh", "-c", "uptime -p | sed 's/^up //'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: root.uptimeText = (this.text || "").trim()
    }
  }

  onIsVisibleChanged: {
    if (isVisible) {
      uptimeProc.running = true;
      currentIndex = -1;
    } else {
      _unmapDelay.restart();
      cancelTimer();
    }
  }

  function startTimer(key, cmd) {
    if (timerActive && pendingAction === key) {
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

  Item {
    anchors.fill: parent
    visible: root.isVisible
    focus: root.isVisible

    Keys.onEscapePressed: {
      if (root.timerActive) root.cancelTimer();
      else root.isVisible = false;
    }

    Keys.onPressed: (event) => {
      if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
        root.currentIndex = Math.max(0, root.currentIndex - 1);
        event.accepted = true;
      } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
        root.currentIndex = Math.min(root.actions.length - 1, root.currentIndex + 1);
        event.accepted = true;
      } else if (event.key === Qt.Key_Tab) {
        root.currentIndex = (root.currentIndex + 1) % root.actions.length;
        event.accepted = true;
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (root.currentIndex >= 0 && root.currentIndex < root.actions.length) {
          var action = root.actions[root.currentIndex];
          root.startTimer(action.key, action.cmd);
        }
        event.accepted = true;
      }
    }

    // Backdrop
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
        Behavior on opacity { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutCubic } }
      }
    }

    // Power Menu Content
    ColumnLayout {
      id: contentCol
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.topMargin: root.edgeMargins.top + Math.max(20, (root.usableHeight - height) / 2)
      anchors.leftMargin: root.edgeMargins.left + Math.max(20, (root.usableWidth - width) / 2)
      spacing: 40
      scale: root.isVisible ? 1.0 : 0.9
      Behavior on scale { NumberAnimation { id: pmScaleAnim; duration: Colors.durationSlow; easing.type: Easing.OutBack } }
      opacity: root.isVisible ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { id: pmFadeAnim; duration: Colors.durationSlow; easing.type: Easing.OutCubic } }
      layer.enabled: pmScaleAnim.running || pmFadeAnim.running

      Text {
        text: "Power Menu"
        color: Colors.text
        font.pixelSize: Colors.fontSizeIcon
        font.weight: Font.Bold
        Layout.alignment: Qt.AlignHCenter
      }

      // Uptime display
      Text {
        visible: root.uptimeText !== ""
        text: "up " + root.uptimeText
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeMedium
        font.family: Colors.fontMono
        Layout.alignment: Qt.AlignHCenter
      }

      RowLayout {
        spacing: Colors.spacingLG

        Repeater {
          model: root.actions

          delegate: Item {
            width: 120; height: 120

            property bool isPending: root.timerActive && root.pendingAction === modelData.key
            property bool isFocused: root.currentIndex === index
            property color activeColor: modelData.danger ? Colors.error : Colors.primary

            // Layer 1: Base (stable, never animated)
            Rectangle {
              id: baseLayer
              anchors.fill: parent
              radius: Colors.radiusLarge
              color: Colors.highlightLight
            }

            // Layer 2: Hover overlay
            Rectangle {
              anchors.fill: parent
              radius: Colors.radiusLarge
              color: Colors.highlight
              opacity: mouseArea.containsMouse || parent.isFocused ? 1.0 : 0.0
              Behavior on opacity { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }
            }

            // Layer 3: Active/pending overlay
            Rectangle {
              anchors.fill: parent
              radius: Colors.radiusLarge
              color: parent.activeColor
              opacity: parent.isPending ? 0.3 : 0.0
              Behavior on opacity { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }
            }

            // Focus/pending border
            Rectangle {
              anchors.fill: parent
              radius: Colors.radiusLarge
              color: "transparent"
              border.color: parent.isPending ? parent.activeColor
                : parent.isFocused ? Colors.primary
                : mouseArea.containsMouse ? modelData.color
                : Colors.border
              border.width: parent.isPending ? 3 : (parent.isFocused ? 2 : 2)
              Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }
            }

            ColumnLayout {
              anchors.centerIn: parent
              spacing: Colors.paddingSmall
              Text {
                text: isPending ? Math.ceil(root.timeRemaining / 1000).toString() : modelData.icon
                color: isPending ? parent.parent.activeColor : modelData.color
                font.family: isPending ? undefined : Colors.fontMono
                font.pixelSize: isPending ? 36 : 40
                font.weight: isPending ? Font.Bold : Font.Normal
                Layout.alignment: Qt.AlignHCenter
              }
              Text {
                text: modelData.label
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.startTimer(modelData.key, modelData.cmd)
              onContainsMouseChanged: {
                if (containsMouse) root.currentIndex = index;
              }
            }
          }
        }
      }

      Text {
        text: root.timerActive ? "Click again to confirm, ESC to cancel" : "Press ESC to cancel"
        color: root.timerActive ? Colors.primary : Colors.textDisabled
        font.pixelSize: Colors.fontSizeMedium
        Layout.alignment: Qt.AlignHCenter
        Behavior on color { ColorAnimation { duration: Colors.durationFast } }
      }
    }
  }
}
