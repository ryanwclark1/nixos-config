import QtQuick
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

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
                    {
                        value: "enabled",
                        label: "Enabled"
                    },
                    {
                        value: "disabled",
                        label: "Disabled"
                    }
                ]
                onModeSelected: value => Config.blurEnabled = value === "enabled"
            }
        }

        SettingsCard {
            title: "Typography"
            iconName: "󰛖"
            description: "Font families and sizing are appearance settings, independent from the active color theme."

            SettingsTextInputRow {
                label: "Primary Font Family"
                placeholderText: "Inter"
                leadingIcon: "󰛖"
                text: Config.fontFamily
                onTextEdited: value => Config.fontFamily = value
            }

            SettingsTextInputRow {
                label: "Monospace Font Family"
                placeholderText: "JetBrainsMono Nerd Font"
                leadingIcon: "󰍛"
                text: Config.monoFontFamily
                onTextEdited: value => Config.monoFontFamily = value
            }

            SettingsSliderRow {
                label: "Font Scale"
                min: 0.85
                max: 1.35
                value: Config.fontScale
                step: 0.05
                onMoved: v => Config.fontScale = v
            }
        }

        SettingsCard {
            title: "Shape & Density"
            iconName: "󰉵"
            description: "Tune radius and spacing without changing the selected color theme."

            SettingsSliderRow {
                label: "Corner Radius Scale"
                min: 0.8
                max: 1.35
                value: Config.radiusScale
                step: 0.05
                onMoved: v => Config.radiusScale = v
            }

            SettingsSliderRow {
                label: "Spacing Scale"
                min: 0.85
                max: 1.35
                value: Config.spacingScale
                step: 0.05
                onMoved: v => Config.spacingScale = v
            }
        }
    }
}
