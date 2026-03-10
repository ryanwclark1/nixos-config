import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import "../services"
import "../modules"

PanelWindow {
  id: root
  
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  color: "transparent"

  property bool isLocked: false
  visible: isLocked

  SystemClock {
    id: lockClock
    precision: SystemClock.Minutes
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.isLocked ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-lock"

  onIsLockedChanged: {
    if (isLocked) {
      pwInput.forceActiveFocus();
    } else {
      pwInput.text = "";
    }
  }

  Item {
    anchors.fill: parent
    opacity: root.isLocked ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    // PAM Session logic
    PamContext {
      id: pam
      onCompleted: (result) => {
        if (result === PamResult.Success) {
          root.isLocked = false;
          pwInput.text = "";
        } else {
          pwInput.text = "";
          shakeAnim.start();
        }
      }
    }

    IpcHandler {
      target: "Lockscreen"
      function lock() { root.isLocked = true; }
      function unlock() { root.isLocked = false; }
    }

    Rectangle {
      anchors.fill: parent
      color: Colors.background
      opacity: 0.6
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 120
      spacing: 5

      Text {
        text: Qt.formatDateTime(lockClock.date, "HH:mm")
        color: Colors.fgMain; font.pixelSize: 120; font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
      }
      Text {
        text: Qt.formatDateTime(lockClock.date, "dddd, MMMM d")
        color: Colors.fgSecondary; font.pixelSize: 24
        horizontalAlignment: Text.AlignHCenter
      }
    }

    // Middle: Auth Area
    Column {
      id: authArea
      anchors.centerIn: parent
      spacing: 20
      width: 300

      Rectangle {
        width: parent.width; height: 50; color: Colors.highlightLight; radius: 12
        border.color: pwInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        TextInput {
          id: pwInput; anchors.fill: parent; anchors.margins: Colors.paddingMedium; verticalAlignment: Text.AlignVCenter
          color: Colors.text; font.pixelSize: 18; echoMode: TextInput.Password; focus: root.isLocked
          
          Keys.onReturnPressed: pam.authenticate(text)
          Keys.onEscapePressed: text = ""
        }
        
        Text {
          anchors.centerIn: parent; text: "Unlock..."; color: Colors.fgDim; font.pixelSize: 16
          visible: !pwInput.text && !pwInput.activeFocus
        }
      }

      Text {
        text: "Type password and press Enter"
        color: Colors.textDisabled; font.pixelSize: 11
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }

    SequentialAnimation {
      id: shakeAnim
      PropertyAnimation { target: authArea; property: "x"; from: authArea.x; to: authArea.x + 10; duration: 50 }
      PropertyAnimation { target: authArea; property: "x"; from: authArea.x + 10; to: authArea.x - 10; duration: 50 }
      PropertyAnimation { target: authArea; property: "x"; from: authArea.x - 10; to: authArea.x; duration: 50 }
    }

    // Bottom: Widgets
    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 40
      spacing: 40

      // Integrated Media
      MediaWidget { Layout.maximumWidth: 400 }

      Item { Layout.fillWidth: true }

      // System Health
      RowLayout {
        spacing: 20
        SystemMonitor {}
        Text {
          visible: UPower.displayDevice && UPower.displayDevice.isPresent
          text: UPower.displayDevice ? "󰁹 " + Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
          color: Colors.fgSecondary
          font.family: Colors.fontMono
        }
      }
    }
  }
}
