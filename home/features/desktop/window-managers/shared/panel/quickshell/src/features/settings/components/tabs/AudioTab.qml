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

    readonly property int _pinnedOutputCount: Config.audioPinnedOutputs ? Config.audioPinnedOutputs.length : 0
    readonly property int _pinnedInputCount: Config.audioPinnedInputs ? Config.audioPinnedInputs.length : 0
    readonly property int _hiddenOutputCount: Config.audioHiddenOutputs ? Config.audioHiddenOutputs.length : 0
    readonly property int _hiddenInputCount: Config.audioHiddenInputs ? Config.audioHiddenInputs.length : 0
    readonly property string _protectionSummary: Config.volumeProtectionEnabled
        ? ("Max " + Math.round(Config.volumeProtectionMaxJump * 100) + "% jump")
        : "Disabled"

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Audio"
        iconName: "speaker.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Audio Overview"
            description: "Safety limits and device list curation stay visible at the top so you can scan the menu state quickly."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingM

                Repeater {
                    model: [
                        {
                            icon: "speaker.svg",
                            label: "Volume Protection",
                            value: root._protectionSummary
                        },
                        {
                            icon: "󰓃",
                            label: "Pinned Outputs",
                            value: root._pinnedOutputCount + " device" + (root._pinnedOutputCount === 1 ? "" : "s")
                        },
                        {
                            icon: "󰍬",
                            label: "Pinned Inputs",
                            value: root._pinnedInputCount + " device" + (root._pinnedInputCount === 1 ? "" : "s")
                        },
                        {
                            icon: "󰝞",
                            label: "Hidden Devices",
                            value: (root._hiddenOutputCount + root._hiddenInputCount) + " total"
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
            title: "Safety"
            description: "Hearing-protection defaults that constrain abrupt volume jumps."

            SettingsCard {
                title: "Volume Protection"
                iconName: "speaker.svg"
                description: "Limit sudden volume jumps to protect hearing."

                SettingsToggleRow {
                    label: "Volume Protection"
                    icon: "speaker.svg"
                    configKey: "volumeProtectionEnabled"
                    enabledText: "Sudden volume jumps are capped at the maximum jump threshold."
                    disabledText: "Volume changes are not restricted."
                }

                SettingsSliderRow {
                    label: "Max Jump"
                    min: 0.05
                    max: 0.50
                    step: 0.05
                    value: Config.volumeProtectionMaxJump
                    unit: "%"
                    onMoved: v => Config.volumeProtectionMaxJump = v
                }
            }
        }

        SettingsSectionGroup {
            title: "Pinned Devices"
            description: "Pin preferred devices to keep the most-used outputs and inputs at the top of the switcher."

            SettingsCard {
                title: "Pinned Output Devices"
                iconName: "mic.svg"
                description: "Pinned devices appear at the top of the output device list."

                Flow {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    visible: Config.audioPinnedOutputs.length > 0

                    Repeater {
                        model: Config.audioPinnedOutputs
                        delegate: SettingsRemovableChip {
                            onRemoved: {
                                var arr = Config.audioPinnedOutputs.slice();
                                arr.splice(index, 1);
                                Config.audioPinnedOutputs = arr;
                            }
                        }
                    }
                }

                SettingsTextInputRow {
                    label: "Add Output Device"
                    leadingIcon: "mic.svg"
                    placeholderText: "Device name…"
                    onSubmitted: value => {
                        var trimmed = value.trim();
                        if (trimmed.length === 0)
                            return;
                        var arr = Config.audioPinnedOutputs.slice();
                        arr.push(trimmed);
                        Config.audioPinnedOutputs = arr;
                        text = "";
                    }
                }
            }

            SettingsCard {
                title: "Pinned Input Devices"
                iconName: "mic-off.svg"
                description: "Pinned devices appear at the top of the input device list."

                Flow {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    visible: Config.audioPinnedInputs.length > 0

                    Repeater {
                        model: Config.audioPinnedInputs
                        delegate: SettingsRemovableChip {
                            onRemoved: {
                                var arr = Config.audioPinnedInputs.slice();
                                arr.splice(index, 1);
                                Config.audioPinnedInputs = arr;
                            }
                        }
                    }
                }

                SettingsTextInputRow {
                    label: "Add Input Device"
                    leadingIcon: "mic-off.svg"
                    placeholderText: "Device name…"
                    onSubmitted: value => {
                        var trimmed = value.trim();
                        if (trimmed.length === 0)
                            return;
                        var arr = Config.audioPinnedInputs.slice();
                        arr.push(trimmed);
                        Config.audioPinnedInputs = arr;
                        text = "";
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Hidden Devices"
            description: "Suppress devices that should never appear in the quick audio menu."

            SettingsCard {
                title: "Hidden Output Devices"
                iconName: "headphones.svg"
                description: "Hidden devices won't appear in the audio menu."

                Flow {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    visible: Config.audioHiddenOutputs.length > 0

                    Repeater {
                        model: Config.audioHiddenOutputs
                        delegate: SettingsRemovableChip {
                            onRemoved: {
                                var arr = Config.audioHiddenOutputs.slice();
                                arr.splice(index, 1);
                                Config.audioHiddenOutputs = arr;
                            }
                        }
                    }
                }

                SettingsTextInputRow {
                    label: "Add Output Device"
                    leadingIcon: "headphones.svg"
                    placeholderText: "Device name…"
                    onSubmitted: value => {
                        var trimmed = value.trim();
                        if (trimmed.length === 0)
                            return;
                        var arr = Config.audioHiddenOutputs.slice();
                        arr.push(trimmed);
                        Config.audioHiddenOutputs = arr;
                        text = "";
                    }
                }
            }

            SettingsCard {
                title: "Hidden Input Devices"
                iconName: "mic-off-filled.svg"
                description: "Hidden devices won't appear in the audio menu."

                Flow {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    visible: Config.audioHiddenInputs.length > 0

                    Repeater {
                        model: Config.audioHiddenInputs
                        delegate: SettingsRemovableChip {
                            onRemoved: {
                                var arr = Config.audioHiddenInputs.slice();
                                arr.splice(index, 1);
                                Config.audioHiddenInputs = arr;
                            }
                        }
                    }
                }

                SettingsTextInputRow {
                    label: "Add Input Device"
                    leadingIcon: "mic-off-filled.svg"
                    placeholderText: "Device name…"
                    onSubmitted: value => {
                        var trimmed = value.trim();
                        if (trimmed.length === 0)
                            return;
                        var arr = Config.audioHiddenInputs.slice();
                        arr.push(trimmed);
                        Config.audioHiddenInputs = arr;
                        text = "";
                    }
                }
            }
        }
    }
}
