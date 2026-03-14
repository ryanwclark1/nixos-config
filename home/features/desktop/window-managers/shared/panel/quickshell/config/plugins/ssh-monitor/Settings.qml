import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../menu/settings"

Flickable {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null

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

    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight

    SshPluginData {
        id: pluginData
        pluginApi: root.pluginApi
        pluginManifest: root.pluginManifest
        pluginService: root.pluginService
    }

    function editHostAt(index) {
        var host = pluginData.manualHosts[index];
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
        var next = JSON.parse(JSON.stringify(pluginData.manualHosts || []));
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
        pluginData.saveManualHosts(next);
        resetForm();
    }

    function removeHost(index) {
        var next = JSON.parse(JSON.stringify(pluginData.manualHosts || []));
        if (index < 0 || index >= next.length)
            return;
        next.splice(index, 1);
        pluginData.saveManualHosts(next);
        if (editingIndex === index)
            resetForm();
    }

    function moveHost(index, delta) {
        var next = JSON.parse(JSON.stringify(pluginData.manualHosts || []));
        var target = index + delta;
        if (index < 0 || index >= next.length || target < 0 || target >= next.length)
            return;
        var item = next[index];
        next.splice(index, 1);
        next.splice(target, 0, item);
        pluginData.saveManualHosts(next);
        if (editingIndex === index)
            editingIndex = target;
    }

    Component.onCompleted: resetForm()

    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: Colors.spacingM

        Text {
            text: pluginManifest ? pluginManifest.name : "SSH Monitor"
            color: Colors.text
            font.pixelSize: Colors.fontSizeLarge
            font.weight: Font.Bold
            Layout.fillWidth: true
        }

        Text {
            text: "First-party SSH launcher plugin with manual hosts plus ~/.ssh/config import."
            color: Colors.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        SettingsToggleRow {
            label: "SSH config import"
            icon: "󰣀"
            checked: pluginData.enableSshConfigImport
            enabledText: "Import aliases from ~/.ssh/config and include files."
            disabledText: "Only manual hosts are shown."
            onToggled: pluginData.setImportEnabled(!pluginData.enableSshConfigImport)
        }

        SettingsDataRow {
            label: "Display Mode"
            iconName: "󰍹"
            value: pluginData.displayMode === "recent" ? "Recent host label" : "Host count"
            monoValue: false
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            SettingsActionButton {
                label: pluginData.displayMode === "count" ? "Show Recent In Bar" : "Show Count In Bar"
                iconName: "󰍹"
                compact: true
                onClicked: pluginData.setDisplayMode(pluginData.displayMode === "count" ? "recent" : "count")
            }

            SettingsActionButton {
                label: pluginData.defaultAction === "connect" ? "Default: Connect" : "Default: Copy"
                iconName: "󰌍"
                compact: true
                onClicked: pluginData.setDefaultAction(pluginData.defaultAction === "connect" ? "copy" : "connect")
            }

            SettingsActionButton {
                label: "Reset State"
                iconName: "󰑐"
                compact: true
                onClicked: pluginData.resetStateOnly()
            }

            SettingsActionButton {
                label: "Reset All"
                iconName: "󰩺"
                compact: true
                onClicked: {
                    pluginData.resetAll();
                    resetForm();
                }
            }
        }

        SettingsDataRow {
            label: "Import Root"
            iconName: "󰈔"
            value: pluginData.importRootPath
        }

        SettingsDataRow {
            label: "Imported Aliases"
            iconName: "󰮔"
            value: String(pluginData.importedHosts.length)
            monoValue: false
        }

        SettingsDataRow {
            label: "Skipped Patterns"
            iconName: "󰇘"
            value: String(pluginData.skippedPatternEntries.length)
            monoValue: false
        }

        SettingsDataRow {
            label: "Import Errors"
            iconName: "󰅚"
            value: String(pluginData.importErrors.length)
            monoValue: false
        }

        Text {
            text: "Manual Hosts"
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }

        Repeater {
            model: pluginData.manualHosts
            delegate: SettingsListRow {
                required property int index
                required property var modelData
                readonly property int rowIndex: index

                minimumHeight: 56

                Text {
                    text: "󰣀"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: modelData.label
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    Text {
                        text: (modelData.user ? (modelData.user + "@") : "") + modelData.host + (Number(modelData.port || 22) !== 22 ? (":" + modelData.port) : "")
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }

                Flow {
                    spacing: Colors.spacingXS
                    Layout.alignment: Qt.AlignVCenter

                    SettingsActionButton {
                        label: "Edit"
                        compact: true
                        onClicked: root.editHostAt(rowIndex)
                    }

                    SettingsActionButton {
                        label: "Up"
                        compact: true
                        enabled: rowIndex > 0
                        onClicked: root.moveHost(rowIndex, -1)
                    }

                    SettingsActionButton {
                        label: "Down"
                        compact: true
                        enabled: rowIndex < pluginData.manualHosts.length - 1
                        onClicked: root.moveHost(rowIndex, 1)
                    }

                    SettingsActionButton {
                        label: "Delete"
                        compact: true
                        onClicked: root.removeHost(rowIndex)
                    }
                }
            }
        }

        SettingsTextInputRow {
            label: editingIndex >= 0 ? "Host Label (editing)" : "Host Label"
            placeholderText: "Production Bastion"
            leadingIcon: "󰣀"
            text: root.formLabel
            onTextEdited: value => root.formLabel = value
        }

        SettingsTextInputRow {
            label: "Host"
            placeholderText: "bastion.example.com"
            leadingIcon: "󰖟"
            text: root.formHost
            onTextEdited: value => root.formHost = value
        }

        SettingsTextInputRow {
            label: "User"
            placeholderText: "deploy"
            leadingIcon: "󰀄"
            text: root.formUser
            onTextEdited: value => root.formUser = value
        }

        SettingsTextInputRow {
            label: "Port"
            placeholderText: "22"
            leadingIcon: "󰈀"
            text: root.formPort
            onTextEdited: value => root.formPort = value
        }

        SettingsTextInputRow {
            label: "Remote Command"
            placeholderText: "tmux attach || tmux new"
            leadingIcon: "󰆍"
            text: root.formRemoteCommand
            onTextEdited: value => root.formRemoteCommand = value
        }

        SettingsTextInputRow {
            label: "Tags"
            placeholderText: "prod, bastion"
            leadingIcon: "󰓹"
            text: root.formTags
            onTextEdited: value => root.formTags = value
        }

        SettingsTextInputRow {
            label: "Group"
            placeholderText: "production"
            leadingIcon: "󰉋"
            text: root.formGroup
            onTextEdited: value => root.formGroup = value
            errorText: root.formError
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            SettingsActionButton {
                label: editingIndex >= 0 ? "Save Host" : "Add Host"
                iconName: "󰐕"
                emphasized: true
                onClicked: root.saveHost()
            }

            SettingsActionButton {
                label: "Clear Form"
                iconName: "󰑐"
                onClicked: root.resetForm()
            }
        }

        Text {
            text: "Imported Aliases"
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }

        Repeater {
            model: pluginData.importedHosts
            delegate: SettingsListRow {
                required property var modelData
                minimumHeight: 52

                Text {
                    text: "󰣀"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: modelData.alias
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        font.weight: Font.Medium
                    }

                    Text {
                        text: modelData.sourcePath + ":" + modelData.sourceLine
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }
            }
        }

        Repeater {
            model: pluginData.importErrors
            delegate: SettingsDataRow {
                required property var modelData
                label: "Import Error"
                iconName: "󰅚"
                value: modelData.path + ":" + modelData.line + " " + modelData.message
                monoValue: false
            }
        }
    }
}
