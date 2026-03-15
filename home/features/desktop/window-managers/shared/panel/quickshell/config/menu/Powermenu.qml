import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets

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
  visible: isVisible || pmFadeAnim.running || pmScaleAnim.running

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

  readonly property var actions: SystemActionRegistry.sessionActions

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
        opacity: root.isVisible ? 0.75 : 0.0
        Behavior on opacity { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutCubic } }
      }
    }

    // Power Menu Content
    ColumnLayout {
      id: contentCol
      anchors.centerIn: parent
      spacing: 48
      scale: root.isVisible ? 1.0 : 0.94
      Behavior on scale { NumberAnimation { id: pmScaleAnim; duration: 500; easing.type: Easing.OutBack } }
      opacity: root.isVisible ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { id: pmFadeAnim; duration: Colors.durationEmphasis; easing.type: Easing.OutCubic } }
      layer.enabled: pmScaleAnim.running || pmFadeAnim.running

      ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Colors.spacingXS
        Text {
          text: "Power Menu"
          color: Colors.text
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.Bold
          font.letterSpacing: Colors.letterSpacingTight
          Layout.alignment: Qt.AlignHCenter
        }

        // Uptime display
        Text {
          visible: root.uptimeText !== ""
          text: "system uptime: " + root.uptimeText
          color: Colors.primary
          opacity: 0.8
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.Medium
          Layout.alignment: Qt.AlignHCenter
        }
      }

      RowLayout {
        spacing: Colors.spacingXL

        Repeater {
          model: root.actions

          delegate: Item {
            id: actionItem
            width: 140; height: 140

            property bool isPending: root.timerActive && root.pendingAction === modelData.id
            property bool isFocused: root.currentIndex === index
            property color actionColor: {
              switch (modelData.id) {
              case "shutdown": return Colors.error;
              case "reboot": return Colors.accent;
              case "lock": return Colors.primary;
              case "logout": return Colors.info;
              case "suspend": return Colors.success;
              default: return Colors.textSecondary;
              }
            }
            property color activeColor: modelData.danger ? Colors.error : Colors.primary

            // Staggered entry
            opacity: root.isVisible ? 1.0 : 0.0
            scale: root.isVisible ? 1.0 : 0.8
            transform: Translate { y: root.isVisible ? 0 : 20 }
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: index * 40 } NumberAnimation { duration: 400; easing.type: Easing.OutCubic } } }
            Behavior on scale { SequentialAnimation { PauseAnimation { duration: index * 40 } NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
            Behavior on transform { SequentialAnimation { PauseAnimation { duration: index * 40 } NumberAnimation { duration: 450; easing.type: Easing.OutCubic } } }

            // Layer 1: Base
            Rectangle {
              id: baseLayer
              anchors.fill: parent
              radius: Colors.radiusLarge
              color: Colors.withAlpha(Colors.surface, 0.4)
              border.color: actionItem.isFocused ? actionItem.actionColor : Colors.border
              border.width: actionItem.isFocused ? 2 : 1
              Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

              gradient: Gradient {
    orientation: Gradient.Vertical
    GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
    GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
}

              SharedWidgets.InnerHighlight { hoveredOpacity: 0.3; hovered: actionItem.isFocused }
            }

            // Layer 2: Pending indicator (circular progress-like)
            Rectangle {
              anchors.fill: parent
              radius: Colors.radiusLarge
              color: actionItem.actionColor
              opacity: actionItem.isPending ? 0.15 : 0.0
              Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
            }

            ColumnLayout {
              anchors.centerIn: parent
              spacing: Colors.spacingM
              Item {
                width: 48; height: 48
                Layout.alignment: Qt.AlignHCenter
                Text {
                  anchors.centerIn: parent
                  text: isPending ? Math.ceil(root.timeRemaining / 1000).toString() : modelData.icon
                  color: actionItem.isFocused ? Colors.text : actionItem.actionColor
                  font.family: isPending ? undefined : Colors.fontMono
                  font.pixelSize: isPending ? 32 : 44
                  font.weight: isPending ? Font.Bold : Font.Normal
                  Behavior on color { ColorAnimation { duration: Colors.durationFast } }
                }
              }
              Text {
                text: modelData.label
                color: actionItem.isFocused ? Colors.text : Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                font.weight: actionItem.isFocused ? Font.Bold : Font.Medium
                Layout.alignment: Qt.AlignHCenter
                Behavior on color { ColorAnimation { duration: Colors.durationFast } }
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.startTimer(modelData.id, modelData.cmd)
              onEntered: root.currentIndex = index
            }
          }
        }
      }

      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 300; height: 40; radius: 20
        color: Colors.withAlpha(Colors.surface, 0.3)
        visible: root.timerActive
        border.color: Colors.border
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "Click again to confirm, ESC to cancel"
          color: Colors.text
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.Medium
        }
      }

      Text {
        visible: !root.timerActive
        text: "Press ESC to cancel"
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeSmall
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
