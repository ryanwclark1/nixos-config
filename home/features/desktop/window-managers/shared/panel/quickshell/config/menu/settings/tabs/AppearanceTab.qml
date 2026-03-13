import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
  id: root
  property var settingsRoot: null
  property string tabId: ""

  SettingsTabPage {
    anchors.fill: parent
    tabId: root.tabId
    title: "UI Appearance"
    iconName: "󰏘"

    SettingsCard {
      title: "Bar"
      iconName: "󰏘"

      SettingsSliderRow { label: "Bar Height"; min: 20; max: 60; value: Config.barHeight; onMoved: (v) => Config.barHeight = v }
      SettingsSliderRow { label: "Bar Margin"; min: 0; max: 40; value: Config.barMargin; onMoved: (v) => Config.barMargin = v }
      SettingsSliderRow { label: "Bar Opacity"; min: 0.3; max: 1.0; value: Config.barOpacity; step: 0.05; unit: "%"; onMoved: (v) => Config.barOpacity = v }
      SettingsSliderRow { label: "Glass Opacity"; min: 0.1; max: 1.0; value: Config.glassOpacity; step: 0.05; onMoved: (v) => Config.glassOpacity = v }

      RowLayout {
        spacing: Colors.spacingXL
        Layout.fillWidth: true
        Text { text: "Floating Bar"; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; Layout.fillWidth: true }
        SharedWidgets.DankToggle { checked: Config.barFloating; onToggled: Config.barFloating = !Config.barFloating }
      }
    }
  }
}
