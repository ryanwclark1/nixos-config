import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Rectangle {
    id: root

    required property bool open
    required property bool compactMode
    required property int overlayInset
    required property var editingWidget
    required property var editingWidgetSchema
    required property string editingPluginId
    required property bool editingPluginHasSettings
    required property bool editingPluginCanWriteSettings
    required property string pluginSettingsError

    // Exposes the Loader so the parent can call setSource / clear it
    readonly property alias pluginSettingsLoader: pluginSettingsLoader

    signal closeRequested
    signal pluginSettingsErrorUpdated(string value)
    signal settingChanged(string key, var value)

    function schemaFieldCurrentValue(field) {
        if (!root.editingWidget || !field)
            return "";
        var settings = root.editingWidget.settings ? root.editingWidget.settings : {};
        if (settings[field.key] !== undefined)
            return settings[field.key];
        var defaults = BarWidgetRegistry.defaultSettings(root.editingWidget.widgetType);
        if (defaults[field.key] !== undefined)
            return defaults[field.key];
        if (field.type === "toggle")
            return false;
        if (field.type === "slider")
            return field.min !== undefined ? field.min : 0;
        return "";
    }

    anchors.fill: parent
    visible: root.open
    color: Qt.rgba(0, 0, 0, 0.45)
    z: 21

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Component {
        id: schemaModeField

        SettingsModeRow {
            property var field: null
            visible: !!field
            label: field ? (field.label || "") : ""
            icon: field && field.icon ? field.icon : ""
            description: field && field.description ? field.description : ""
            currentValue: root.schemaFieldCurrentValue(field)
            options: field && field.options ? field.options : []
            onModeSelected: value => {
                if (field)
                    root.settingChanged(field.key, value);
            }
        }
    }

    Component {
        id: schemaSliderField

        SettingsSliderRow {
            property var field: null
            visible: !!field
            label: field ? (field.label || "") : ""
            icon: field && field.icon ? field.icon : ""
            min: field && field.min !== undefined ? field.min : 0
            max: field && field.max !== undefined ? field.max : 100
            step: field && field.step !== undefined ? field.step : 1
            unit: field && field.unit ? field.unit : ""
            value: root.schemaFieldCurrentValue(field)
            onMoved: value => {
                if (field)
                    root.settingChanged(field.key, value);
            }
        }
    }

    Component {
        id: schemaToggleField

        SettingsToggleRow {
            property var field: null
            visible: !!field
            label: field ? (field.label || "") : ""
            icon: field && field.icon ? field.icon : ""
            checked: !!root.schemaFieldCurrentValue(field)
            enabledText: field && field.enabledText ? field.enabledText : "Enabled"
            disabledText: field && field.disabledText ? field.disabledText : "Disabled"
            onToggled: {
                if (field)
                    root.settingChanged(field.key, !root.schemaFieldCurrentValue(field));
            }
        }
    }

    Component {
        id: schemaTextField

        SettingsTextInputRow {
            property var field: null
            visible: !!field
            label: field ? (field.label || "") : ""
            leadingIcon: field && field.icon ? field.icon : ""
            placeholderText: field && field.placeholder ? field.placeholder : ""
            text: String(root.schemaFieldCurrentValue(field) || "")
            onTextEdited: value => {
                if (field)
                    root.settingChanged(field.key, value);
            }
        }
    }

    Rectangle {
        width: Math.min(560, parent.width - root.overlayInset * 2)
        height: Math.min(settingsFlick.contentHeight + Appearance.paddingLarge * 2, parent.height - root.overlayInset * 2)
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Math.max(root.overlayInset, (parent.height - height) / 2)
        anchors.leftMargin: Math.max(root.overlayInset, (parent.width - width) / 2)
        radius: Appearance.radiusLarge
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        Flickable {
            id: settingsFlick
            anchors.fill: parent
            anchors.margins: Appearance.paddingLarge
            clip: true
            contentHeight: settingsColumn.implicitHeight

            ColumnLayout {
                id: settingsColumn
                width: settingsFlick.width
                spacing: Appearance.spacingM

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Appearance.spacingS

                    Text {
                        width: root.compactMode ? parent.width : Math.max(0, parent.width - closeSettingsButton.implicitWidth - Appearance.spacingS)
                        text: root.editingWidget ? (BarWidgetRegistry.displayName(root.editingWidget.widgetType) + " Settings") : "Widget Settings"
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeXL
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }

                    SettingsActionButton {
                        id: closeSettingsButton
                        compact: true
                        iconName: "dismiss.svg"
                        label: "Close"
                        onClicked: root.closeRequested()
                    }
                }

                SettingsInfoCallout {
                    visible: !root.editingWidget || (!BarWidgetRegistry.supportsSettings(root.editingWidget.widgetType) && root.editingPluginId === "")
                    title: "No configurable options"
                    body: "This widget does not expose custom per-instance settings yet."
                }

                SettingsInfoCallout {
                    visible: root.editingPluginId !== "" && root.editingPluginHasSettings && !root.editingPluginCanWriteSettings
                    title: "Permission required"
                    body: "This plugin is missing settings_write permission in its manifest."
                }

                SettingsInfoCallout {
                    visible: root.pluginSettingsError !== ""
                    title: "Plugin settings failed to load"
                    body: root.pluginSettingsError
                }

                Repeater {
                    model: root.editingWidgetSchema

                    delegate: Loader {
                        required property var modelData
                        readonly property var field: modelData
                        Layout.fillWidth: true
                        active: !!root.editingWidget

                        sourceComponent: {
                            if (field.type === "mode")
                                return schemaModeField;
                            if (field.type === "slider")
                                return schemaSliderField;
                            if (field.type === "toggle")
                                return schemaToggleField;
                            if (field.type === "text")
                                return schemaTextField;
                            return null;
                        }

                        onLoaded: {
                            if (item && item.field !== undefined)
                                item.field = field;
                        }
                    }
                }

                SharedWidgets.SshWidgetSettings {
                    Layout.fillWidth: true
                    visible: !!root.editingWidget && root.editingWidget.widgetType === "ssh"
                    widgetInstance: root.editingWidget
                }

                Loader {
                    id: pluginSettingsLoader
                    Layout.fillWidth: true
                    visible: root.editingPluginId !== "" && root.editingPluginHasSettings && root.editingPluginCanWriteSettings && status !== Loader.Error
                    onStatusChanged: {
                        if (status === Loader.Error)
                            root.pluginSettingsErrorUpdated(errorString());
                        else if (status === Loader.Ready)
                            root.pluginSettingsErrorUpdated("");
                    }
                }
            }
        }
    }
}
