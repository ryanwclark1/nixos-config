import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    readonly property int _enabledBackgroundFeatures: (Config.backgroundVisualizerEnabled ? 1 : 0)
        + (Config.backgroundUseShaderVisualizer ? 1 : 0)
        + (Config.backgroundClockEnabled ? 1 : 0)
        + (Config.backgroundAutoHide ? 1 : 0)
        + (Config.weatherOverlayEnabled ? 1 : 0)
    readonly property string _clockPositionSummary: Config.backgroundClockEnabled ? String(Config.backgroundClockPosition || "center") : "Hidden"
    readonly property string _gifSummary: Config.personalityGifEnabled
        ? String(Config.personalityGifReactionMode || "idle")
        : "Disabled"

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Background"
        iconName: "image.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Background Overview"
            description: "Desktop-layer overlays, clock placement, and animated personality surface state."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󰸉",
                            label: "Background Features",
                            value: root._enabledBackgroundFeatures + " active"
                        },
                        {
                            icon: "clock.svg",
                            label: "Clock",
                            value: root._clockPositionSummary
                        },
                        {
                            icon: "people.svg",
                            label: "Personality GIF",
                            value: root._gifSummary
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(180, Math.floor((parent.width - Appearance.spacingM * 2) / 3))
                        implicitHeight: metricColumn.implicitHeight + Appearance.spacingM * 2
                        radius: Appearance.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            spacing: Appearance.spacingXS

                            SettingsMetricIcon { icon: modelData.icon }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Appearance.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Desktop Layer"
            description: "Control the overlays that live directly on the desktop background surface."

            SettingsCard {
                title: "Desktop Background"
                iconName: "image.svg"
                description: "Wallpaper overlays visible on the desktop background layer."

                SettingsFieldGrid {
                    maximumColumns: root.compactMode ? 1 : 2

                    SettingsToggleRow {
                        label: "Spectrum Visualizer"
                        icon: "mic.svg"
                        configKey: "backgroundVisualizerEnabled"
                    }
                    SettingsToggleRow {
                        label: "Shader Visualizer"
                        description: "High-performance GLSL mode."
                        icon: "mic.svg"
                        configKey: "backgroundUseShaderVisualizer"
                    }
                    SettingsToggleRow {
                        label: "Desktop Clock"
                        icon: "clock.svg"
                        configKey: "backgroundClockEnabled"
                    }
                    SettingsToggleRow {
                        label: "Auto-Hide on Fullscreen"
                        icon: "lock-closed.svg"
                        configKey: "backgroundAutoHide"
                    }
                    SettingsToggleRow {
                        label: "Weather overlay"
                        icon: "weather-sunny.svg"
                        configKey: "weatherOverlayEnabled"
                    }
                }

                SettingsModeRow {
                    label: "Clock Position"
                    currentValue: Config.backgroundClockPosition
                    options: [
                        {
                            value: "center",
                            label: "Center"
                        },
                        {
                            value: "top-left",
                            label: "Top Left"
                        },
                        {
                            value: "top-right",
                            label: "Top Right"
                        },
                        {
                            value: "bottom-left",
                            label: "Bottom Left"
                        },
                        {
                            value: "bottom-right",
                            label: "Bottom Right"
                        }
                    ]
                    onModeSelected: v => Config.backgroundClockPosition = v
                }
            }
        }

        SettingsSectionGroup {
            title: "Personality Overlay"
            description: "Animated overlay behavior that reacts to media, CPU activity, or audio."

            SettingsCard {
                title: "Personality GIF"
                iconName: "people.svg"
                description: "An optional animated element that reacts to your environment."

                SettingsToggleRow {
                    label: "Enable GIF"
                    icon: "people.svg"
                    configKey: "personalityGifEnabled"
                }

                SettingsTextInputRow {
                    label: "GIF Path"
                    placeholderText: "~/Pictures/bongocat.gif"
                    leadingIcon: "folder.svg"
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
                        {
                            value: "media",
                            label: "Music Playback"
                        },
                        {
                            value: "cpu",
                            label: "CPU Usage"
                        },
                        {
                            value: "beat",
                            label: "Audio Beat"
                        },
                        {
                            value: "idle",
                            label: "Always"
                        }
                    ]
                    onModeSelected: v => Config.personalityGifReactionMode = v
                }
            }
        }
    }
}
