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

    readonly property string _captureSourceSummary: Config.recordingCaptureSource === "portal" ? "Portal picker" : "Full screen"
    readonly property string _qualitySummary: Config.recordingFps + " FPS / " + String(Config.recordingQuality || "").replace(/_/g, " ")
    readonly property string _audioSummary: {
        var parts = [];
        if (Config.recordingIncludeDesktopAudio)
            parts.push("Desktop");
        if (Config.recordingIncludeMicrophoneAudio)
            parts.push("Mic");
        return parts.length > 0 ? parts.join(" + ") : "Silent";
    }
    readonly property string _outputSummary: {
        var path = String(Config.recordingOutputDir || "").trim();
        return path !== "" ? path : "~/Videos";
    }

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Recording"
        iconName: "󰻃"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Recording Overview"
            description: "Capture source, default quality, audio inclusion, and storage destination at a glance."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󰹑",
                            label: "Source",
                            value: root._captureSourceSummary
                        },
                        {
                            icon: "󰔟",
                            label: "Profile",
                            value: root._qualitySummary
                        },
                        {
                            icon: "󰕾",
                            label: "Audio",
                            value: root._audioSummary
                        },
                        {
                            icon: "󰉋",
                            label: "Storage",
                            value: root._outputSummary
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(180, Math.floor((parent.width - Colors.spacingM * 2) / 3))
                        implicitHeight: metricColumn.implicitHeight + Colors.spacingM * 2
                        radius: Colors.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            Text {
                                text: modelData.icon
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeLarge
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Colors.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Capture Defaults"
            description: "Default source, frame rate, quality, and cursor behavior for new recordings."

            SettingsCard {
                title: "Capture"
                iconName: "󰹑"
                description: "Default source and visual capture behavior for screen recording."

                SettingsModeRow {
                    label: "Capture Source"
                    currentValue: Config.recordingCaptureSource
                    options: [
                        {
                            value: "portal",
                            label: "Portal"
                        },
                        {
                            value: "screen",
                            label: "Full Screen"
                        }
                    ]
                    onModeSelected: value => Config.recordingCaptureSource = value
                }

                SettingsModeRow {
                    label: "Frame Rate"
                    currentValue: String(Config.recordingFps)
                    options: [
                        {
                            value: "30",
                            label: "30 FPS"
                        },
                        {
                            value: "60",
                            label: "60 FPS"
                        },
                        {
                            value: "120",
                            label: "120 FPS"
                        }
                    ]
                    onModeSelected: value => Config.recordingFps = parseInt(value, 10) || 60
                }

                SettingsModeRow {
                    label: "Quality"
                    currentValue: Config.recordingQuality
                    options: [
                        {
                            value: "medium",
                            label: "Medium"
                        },
                        {
                            value: "high",
                            label: "High"
                        },
                        {
                            value: "very_high",
                            label: "Very High"
                        }
                    ]
                    onModeSelected: value => Config.recordingQuality = value
                }

                SettingsToggleRow {
                    label: "Record Cursor"
                    icon: "󰆺"
                    configKey: "recordingRecordCursor"
                    enabledText: "Pointer movements are visible in recordings."
                    disabledText: "Recordings omit the cursor."
                }
            }
        }

        SettingsSectionGroup {
            title: "Audio Capture"
            description: "Control whether desktop output, microphone input, or both are included by default."

            SettingsCard {
                title: "Audio"
                iconName: "󰕾"
                description: "Choose which audio sources are included by default."

                SettingsToggleRow {
                    label: "Desktop Audio"
                    icon: "󰕾"
                    configKey: "recordingIncludeDesktopAudio"
                    enabledText: "System output audio is captured."
                    disabledText: "System output audio is not captured."
                }

                SettingsToggleRow {
                    label: "Microphone"
                    icon: "󰍬"
                    configKey: "recordingIncludeMicrophoneAudio"
                    enabledText: "Default microphone input is captured."
                    disabledText: "Microphone input is not captured."
                }
            }
        }

        SettingsSectionGroup {
            title: "Storage"
            description: "Choose where recordings land when the recording flow completes."

            SettingsCard {
                title: "Storage"
                iconName: "󰉋"
                description: "Leave blank to use the default Videos directory."

                SettingsTextInputRow {
                    label: "Output Directory"
                    leadingIcon: "󰉋"
                    placeholderText: "~/Videos"
                    text: Config.recordingOutputDir
                    onSubmitted: value => Config.recordingOutputDir = value.trim()
                }
            }
        }
    }
}
