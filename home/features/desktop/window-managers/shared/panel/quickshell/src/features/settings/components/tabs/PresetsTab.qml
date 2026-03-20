import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    property string _presetName: ""
    property string _presetDesc: ""
    property string _pendingDeleteName: ""

    readonly property int _confirmTimeoutMs: 3000

    Timer {
        id: deleteConfirmTimer
        interval: root._confirmTimeoutMs
        onTriggered: root._pendingDeleteName = ""
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Presets"
        iconName: "󰆓"

        SettingsCard {
            title: "Save Current Configuration"
            iconName: "󰆓"
            description: "Save a snapshot of your current settings as a named preset."

            SettingsTextInputRow {
                label: "Preset Name"
                placeholderText: "e.g. My Dark Setup"
                leadingIcon: "󰏪"
                text: root._presetName
                onTextEdited: value => root._presetName = value
            }

            SettingsTextInputRow {
                label: "Description (optional)"
                placeholderText: "A brief note about this preset"
                leadingIcon: "󰈔"
                text: root._presetDesc
                onTextEdited: value => root._presetDesc = value
            }

            SettingsActionButton {
                label: "Save Preset"
                iconName: "󰆓"
                emphasized: true
                enabled: root._presetName.trim().length > 0
                onClicked: {
                    PresetService.savePreset(root._presetName.trim(), root._presetDesc.trim());
                    root._presetName = "";
                    root._presetDesc = "";
                }
            }
        }

        SettingsCard {
            title: "Saved Presets"
            iconName: "󰋊"
            description: "Load or delete previously saved configuration snapshots."

            SharedWidgets.EmptyState {
                visible: PresetService.presets.length === 0
                Layout.fillWidth: true
                icon: "save.svg"
                message: "No presets saved yet"
            }

            Repeater {
                model: PresetService.presets
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: presetContent.implicitHeight + Colors.spacingL * 2
                    radius: Colors.radiusSmall
                    color: Colors.modalFieldSurface
                    border.color: Colors.border
                    border.width: 1

                    ColumnLayout {
                        id: presetContent
                        anchors.fill: parent
                        anchors.margins: Colors.spacingL
                        spacing: Colors.spacingS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingM

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Colors.spacingXXS

                                Text {
                                    text: modelData.name
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: (modelData.description || "") !== ""
                                    text: modelData.description || ""
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeSmall
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.created > 0
                                        ? new Date(modelData.created * 1000).toLocaleDateString()
                                        : ""
                                    color: Colors.textDisabled
                                    font.pixelSize: Colors.fontSizeXS
                                    visible: modelData.created > 0
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS

                            SettingsActionButton {
                                label: "Load"
                                iconName: "󰦛"
                                compact: true
                                onClicked: PresetService.loadPreset(modelData.name)
                            }

                            SettingsActionButton {
                                label: root._pendingDeleteName === modelData.name ? "Confirm?" : "Delete"
                                iconName: root._pendingDeleteName === modelData.name ? "󰀦" : "󰆴"
                                compact: true
                                onClicked: {
                                    if (root._pendingDeleteName === modelData.name) {
                                        PresetService.deletePreset(modelData.name);
                                        root._pendingDeleteName = "";
                                        deleteConfirmTimer.stop();
                                    } else {
                                        root._pendingDeleteName = modelData.name;
                                        deleteConfirmTimer.restart();
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }
}
