import QtQuick
import QtQuick.Layouts
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 300; popupMaxWidth: 320; compactThreshold: 310
  implicitHeight: compactMode ? 290 : 260
  title: "Privacy"

  SharedWidgets.Ref { service: PrivacyService }

  // Status summary
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: summaryRow.implicitHeight + 20
    radius: Appearance.radiusMedium
    color: PrivacyService.anyActive
      ? Colors.withAlpha(Colors.warning, 0.10)
      : Colors.cardSurface
    border.color: PrivacyService.anyActive ? Colors.withAlpha(Colors.warning, 0.4) : Colors.border
    border.width: 1
    Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }
    Behavior on border.color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationNormal } }

    RowLayout {
      id: summaryRow
      anchors.fill: parent
      anchors.margins: Appearance.spacingM
      spacing: Appearance.spacingM

      Text {
        text: PrivacyService.anyActive ? PrivacyService.activeIcon : "󰒃"
        color: PrivacyService.anyActive ? Colors.warning : Colors.textDisabled
        font.family: Appearance.fontMono
        font.pixelSize: Appearance.fontSizeDisplay
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingXXS

        Text {
          text: PrivacyService.anyActive ? "Active access detected" : "No active access"
          color: PrivacyService.anyActive ? Colors.warning : Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.DemiBold
          wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
          Layout.fillWidth: true
        }

        Text {
          text: PrivacyService.anyActive ? PrivacyService.activeLabel : "Microphone, camera, and screen share are idle"
          color: Colors.textSecondary
          font.pixelSize: Appearance.fontSizeSmall
          wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
          Layout.fillWidth: true
        }
      }
    }
  }

  // Individual source cards
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Appearance.spacingS

    SharedWidgets.PrivacySourceRow { icon: "mic.svg"; label: "Microphone"; active: PrivacyService.micActive }
    SharedWidgets.PrivacySourceRow { icon: "eye.svg"; label: "Camera"; active: PrivacyService.cameraActive }
    SharedWidgets.PrivacySourceRow { icon: "desktop.svg"; label: "Screen Share"; active: PrivacyService.screenshareActive }
  }

  Item { Layout.fillHeight: true }
}
