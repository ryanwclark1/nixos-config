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
        title: "UI Appearance"
        iconName: "󰏘"

        SettingsCard {
            title: "Glass Surface"
            iconName: "󰖲"
            description: "Shell-wide blur and translucency settings shared by bars and menus."

            SettingsSliderRow {
                label: "Glass Opacity"
                min: 0.1
                max: 1.0
                value: Config.glassOpacity
                step: 0.05
                onMoved: v => Config.glassOpacity = v
            }

            SettingsModeRow {
                label: "Blur"
                currentValue: Config.blurEnabled ? "enabled" : "disabled"
                options: [
                    { value: "enabled", label: "Enabled" },
                    { value: "disabled", label: "Disabled" }
                ]
                onModeSelected: value => Config.blurEnabled = value === "enabled"
            }
        }
    }
}
