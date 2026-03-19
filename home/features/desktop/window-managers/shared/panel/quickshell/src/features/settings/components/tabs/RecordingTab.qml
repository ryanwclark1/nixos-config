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
        title: "Recording"
        iconName: "󰻃"

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
