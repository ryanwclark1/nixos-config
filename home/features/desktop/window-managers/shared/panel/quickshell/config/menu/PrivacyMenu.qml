import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 300; popupMaxWidth: 320; compactThreshold: 310
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
    Behavior on color { ColorAnimation { duration: Colors.durationNormal } }
    Behavior on border.color { ColorAnimation { duration: Colors.durationNormal } }

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
        spacing: Colors.spacingXXS

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

    SharedWidgets.PrivacySourceRow { icon: ""; label: "Microphone"; active: PrivacyService.micActive }
    SharedWidgets.PrivacySourceRow { icon: "󰄀"; label: "Camera"; active: PrivacyService.cameraActive }
    SharedWidgets.PrivacySourceRow { icon: "󰍹"; label: "Screen Share"; active: PrivacyService.screenshareActive }
  }

  Item { Layout.fillHeight: true }
}
