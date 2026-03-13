import QtQuick
import QtQuick.Layouts
import "../../../services"
import ".."

Item {
  id: root
  property var settingsRoot: null
  property string tabId: ""

  SettingsTabPage {
    anchors.fill: parent
    tabId: root.tabId
    title: "Privacy"
    iconName: "󰒃"

    SettingsCard {
      title: "Indicators"
      iconName: "󰒃"

      SettingsFieldGrid {
        SettingsToggleRow { label: "Privacy Indicators"; icon: "󰒃"; configKey: "privacyIndicatorsEnabled" }
        SettingsToggleRow { label: "Camera Monitoring"; icon: "󰄀"; configKey: "privacyCameraMonitoring" }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: noteRow.implicitHeight + 24
        radius: Colors.radiusMedium
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08)
        border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
        border.width: 1

        RowLayout {
          id: noteRow
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: Colors.spacingM }
          spacing: Colors.spacingM

          Text {
            text: "󰋗"
            color: Colors.primary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeXL
            Layout.alignment: Qt.AlignTop
          }

          Text {
            text: "Privacy indicators appear in the bar when microphone, camera, or screen sharing is active."
            color: Colors.fgSecondary
            font.pixelSize: Colors.fontSizeMedium
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}
