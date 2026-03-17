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

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Audio"
        iconName: "󰕾"

        SettingsCard {
            title: "Volume Protection"
            iconName: "󰕾"
            description: "Limit sudden volume jumps to protect hearing."

            SettingsToggleRow {
                label: "Volume Protection"
                icon: "󰕾"
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

        SettingsCard {
            title: "Pinned Output Devices"
            iconName: "󰓃"
            description: "Pinned devices appear at the top of the output device list."

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS
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
                leadingIcon: "󰓃"
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
            iconName: "󰍬"
            description: "Pinned devices appear at the top of the input device list."

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS
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
                leadingIcon: "󰍬"
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

        SettingsCard {
            title: "Hidden Output Devices"
            iconName: "󰝞"
            description: "Hidden devices won't appear in the audio menu."

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS
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
                leadingIcon: "󰝞"
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
            iconName: "󰍭"
            description: "Hidden devices won't appear in the audio menu."

            Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS
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
                leadingIcon: "󰍭"
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
