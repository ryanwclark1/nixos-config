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
        tabId: root.tabId
        title: "Background"
        iconName: "󰸉"

        SettingsCard {
            title: "Desktop Background"
            iconName: "󰸉"
            description: "Wallpaper overlays visible on the desktop background layer."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Spectrum Visualizer"
                    icon: "󰓃"
                    configKey: "backgroundVisualizerEnabled"
                }
                SettingsToggleRow {
                    label: "Shader Visualizer"
                    description: "High-performance GLSL mode."
                    icon: "󰓃"
                    configKey: "backgroundUseShaderVisualizer"
                }
                SettingsToggleRow {
                    label: "Desktop Clock"
                    icon: "󰥔"
                    configKey: "backgroundClockEnabled"
                }
                SettingsToggleRow {
                    label: "Auto-Hide on Fullscreen"
                    icon: "󰘖"
                    configKey: "backgroundAutoHide"
                }
                SettingsToggleRow {
                    label: "Weather overlay"
                    icon: "󰖐"
                    configKey: "weatherOverlayEnabled"
                }
            }

            SettingsModeRow {
                label: "Clock Position"
                currentValue: Config.backgroundClockPosition
                options: [
                    { value: "center", label: "Center" },
                    { value: "top-left", label: "Top Left" },
                    { value: "top-right", label: "Top Right" },
                    { value: "bottom-left", label: "Bottom Left" },
                    { value: "bottom-right", label: "Bottom Right" }
                ]
                onModeSelected: v => Config.backgroundClockPosition = v
            }
        }

        SettingsCard {
            title: "Personality GIF"
            iconName: "󰄛"
            description: "An optional animated element that reacts to your environment."

            SettingsToggleRow {
                label: "Enable GIF"
                icon: "󰄛"
                configKey: "personalityGifEnabled"
            }

            SettingsTextInputRow {
                label: "GIF Path"
                placeholderText: "~/Pictures/bongocat.gif"
                leadingIcon: "󰉋"
                text: Config.personalityGifPath
                onTextEdited: value => Config.personalityGifPath = value

                SettingsActionButton {
                    label: "Pick File"
                    compact: true
                    onClicked: if (root.settingsRoot) root.settingsRoot.pickPersonalityGif()
                }
            }

            SettingsModeRow {
                label: "Reaction Mode"
                currentValue: Config.personalityGifReactionMode
                options: [
                    { value: "media", label: "Music Playback" },
                    { value: "cpu", label: "CPU Usage" },
                    { value: "beat", label: "Audio Beat" },
                    { value: "idle", label: "Always" }
                ]
                onModeSelected: v => Config.personalityGifReactionMode = v
            }
        }
    }
}
