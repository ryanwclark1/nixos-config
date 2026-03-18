import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../../widgets" as SharedWidgets

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

  function startTimer(actionId) {
    var key = String(actionId || "");
    if (!key)
      return;
    if (timerActive && pendingAction === key) {
      executeAction(key);
      return;
    }
    pendingAction = key;
    timeRemaining = Config.powermenuCountdown;
    timerActive = true;
  }

  function cancelTimer() {
    pendingAction = "";
    timerActive = false;
    timeRemaining = 0;
  }

  function executeAction(actionId) {
    cancelTimer();
    root.isVisible = false;
    SystemActionRegistry.execute(actionId);
  }

  Timer {
    id: countdownTimer
    interval: 100
    running: root.timerActive
    repeat: true
    onTriggered: {
      root.timeRemaining -= 100;
      if (root.timeRemaining <= 0)
        root.executeAction(root.pendingAction);
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
          root.startTimer(action.id);
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
        opacity: root.isVisible ? 0.92 : 0.0
        Behavior on opacity { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutCubic } }
      }
    }

    // Power Menu Content
    ColumnLayout {
      id: contentCol
      anchors.centerIn: parent
      spacing: 64
      scale: root.isVisible ? 1.0 : 0.92
      Behavior on scale { NumberAnimation { id: pmScaleAnim; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
      opacity: root.isVisible ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { id: pmFadeAnim; duration: Colors.durationEmphasis; easing.type: Easing.OutCubic } }
      layer.enabled: pmScaleAnim.running || pmFadeAnim.running

      ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Colors.spacingS
        Text {
          text: "System Session"
          color: Colors.text
          font.pixelSize: 42
          font.weight: Font.Bold
          font.letterSpacing: -1
          Layout.alignment: Qt.AlignHCenter
        }

        // Uptime display
        Text {
          visible: root.uptimeText !== ""
          text: "system uptime: " + root.uptimeText
          color: Colors.primary
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Medium
          Layout.alignment: Qt.AlignHCenter
        }
      }

      RowLayout {
        spacing: 32

        Repeater {
          model: root.actions

          delegate: Item {
            id: actionItem
            width: 160; height: 160

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

            // Staggered entry
            opacity: root.isVisible ? 1.0 : 0.0
            scale: root.isVisible ? 1.0 : 0.7
            transform: Translate { y: root.isVisible ? 0 : 30 }
            Behavior on opacity { SequentialAnimation { id: actionFadeAnim; PauseAnimation { duration: index * 50 } NumberAnimation { duration: Colors.durationEmphasis; easing.type: Easing.OutCubic } } }
            Behavior on scale { SequentialAnimation { id: actionScaleAnim; PauseAnimation { duration: index * 50 } NumberAnimation { duration: 550; easing.type: Easing.OutBack } } }
            Behavior on transform { SequentialAnimation { PauseAnimation { duration: index * 50 } NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
            layer.enabled: actionFadeAnim.running || actionScaleAnim.running

            // Layer 1: Base
            Rectangle {
              id: baseLayer
              anchors.fill: parent
              radius: Colors.radiusLarge
              color: Colors.cardSurface
              border.color: actionItem.isFocused ? actionItem.actionColor : Colors.border
              border.width: actionItem.isFocused ? 3 : 1
              Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }


              SharedWidgets.InnerHighlight { highlightOpacity: actionItem.isFocused ? 0.25 : 0.12 }
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
                  font.family: isPending ? "" : Colors.fontMono
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
              onClicked: root.startTimer(modelData.id)
              onEntered: root.currentIndex = index
            }
          }
        }
      }

      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 300; height: 40; radius: Colors.radiusLarge
        color: Colors.cardSurface
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
