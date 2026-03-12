import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets

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
      color: Colors.background
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
        anchors.margins: Colors.paddingLarge
        spacing: Colors.paddingMedium

        RowLayout {
          spacing: Colors.spacingM
          Text { text: "󰌾"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeHuge }
          Text {
            text: "Authentication Required"
            color: Colors.text
            font.pixelSize: Colors.fontSizeXL
            font.weight: Font.Bold
          }
        }

        Text {
          text: modelData.message
          color: Colors.fgSecondary
          font.pixelSize: Colors.fontSizeSmall
          wrapMode: Text.Wrap
          Layout.fillWidth: true
        }

        // Password Input
        Rectangle {
          Layout.fillWidth: true
          height: 45
          color: Colors.highlightLight
          radius: Colors.radiusXS
          border.color: pwInput.activeFocus ? Colors.primary : "transparent"
          border.width: 1

          TextInput {
            id: pwInput
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            verticalAlignment: Text.AlignVCenter
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            echoMode: TextInput.Password
            focus: true
            
            Keys.onReturnPressed: {
              modelData.authenticate(text);
            }
          }
          
          Text {
            anchors.fill: parent
            anchors.leftMargin: Colors.spacingM
            verticalAlignment: Text.AlignVCenter
            text: "Password..."
            color: Colors.fgDim
            font.pixelSize: Colors.fontSizeMedium
            visible: !pwInput.text && !pwInput.activeFocus
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingM
          
          // Cancel
          Rectangle {
            Layout.fillWidth: true; height: 40; radius: Colors.radiusXS
            color: Colors.highlightLight

            SharedWidgets.StateLayer {
              id: cancelStateLayer
              hovered: cancelHover.containsMouse
              pressed: cancelHover.pressed
            }

            Text { anchors.centerIn: parent; text: "Cancel"; color: Colors.fgSecondary; font.weight: Font.Medium }

            MouseArea {
              id: cancelHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                cancelStateLayer.burst(mouse.x, mouse.y);
                modelData.cancel();
              }
            }
          }

          // Authenticate
          Rectangle {
            Layout.fillWidth: true; height: 40; radius: Colors.radiusXS
            color: Colors.primary

            SharedWidgets.StateLayer {
              id: authStateLayer
              hovered: authHover.containsMouse
              pressed: authHover.pressed
              stateColor: Colors.primary
            }

            Text { anchors.centerIn: parent; text: "Unlock"; color: Colors.text; font.weight: Font.Bold }

            MouseArea {
              id: authHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                authStateLayer.burst(mouse.x, mouse.y);
                modelData.authenticate(pwInput.text);
              }
            }
          }
        }
      }
    }
  }
}
