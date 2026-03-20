import QtQuick
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Style & Motion"
        iconName: "󰏘"

        SettingsCard {
            title: "Glass Surface"
            iconName: "󰖲"
            description: "Shell-wide blur and tiered transparency settings for bars and menus."

            SettingsSliderRow {
                label: "Base Opacity"
                description: "Used for main bars and panels."
                min: 0.1
                max: 1.0
                value: Config.glassOpacityBase
                step: 0.05
                onMoved: v => Config.glassOpacityBase = v
            }

            SettingsSliderRow {
                label: "Surface Opacity"
                description: "Used for menu items and cards."
                min: 0.1
                max: 1.0
                value: Config.glassOpacitySurface
                step: 0.05
                onMoved: v => Config.glassOpacitySurface = v
            }

            SettingsSliderRow {
                label: "Overlay Opacity"
                description: "Used for tooltips and floating OSDs."
                min: 0.1
                max: 1.0
                value: Config.glassOpacityOverlay
                step: 0.05
                onMoved: v => Config.glassOpacityOverlay = v
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

            SettingsToggleRow {
                label: "Auto Transparency"
                icon: "color-palette.svg"
                configKey: "autoTransparency"
            }
        }

        SettingsCard {
            title: "Theme Mode"
            iconName: "󰏘"
            description: "Choose how shell colors are derived from your wallpaper."

            SettingsModeRow {
                label: "Color Backend"
                currentValue: Config.colorBackend || "pywal"
                options: [
                    { value: "pywal", label: "Pywal" },
                    { value: "matugen", label: "Material You" },
                    { value: "dynamic", label: "Dynamic" }
                ]
                onModeSelected: value => Config.colorBackend = value
            }

            SettingsToggleRow {
                label: "Dynamic Wallpaper Theming"
                icon: "image.svg"
                configKey: "useDynamicTheming"
            }
        }

        SettingsCard {
            title: "Power Management"
            iconName: "󰂄"
            description: "Control how the shell behaves when running on battery."

            SettingsToggleRow {
                label: "Automatic Eco Mode"
                description: "Optimizes animations and disables shaders on battery."
                icon: "leaf-two.svg"
                configKey: "autoEcoMode"
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
            description: "Tune scaling and responsiveness globally."

            SettingsSliderRow {
                label: "Corner Radius Scale"
                min: 0.8
                max: 1.35
                value: Config.radiusScale
                step: 0.05
                onMoved: v => Config.radiusScale = v
            }

            SettingsSliderRow {
                label: "UI Density Scale"
                min: 0.85
                max: 1.35
                value: Config.uiDensityScale
                step: 0.05
                onMoved: v => Config.uiDensityScale = v
            }

            SettingsSliderRow {
                label: "Animation Speed Scale"
                description: "0.5 = Fast, 1.5 = Slow"
                min: 0.0
                max: 2.0
                value: Config.animationSpeedScale
                step: 0.05
                onMoved: v => Config.animationSpeedScale = v
            }
        }
    }
}
