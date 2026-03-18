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
                    label: "Desktop Clock"
                    icon: "󰥔"
                    configKey: "backgroundClockEnabled"
                }
                SettingsToggleRow {
                    label: "Auto-Hide on Fullscreen"
                    icon: "󰘖"
                    configKey: "backgroundAutoHide"
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
    }
}
