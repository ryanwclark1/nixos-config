import QtQuick
import QtQuick.Layouts
import "../services"
import "../menu/settings"

ColumnLayout {
    id: root

    property var widgetInstance: null
    property int editingIndex: -1
    property string formId: ""
    property string formLabel: ""
    property string formHost: ""
    property string formUser: ""
    property string formPort: "22"
    property string formRemoteCommand: ""
    property string formTags: ""
    property string formGroup: ""
    property string formError: ""

    spacing: Colors.spacingM
    Layout.fillWidth: true

    SshWidgetData {
        id: sshData
        widgetInstance: root.widgetInstance
    }

    function editHostAt(index) {
        var host = sshData.manualHosts[index];
        if (!host)
            return;
        editingIndex = index;
        formId = String(host.id || "");
        formLabel = String(host.label || "");
        formHost = String(host.host || "");
        formUser = String(host.user || "");
        formPort = String(host.port || 22);
        formRemoteCommand = String(host.remoteCommand || "");
        formTags = Array.isArray(host.tags) ? host.tags.join(", ") : "";
        formGroup = String(host.group || "");
        formError = "";
    }

    function resetForm() {
        editingIndex = -1;
        formId = "";
        formLabel = "";
        formHost = "";
        formUser = "";
        formPort = "22";
        formRemoteCommand = "";
        formTags = "";
        formGroup = "";
        formError = "";
    }

    function saveHost() {
        if (formLabel.trim() === "" || formHost.trim() === "") {
            formError = "Label and host are required.";
            return;
        }
        var next = JSON.parse(JSON.stringify(sshData.manualHosts || []));
        var host = {
            id: formId,
            label: formLabel,
            host: formHost,
            user: formUser,
            port: formPort,
            remoteCommand: formRemoteCommand,
            tags: formTags,
            group: formGroup
        };
        if (editingIndex >= 0 && editingIndex < next.length)
            next[editingIndex] = host;
        else
            next.push(host);
        sshData.saveManualHosts(next);
        resetForm();
    }

    function removeHost(index) {
        var next = JSON.parse(JSON.stringify(sshData.manualHosts || []));
        if (index < 0 || index >= next.length)
            return;
        next.splice(index, 1);
        sshData.saveManualHosts(next);
        if (editingIndex === index)
            resetForm();
    }

    function moveHost(index, delta) {
        var next = JSON.parse(JSON.stringify(sshData.manualHosts || []));
        var target = index + delta;
        if (index < 0 || index >= next.length || target < 0 || target >= next.length)
            return;
        var item = next[index];
        next.splice(index, 1);
        next.splice(target, 0, item);
        sshData.saveManualHosts(next);
        if (editingIndex === index)
            editingIndex = target;
    }

    Component.onCompleted: resetForm()

    Text {
        text: "SSH Hosts & Import"
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
        Layout.fillWidth: true
    }

    Text {
        text: "Basic SSH pill behavior is configured above with the shared widget settings. This section manages host lists, import diagnostics, and reset actions."
        color: Colors.textSecondary
        font.pixelSize: Colors.fontSizeXS
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: Colors.spacingS

        SettingsActionButton {
            compact: true
            iconName: "󰑐"
            label: "Reset State"
            onClicked: sshData.resetStateOnly()
        }

        SettingsActionButton {
            compact: true
            iconName: "󰩺"
            label: "Reset All"
            onClicked: {
                sshData.resetAll();
                root.resetForm();
            }
        }
    }

    SettingsDataRow {
        label: "Import Root"
        iconName: "󰈔"
        value: sshData.importRootPath
    }

    SettingsDataRow {
        label: "Imported Aliases"
        iconName: "󰮔"
        value: String(sshData.importedHosts.length)
        monoValue: false
    }

    SettingsDataRow {
        label: "Skipped Patterns"
        iconName: "󰇘"
        value: String(sshData.skippedPatternEntries.length)
        monoValue: false
    }

    SettingsDataRow {
        label: "Import Errors"
        iconName: "󰅚"
        value: String(sshData.importErrors.length)
        monoValue: false
    }

    Text {
        text: "Manual Hosts"
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
        Layout.fillWidth: true
    }

    SettingsTextInputRow {
        label: "Label"
        placeholderText: "Production Bastion"
        text: root.formLabel
        onTextEdited: value => root.formLabel = value
        errorText: root.formError
    }

    SettingsTextInputRow {
        label: "Host"
        placeholderText: "bastion.example.com"
        text: root.formHost
        onTextEdited: value => root.formHost = value
    }

    SettingsTextInputRow {
        label: "User"
        placeholderText: "ubuntu"
        text: root.formUser
        onTextEdited: value => root.formUser = value
    }

    SettingsTextInputRow {
        label: "Port"
        placeholderText: "22"
        text: root.formPort
        onTextEdited: value => root.formPort = value
    }

    SettingsTextInputRow {
        label: "Remote Command"
        placeholderText: "tmux attach"
        text: root.formRemoteCommand
        onTextEdited: value => root.formRemoteCommand = value
    }

    SettingsTextInputRow {
        label: "Tags"
        placeholderText: "prod, infra"
        text: root.formTags
        onTextEdited: value => root.formTags = value
    }

    SettingsTextInputRow {
        label: "Group"
        placeholderText: "platform"
        text: root.formGroup
        onTextEdited: value => root.formGroup = value
    }

    Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: Colors.spacingS

        SettingsActionButton {
            compact: true
            iconName: "󰐕"
            label: root.editingIndex >= 0 ? "Update Host" : "Add Host"
            onClicked: root.saveHost()
        }

        SettingsActionButton {
            compact: true
            iconName: "󰜉"
            label: "Clear Form"
            onClicked: root.resetForm()
        }
    }

    Repeater {
        model: sshData.manualHosts.length
        delegate: Rectangle {
            required property int index
            readonly property var host: sshData.manualHosts[index]
            Layout.fillWidth: true
            implicitHeight: hostColumn.implicitHeight + Colors.spacingM * 2
            radius: Colors.radiusSmall
            color: Colors.modalFieldSurface
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
                id: hostColumn
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingS

                Text {
                    text: host.label
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: sshData.buildDisplayCommand(host)
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    SettingsActionButton {
                        compact: true
                        iconName: "󰏫"
                        label: "Up"
                        enabled: index > 0
                        onClicked: root.moveHost(index, -1)
                    }

                    SettingsActionButton {
                        compact: true
                        iconName: "󰏬"
                        label: "Down"
                        enabled: index < (sshData.manualHosts.length - 1)
                        onClicked: root.moveHost(index, 1)
                    }

                    SettingsActionButton {
                        compact: true
                        iconName: "󰏫"
                        label: "Edit"
                        onClicked: root.editHostAt(index)
                    }

                    SettingsActionButton {
                        compact: true
                        iconName: "󰅖"
                        label: "Remove"
                        onClicked: root.removeHost(index)
                    }
                }
            }
        }
    }

    SettingsInfoCallout {
        visible: sshData.importErrors.length > 0
        title: "SSH config import errors"
        body: sshData.importErrors.map(function(entry) {
            return String(entry.path || "") + ":" + String(entry.line || 0) + " " + String(entry.message || "");
        }).join("\n")
    }
}
