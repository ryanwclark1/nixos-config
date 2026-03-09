import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
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
  
  visible: Polkit.activeSessions.count > 0
  
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-auth"

  // Backdrop
  MouseArea {
    anchors.fill: parent
    Rectangle {
      anchors.fill: parent
      color: "#000000"
      opacity: root.visible ? 0.5 : 0.0
      Behavior on opacity { NumberAnimation { duration: 200 } }
    }
  }

  Repeater {
    model: Polkit.activeSessions

    Rectangle {
      id: authBox
      width: 400
      height: 220
      anchors.centerIn: parent
      color: Colors.bgGlass
      border.color: Colors.primary
      border.width: 1
      radius: 16
      clip: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 15

        RowLayout {
          spacing: 12
          Text { text: "󰌾"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 24 }
          Text {
            text: "Authentication Required"
            color: Colors.fgMain
            font.pixelSize: 18
            font.weight: Font.Bold
          }
        }

        Text {
          text: modelData.message
          color: Colors.fgSecondary
          font.pixelSize: 12
          wrapMode: Text.Wrap
          Layout.fillWidth: true
        }

        // Password Input
        Rectangle {
          Layout.fillWidth: true
          height: 45
          color: "#1affffff"
          radius: 8
          border.color: pwInput.activeFocus ? Colors.primary : "transparent"
          border.width: 1

          TextInput {
            id: pwInput
            anchors.fill: parent
            anchors.margins: 12
            verticalAlignment: Text.AlignVCenter
            color: Colors.fgMain
            font.pixelSize: 14
            echoMode: TextInput.Password
            focus: true
            
            Keys.onReturnPressed: {
              modelData.authenticate(text);
            }
          }
          
          Text {
            anchors.fill: parent
            anchors.leftMargin: 12
            verticalAlignment: Text.AlignVCenter
            text: "Password..."
            color: Colors.fgDim
            font.pixelSize: 14
            visible: !pwInput.text && !pwInput.activeFocus
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 12
          
          // Cancel
          Rectangle {
            Layout.fillWidth: true; height: 40; color: Colors.highlightLight; radius: 8
            Text { anchors.centerIn: parent; text: "Cancel"; color: Colors.fgSecondary; font.weight: Font.Medium }
            MouseArea { anchors.fill: parent; onClicked: modelData.cancel() }
          }

          // Authenticate
          Rectangle {
            Layout.fillWidth: true; height: 40; color: Colors.primary; radius: 8
            Text { anchors.centerIn: parent; text: "Unlock"; color: "#ffffff"; font.weight: Font.Bold }
            MouseArea { anchors.fill: parent; onClicked: modelData.authenticate(pwInput.text) }
          }
        }
      }
    }
  }
}
