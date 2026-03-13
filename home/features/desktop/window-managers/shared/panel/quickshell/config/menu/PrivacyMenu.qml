import Quickshell
import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  readonly property int availablePopupWidth: screen ? Math.max(300, screen.width - 40) : 320
  readonly property bool compactMode: availablePopupWidth < 310
  implicitWidth: Math.min(320, availablePopupWidth)
  implicitHeight: compactMode ? 290 : 260
  title: "Privacy"
  toggleMethod: "togglePrivacyMenu"

  SharedWidgets.Ref { service: PrivacyService }

  // Status summary
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: summaryRow.implicitHeight + 20
    radius: Colors.radiusMedium
    color: PrivacyService.anyActive
      ? Colors.withAlpha(Colors.warning, 0.10)
      : Colors.cardSurface
    border.color: PrivacyService.anyActive ? Colors.withAlpha(Colors.warning, 0.4) : Colors.border
    border.width: 1
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    RowLayout {
      id: summaryRow
      anchors.fill: parent
      anchors.margins: Colors.spacingM
      spacing: Colors.spacingM

      Text {
        text: PrivacyService.anyActive ? PrivacyService.activeIcon : "󰒃"
        color: PrivacyService.anyActive ? Colors.warning : Colors.textDisabled
        font.family: Colors.fontMono
        font.pixelSize: 28
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
          text: PrivacyService.anyActive ? "Active access detected" : "No active access"
          color: PrivacyService.anyActive ? Colors.warning : Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.DemiBold
          wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
          Layout.fillWidth: true
        }

        Text {
          text: PrivacyService.anyActive ? PrivacyService.activeLabel : "Microphone, camera, and screen share are idle"
          color: Colors.fgSecondary
          font.pixelSize: Colors.fontSizeSmall
          wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
          Layout.fillWidth: true
        }
      }
    }
  }

  // Individual source cards
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Colors.spacingS

    // Microphone
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: Colors.radiusMedium
      color: PrivacyService.micActive
        ? Colors.withAlpha(Colors.warning, 0.10)
        : Colors.cardSurface
      border.color: PrivacyService.micActive ? Colors.withAlpha(Colors.warning, 0.3) : Colors.border
      border.width: 1
      Behavior on color { ColorAnimation { duration: 200 } }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.paddingSmall

        Text {
          text: ""
          color: PrivacyService.micActive ? Colors.warning : Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeXL
        }

        Text {
          text: "Microphone"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          Layout.fillWidth: true
        }

        // Active indicator
        Rectangle {
          width: 8; height: 8; radius: 4
          color: PrivacyService.micActive ? Colors.warning : Colors.textDisabled
          opacity: PrivacyService.micActive ? 1.0 : 0.3
          Behavior on color { ColorAnimation { duration: 200 } }

          SequentialAnimation on opacity {
            running: PrivacyService.micActive
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.3; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
          }
        }

        Text {
          text: PrivacyService.micActive ? "Active" : "Idle"
          color: PrivacyService.micActive ? Colors.warning : Colors.textDisabled
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.Medium
        }
      }
    }

    // Camera
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: Colors.radiusMedium
      color: PrivacyService.cameraActive
        ? Colors.withAlpha(Colors.warning, 0.10)
        : Colors.cardSurface
      border.color: PrivacyService.cameraActive ? Colors.withAlpha(Colors.warning, 0.3) : Colors.border
      border.width: 1
      Behavior on color { ColorAnimation { duration: 200 } }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.paddingSmall

        Text {
          text: "󰄀"
          color: PrivacyService.cameraActive ? Colors.warning : Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeXL
        }

        Text {
          text: "Camera"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          Layout.fillWidth: true
        }

        Rectangle {
          width: 8; height: 8; radius: 4
          color: PrivacyService.cameraActive ? Colors.warning : Colors.textDisabled
          opacity: PrivacyService.cameraActive ? 1.0 : 0.3
          Behavior on color { ColorAnimation { duration: 200 } }

          SequentialAnimation on opacity {
            running: PrivacyService.cameraActive
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.3; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
          }
        }

        Text {
          text: PrivacyService.cameraActive ? "Active" : "Idle"
          color: PrivacyService.cameraActive ? Colors.warning : Colors.textDisabled
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.Medium
        }
      }
    }

    // Screen Share
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: Colors.radiusMedium
      color: PrivacyService.screenshareActive
        ? Colors.withAlpha(Colors.warning, 0.10)
        : Colors.cardSurface
      border.color: PrivacyService.screenshareActive ? Colors.withAlpha(Colors.warning, 0.3) : Colors.border
      border.width: 1
      Behavior on color { ColorAnimation { duration: 200 } }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.paddingSmall

        Text {
          text: "󰍹"
          color: PrivacyService.screenshareActive ? Colors.warning : Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeXL
        }

        Text {
          text: "Screen Share"
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          Layout.fillWidth: true
        }

        Rectangle {
          width: 8; height: 8; radius: 4
          color: PrivacyService.screenshareActive ? Colors.warning : Colors.textDisabled
          opacity: PrivacyService.screenshareActive ? 1.0 : 0.3
          Behavior on color { ColorAnimation { duration: 200 } }

          SequentialAnimation on opacity {
            running: PrivacyService.screenshareActive
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.3; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
          }
        }

        Text {
          text: PrivacyService.screenshareActive ? "Active" : "Idle"
          color: PrivacyService.screenshareActive ? Colors.warning : Colors.textDisabled
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.Medium
        }
      }
    }
  }

  Item { Layout.fillHeight: true }
}
