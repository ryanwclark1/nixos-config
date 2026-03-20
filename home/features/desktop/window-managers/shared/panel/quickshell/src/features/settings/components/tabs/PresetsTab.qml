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
    readonly property int presetCount: (PresetService.presets || []).length
    readonly property string latestPresetLabel: {
        var presets = PresetService.presets || [];
        var latest = null;
        for (var i = 0; i < presets.length; i++) {
            if (!latest || Number(presets[i].created || 0) > Number(latest.created || 0))
                latest = presets[i];
        }
        return latest ? String(latest.name || "") : "None";
    }

    Timer {
        id: deleteConfirmTimer
        interval: root._confirmTimeoutMs
        onTriggered: root._pendingDeleteName = ""
    }

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Presets"
        iconName: "save.svg"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Preset Overview"
            description: "Snapshot count and the most recently saved preset before you save or restore configurations."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingM

                Repeater {
                    model: [
                        {
                            icon: "save.svg",
                            label: "Saved",
                            value: root.presetCount + " preset" + (root.presetCount === 1 ? "" : "s")
                        },
                        {
                            icon: "save.svg",
                            label: "Latest",
                            value: root.latestPresetLabel
                        },
                        {
                            icon: "rename.svg",
                            label: "Draft Name",
                            value: root._presetName.trim() !== "" ? root._presetName.trim() : "Not set"
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
            title: "Style Presets"
            description: "Quick-apply curated shell personalities that adjust spacing, radii, and motion."

            SettingsCard {
                title: "Built-In Presets"
                iconName: "color-palette.svg"
                description: "One-click style adjustments. Your colors and layout are preserved."

                Repeater {
                    model: PresetService.builtinPresets
                    delegate: SettingsActionButton {
                        required property var modelData
                        label: modelData.name
                        iconName: modelData.icon || ""
                        description: modelData.description || ""
                        onClicked: PresetService.loadBuiltinPreset(modelData.id)
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Save Current Configuration"
            description: "Create a named snapshot of the current shell configuration."

            SettingsCard {
                title: "Save Current Configuration"
                iconName: "save.svg"
                description: "Save a snapshot of your current settings as a named preset."

                SettingsTextInputRow {
                    label: "Preset Name"
                    placeholderText: "e.g. My Dark Setup"
                    leadingIcon: "rename.svg"
                    text: root._presetName
                    onTextEdited: value => root._presetName = value
                }

                SettingsTextInputRow {
                    label: "Description (optional)"
                    placeholderText: "A brief note about this preset"
                    leadingIcon: "document.svg"
                    text: root._presetDesc
                    onTextEdited: value => root._presetDesc = value
                }

                SettingsActionButton {
                    label: "Save Preset"
                    iconName: "save.svg"
                    emphasized: true
                    enabled: root._presetName.trim().length > 0
                    onClicked: {
                        PresetService.savePreset(root._presetName.trim(), root._presetDesc.trim());
                        root._presetName = "";
                        root._presetDesc = "";
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Saved Presets"
            description: "Restore or remove named configuration snapshots."

            SettingsCard {
                title: "Saved Presets"
                iconName: "hard-drive.svg"
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
                        implicitHeight: presetContent.implicitHeight + Appearance.spacingL * 2
                        radius: Appearance.radiusSmall
                        color: Colors.modalFieldSurface
                        border.color: Colors.border
                        border.width: 1

                        ColumnLayout {
                            id: presetContent
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingL
                            spacing: Appearance.spacingS

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingM

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacingXXS

                                    Text {
                                        text: modelData.name
                                        color: Colors.text
                                        font.pixelSize: Appearance.fontSizeMedium
                                        font.weight: Font.DemiBold
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: (modelData.description || "") !== ""
                                        text: modelData.description || ""
                                        color: Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeSmall
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.created > 0
                                            ? new Date(modelData.created * 1000).toLocaleDateString()
                                            : ""
                                        color: Colors.textDisabled
                                        font.pixelSize: Appearance.fontSizeXS
                                        visible: modelData.created > 0
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Appearance.spacingS

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

                                Item {
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
