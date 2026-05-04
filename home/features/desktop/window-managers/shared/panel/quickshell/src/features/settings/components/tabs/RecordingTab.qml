import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".." as Components

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

    Components.SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Recording"
        iconName: "video.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        Components.SettingsSectionGroup {
            title: "Recording Overview"
            description: "Capture source, default quality, audio inclusion, and storage destination at a glance."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingM

                Repeater {
                    model: [
                        {
                            icon: "record.svg",
                            label: "Source",
                            value: root._captureSourceSummary
                        },
                        {
                            icon: "timer.svg",
                            label: "Profile",
                            value: root._qualitySummary
                        },
                        {
                            icon: "speaker.svg",
                            label: "Audio",
                            value: root._audioSummary
                        },
                        {
                            icon: "folder.svg",
                            label: "Storage",
                            value: root._outputSummary
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(140, Math.floor((parent.width - Appearance.spacingM * 3) / 4))
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

                            Components.SettingsMetricIcon { icon: modelData.icon }

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

        Components.SettingsSectionGroup {
            title: "Capture Defaults"
            description: "Default source, frame rate, quality, and cursor behavior for new recordings."

            Components.SettingsCard {
                title: "Capture"
                iconName: "fullscreen.svg"
                description: "Default source and visual capture behavior for screen recording."

                Components.SettingsModeRow {
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

                Components.SettingsModeRow {
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

                Components.SettingsModeRow {
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

                Components.SettingsToggleRow {
                    label: "Record Cursor"
                    icon: "video.svg"
                    configKey: "recordingRecordCursor"
                    enabledText: "Pointer movements are visible in recordings."
                    disabledText: "Recordings omit the cursor."
                }
            }
        }

        Components.SettingsSectionGroup {
            title: "Audio Capture"
            description: "Control whether desktop output, microphone input, or both are included by default."

            Components.SettingsCard {
                title: "Audio"
                iconName: "speaker.svg"
                description: "Choose which audio sources are included by default."

                Components.SettingsToggleRow {
                    label: "Desktop Audio"
                    icon: "speaker.svg"
                    configKey: "recordingIncludeDesktopAudio"
                    enabledText: "System output audio is captured."
                    disabledText: "System output audio is not captured."
                }

                Components.SettingsToggleRow {
                    label: "Microphone"
                    icon: "mic-off.svg"
                    configKey: "recordingIncludeMicrophoneAudio"
                    enabledText: "Default microphone input is captured."
                    disabledText: "Microphone input is not captured."
                }
            }
        }

        Components.SettingsSectionGroup {
            title: "Storage"
            description: "Choose where recordings land when the recording flow completes."

            Components.SettingsCard {
                title: "Storage"
                iconName: "folder.svg"
                description: "Leave blank to use the default Videos directory."

                Components.SettingsDirectoryPickerRow {
                    label: "Output Directory"
                    callerId: "recording-folder"
                    leadingIcon: "folder.svg"
                    placeholderText: "~/Videos"
                    text: Config.recordingOutputDir
                    onSubmitted: value => Config.recordingOutputDir = value.trim()
                }
            }
        }
    }
}
