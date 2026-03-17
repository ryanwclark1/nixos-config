import QtQuick
import QtQuick.Layouts
import "../services"
import "../menu/settings"
import "." as SharedWidgets

ColumnLayout {
    id: root

    property var widgetInstance: null
    property string editingHostId: ""
    property string manualSearchQuery: ""
    property string formId: ""
    property string formLabel: ""
    property string formHost: ""
    property string formUser: ""
    property string formPort: "22"
    property string formRemoteCommand: ""
    property string formTags: ""
    property string formGroup: ""
    property string formError: ""

    readonly property bool isEditingExisting: editingHostId !== ""
    readonly property var filteredManualHosts: {
        var query = String(manualSearchQuery || "").trim().toLowerCase();
        var list = [];
        for (var i = 0; i < sshData.manualHosts.length; ++i) {
            var host = sshData.manualHosts[i];
            if (query !== "" && String(host.searchText || "").toLowerCase().indexOf(query) === -1)
                continue;
            list.push({
                index: i,
                host: host
            });
        }
        return list;
    }

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
        editingHostId = String(host.id || "");
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

    function duplicateHost(index) {
        var host = sshData.manualHosts[index];
        if (!host)
            return;
        editingHostId = "";
        formId = "";
        formLabel = String(host.label || "SSH Host").trim() + " Copy";
        formHost = String(host.host || "");
        formUser = String(host.user || "");
        formPort = String(host.port || 22);
        formRemoteCommand = String(host.remoteCommand || "");
        formTags = Array.isArray(host.tags) ? host.tags.join(", ") : "";
        formGroup = String(host.group || "");
        formError = "";
    }

    function resetForm() {
        editingHostId = "";
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

    function _currentEditingIndex() {
        if (editingHostId === "")
            return -1;
        for (var i = 0; i < sshData.manualHosts.length; ++i) {
            if (String(sshData.manualHosts[i].id || "") === editingHostId)
                return i;
        }
        return -1;
    }

    function saveHost() {
        var label = String(formLabel || "").trim();
        var host = String(formHost || "").trim();
        var user = String(formUser || "").trim();
        var remoteCommand = String(formRemoteCommand || "").trim();
        var tags = String(formTags || "").split(",").map(function(tag) {
            return String(tag || "").trim();
        }).filter(function(tag) {
            return tag !== "";
        }).join(", ");
        var group = String(formGroup || "").trim();
        var portText = String(formPort || "").trim();
        var port = portText === "" ? 22 : Number(portText);

        if (label === "" || host === "") {
            formError = "Label and host are required.";
            return;
        }
        if (!isFinite(port) || Math.floor(port) !== port || port < 1 || port > 65535) {
            formError = "Port must be a whole number between 1 and 65535.";
            return;
        }

        var next = JSON.parse(JSON.stringify(sshData.manualHosts || []));
        var normalizedHost = {
            id: String(formId || "").trim(),
            label: label,
            host: host,
            user: user,
            port: port,
            remoteCommand: remoteCommand,
            tags: tags,
            group: group
        };
        var currentIndex = _currentEditingIndex();
        if (currentIndex >= 0 && currentIndex < next.length)
            next[currentIndex] = normalizedHost;
        else
            next.push(normalizedHost);
        sshData.saveManualHosts(next);
        resetForm();
    }

    function removeHost(index) {
        var next = JSON.parse(JSON.stringify(sshData.manualHosts || []));
        if (index < 0 || index >= next.length)
            return;
        var removedId = String(next[index].id || "");
        next.splice(index, 1);
        sshData.saveManualHosts(next);
        if (editingHostId === removedId)
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

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: overviewColumn.implicitHeight + Colors.spacingM * 2
        radius: Colors.radiusMedium
        color: Colors.modalFieldSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            id: overviewColumn
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS

            Text {
                text: "Overview"
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
            }

            SettingsDataRow {
                Layout.fillWidth: true
                label: "Import Root"
                iconName: "󰈔"
                value: sshData.importRootPath
            }

            SettingsDataRow {
                Layout.fillWidth: true
                label: "Imported Aliases"
                iconName: "󰮔"
                value: String(sshData.importedHosts.length)
                monoValue: false
            }

            SettingsDataRow {
                Layout.fillWidth: true
                label: "Skipped Patterns"
                iconName: "󰇘"
                value: String(sshData.skippedPatternEntries.length)
                monoValue: false
            }

            SettingsDataRow {
                Layout.fillWidth: true
                label: "Import Errors"
                iconName: "󰅚"
                value: String(sshData.importErrors.length)
                monoValue: false
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
        }
    }

    SharedWidgets.CollapsibleSection {
        Layout.fillWidth: true
        title: "Import Diagnostics"
        icon: "󰅚"
        expanded: sshData.importErrors.length > 0 || sshData.skippedPatternEntries.length > 0

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            SettingsInfoCallout {
                Layout.fillWidth: true
                visible: sshData.importErrors.length === 0 && sshData.skippedPatternEntries.length === 0
                title: "No import diagnostics"
                body: "SSH config import has no current errors or skipped wildcard patterns."
            }

            Repeater {
                model: sshData.importErrors

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: errorColumn.implicitHeight + Colors.spacingS * 2
                    radius: Colors.radiusSmall
                    color: Colors.withAlpha(Colors.warning, 0.08)
                    border.color: Colors.withAlpha(Colors.warning, 0.35)
                    border.width: 1

                    ColumnLayout {
                        id: errorColumn
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: Colors.spacingXXS

                        Text {
                            text: String(modelData.message || "Import error")
                            color: Colors.warning
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: String(modelData.path || "") + (Number(modelData.line || 0) > 0 ? (":" + String(modelData.line || 0)) : "")
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            font.family: Colors.fontMono
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }

            Repeater {
                model: sshData.skippedPatternEntries

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: skippedColumn.implicitHeight + Colors.spacingS * 2
                    radius: Colors.radiusSmall
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1

                    ColumnLayout {
                        id: skippedColumn
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: Colors.spacingXXS

                        Text {
                            text: "Skipped pattern: " + String(modelData.alias || "")
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: String(modelData.sourcePath || "") + (Number(modelData.sourceLine || 0) > 0 ? (":" + String(modelData.sourceLine || 0)) : "")
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            font.family: Colors.fontMono
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: listColumn.implicitHeight + Colors.spacingM * 2
        radius: Colors.radiusMedium
        color: Colors.modalFieldSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            id: listColumn
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    text: "Manual Hosts"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                SharedWidgets.FilterChip {
                    label: String(root.filteredManualHosts.length) + "/" + String(sshData.manualHosts.length)
                    selected: false
                    enabled: false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: height / 2
                color: Colors.bgWidget
                border.color: manualSearchInput.activeFocus ? Colors.primary : Colors.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Colors.spacingM
                    anchors.rightMargin: Colors.spacingM
                    spacing: Colors.spacingS

                    Text {
                        text: "󰍉"
                        color: Colors.textDisabled
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeMedium
                    }

                    TextInput {
                        id: manualSearchInput
                        Layout.fillWidth: true
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        clip: true
                        text: root.manualSearchQuery
                        onTextChanged: root.manualSearchQuery = text

                        Text {
                            anchors.fill: parent
                            text: "Filter manual hosts..."
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeSmall
                            visible: !manualSearchInput.text && !manualSearchInput.activeFocus
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.filteredManualHosts.length === 0
                text: root.manualSearchQuery.trim() !== "" ? "No manual hosts match \"" + root.manualSearchQuery + "\"." : "No manual hosts saved yet."
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: root.filteredManualHosts

                delegate: Rectangle {
                    required property var modelData
                    readonly property var host: modelData.host
                    readonly property int hostIndex: modelData.index
                    readonly property bool editingThisHost: String(host.id || "") === root.editingHostId

                    Layout.fillWidth: true
                    implicitHeight: hostColumn.implicitHeight + Colors.spacingM * 2
                    radius: Colors.radiusSmall
                    color: editingThisHost ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface
                    border.color: editingThisHost ? Colors.primary : Colors.border
                    border.width: 1

                    ColumnLayout {
                        id: hostColumn
                        anchors.fill: parent
                        anchors.margins: Colors.spacingM
                        spacing: Colors.spacingS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS

                            Text {
                                text: host.label
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            SharedWidgets.FilterChip {
                                visible: editingThisHost
                                label: "Editing"
                                selected: true
                                enabled: false
                            }
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

                            SharedWidgets.FilterChip {
                                visible: String(host.group || "") !== ""
                                label: String(host.group || "")
                                selected: false
                                enabled: false
                            }

                            SharedWidgets.FilterChip {
                                visible: String(host.user || "") !== ""
                                label: String(host.user || "")
                                selected: false
                                enabled: false
                            }

                            Repeater {
                                model: Array.isArray(host.tags) ? host.tags : []

                                delegate: SharedWidgets.FilterChip {
                                    required property var modelData
                                    visible: String(modelData || "").trim() !== ""
                                    label: "#" + String(modelData || "")
                                    selected: false
                                    enabled: false
                                }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Colors.spacingS

                            SettingsActionButton {
                                compact: true
                                iconName: "󰏫"
                                label: "Up"
                                enabled: hostIndex > 0
                                onClicked: root.moveHost(hostIndex, -1)
                            }

                            SettingsActionButton {
                                compact: true
                                iconName: "󰏬"
                                label: "Down"
                                enabled: hostIndex < (sshData.manualHosts.length - 1)
                                onClicked: root.moveHost(hostIndex, 1)
                            }

                            SettingsActionButton {
                                compact: true
                                iconName: "󰏫"
                                label: "Edit"
                                onClicked: root.editHostAt(hostIndex)
                            }

                            SettingsActionButton {
                                compact: true
                                iconName: "󰑕"
                                label: "Duplicate"
                                onClicked: root.duplicateHost(hostIndex)
                            }

                            SettingsActionButton {
                                compact: true
                                iconName: "󰅖"
                                label: "Remove"
                                onClicked: root.removeHost(hostIndex)
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: editorColumn.implicitHeight + Colors.spacingM * 2
        radius: Colors.radiusMedium
        color: Colors.modalFieldSurface
        border.color: root.formError !== "" ? Colors.error : (root.isEditingExisting ? Colors.primary : Colors.border)
        border.width: 1

        ColumnLayout {
            id: editorColumn
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    text: root.isEditingExisting ? "Edit Host" : "Host Editor"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                SharedWidgets.FilterChip {
                    label: root.isEditingExisting ? "Existing" : "New"
                    selected: root.isEditingExisting
                    enabled: false
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.isEditingExisting
                    ? "Update the selected manual host. Cancel returns to list mode without saving."
                    : "Create a new manual SSH host entry. Save persists only when the draft validates."
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                wrapMode: Text.WordWrap
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
                    label: root.isEditingExisting ? "Save Changes" : "Save Host"
                    onClicked: root.saveHost()
                }

                SettingsActionButton {
                    compact: true
                    iconName: "󰜉"
                    label: "Clear"
                    onClicked: root.resetForm()
                }

                SettingsActionButton {
                    compact: true
                    iconName: "󰗼"
                    label: "Cancel"
                    visible: root.isEditingExisting
                    onClicked: root.resetForm()
                }
            }
        }
    }
}
