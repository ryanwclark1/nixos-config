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
        iconName: "color-palette.svg"

        SettingsCard {
            title: "Glass Surface"
            iconName: "options.svg"
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

            SettingsToggleRow {
                label: "Auto Transparency"
                icon: "color-palette.svg"
                configKey: "autoTransparency"
                enabledText: "Panels, popups, and cards adapt to wallpaper"
                disabledText: "Surfaces use manual glass opacity values"
            }
        }

        SettingsCard {
            title: "Theme Mode"
            iconName: "color-palette.svg"
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

            SettingsToggleRow {
                label: "OLED Mode"
                description: "Forces pure black backgrounds for OLED power savings."
                icon: "desktop-monitor.svg"
                configKey: "oledMode"
            }
        }

        SettingsCard {
            title: "Screen Decorations"
            iconName: "fullscreen.svg"
            description: "Rounded corners and border frame overlays for your displays."

            SettingsToggleRow {
                label: "Screen Corners"
                description: "Draws rounded corner overlays at each screen edge."
                icon: "border-all.svg"
                configKey: "showScreenCorners"
            }

            SettingsSliderRow {
                label: "Corner Radius"
                description: "Size of the rounded screen corners."
                min: 4
                max: 36
                value: Config.screenCornerRadius
                step: 2
                onMoved: v => Config.screenCornerRadius = Math.round(v)
                visible: Config.showScreenCorners
            }

            SettingsToggleRow {
                label: "Screen Borders"
                description: "Draws a thin frame around each display."
                icon: "border-outside.svg"
                configKey: "showScreenBorders"
            }
        }

        SettingsCard {
            title: "Performance"
            iconName: "󰓅"
            description: "Disable GPU-intensive features for lower-end hardware or battery savings."

            SettingsToggleRow {
                label: "Automatic Eco Mode"
                description: "Reduces animations and disables shaders on battery."
                icon: "leaf-two.svg"
                configKey: "autoEcoMode"
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
                label: "Weather Overlay Shaders"
                description: "Animated rain, snow, and fog effects over the wallpaper."
                icon: "weather-rain.svg"
                configKey: "weatherOverlayEnabled"
            }

            SettingsToggleRow {
                label: "Background Visualizer"
                description: "Audio-reactive wallpaper visualizer."
                icon: "music-note-2.svg"
                configKey: "backgroundVisualizerEnabled"
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
                leadingIcon: "code.svg"
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
