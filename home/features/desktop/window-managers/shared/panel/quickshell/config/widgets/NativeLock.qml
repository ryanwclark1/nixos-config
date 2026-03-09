import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pam
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

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.isLocked ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-lock"

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
      color: "#000000"
      opacity: 0.6
    }
    // Top: Time & Date
    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 5
      Text {
        text: Qt.formatDateTime(new Date(), "HH:mm")
        color: Colors.fgMain; font.pixelSize: 120; font.weight: Font.Bold
      }
      Text {
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        color: Colors.fgSecondary; font.pixelSize: 24; Layout.alignment: Qt.AlignHCenter
      }
    }

    Item { Layout.fillHeight: true }

    // Middle: Auth Area
    ColumnLayout {
      id: authArea
      Layout.alignment: Qt.AlignHCenter
      spacing: 20
      
      width: 300

      Rectangle {
        Layout.fillWidth: true; height: 50; color: "#1affffff"; radius: 12
        border.color: pwInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        TextInput {
          id: pwInput; anchors.fill: parent; anchors.margins: 15; verticalAlignment: Text.AlignVCenter
          color: "white"; font.pixelSize: 18; echoMode: TextInput.Password; focus: root.isLocked
          
          Keys.onReturnPressed: pam.authenticate(text)
        }
        
        Text {
          anchors.centerIn: parent; text: "Unlock..."; color: Colors.fgDim; font.pixelSize: 16
          visible: !pwInput.text && !pwInput.activeFocus
        }
      }

      Text {
        text: "Type password and press Enter"
        color: Colors.textDisabled; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter
      }
    }

    SequentialAnimation {
      id: shakeAnim
      PropertyAnimation { target: authArea; property: "anchors.horizontalCenterOffset"; from: 0; to: 10; duration: 50 }
      PropertyAnimation { target: authArea; property: "anchors.horizontalCenterOffset"; from: 10; to: -10; duration: 50 }
      PropertyAnimation { target: authArea; property: "anchors.horizontalCenterOffset"; from: -10; to: 0; duration: 50 }
    }

    Item { Layout.fillHeight: true }

    // Bottom: Widgets
    RowLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignBottom
      spacing: 40

      // Integrated Media
      MediaWidget { Layout.maximumWidth: 400 }

      Item { Layout.fillWidth: true }

      // System Health
      RowLayout {
        spacing: 20
        SystemMonitor {}
        Text { text: "󰁹 85%"; color: Colors.fgSecondary; font.family: Colors.fontMono }
      }
    }
  }
}
