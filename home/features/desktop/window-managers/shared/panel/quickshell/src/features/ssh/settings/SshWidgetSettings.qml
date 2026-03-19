import QtQuick
import QtQuick.Layouts
import ".."
import "../../../services"
import "../../../features/settings/components"

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
        var host = sshData.manualHosts[index];
        var target = index + delta;
        if (!host || target < 0 || target >= sshData.manualHosts.length)
            return;
        sshData.moveManualHost(host.id, target);
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

    SshSettingsOverview {
        Layout.fillWidth: true
        sshData: sshData
        onResetStateRequested: sshData.resetStateOnly()
        onResetAllRequested: {
            sshData.resetAll();
            root.resetForm();
        }
    }

    SshImportDiagnostics {
        Layout.fillWidth: true
        sshData: sshData
    }

    SshHostList {
        Layout.fillWidth: true
        sshData: sshData
        filteredManualHosts: root.filteredManualHosts
        editingHostId: root.editingHostId
        searchQuery: root.manualSearchQuery
        onEditHost: (index) => root.editHostAt(index)
        onDuplicateHost: (index) => root.duplicateHost(index)
        onRemoveHost: (index) => root.removeHost(index)
        onMoveHost: (index, delta) => root.moveHost(index, delta)
        onSearchChanged: (query) => root.manualSearchQuery = query
    }

    SshHostEditor {
        Layout.fillWidth: true
        formLabel: root.formLabel
        formHost: root.formHost
        formUser: root.formUser
        formPort: root.formPort
        formRemoteCommand: root.formRemoteCommand
        formTags: root.formTags
        formGroup: root.formGroup
        formError: root.formError
        isEditingExisting: root.isEditingExisting
        onSave: root.saveHost()
        onClear: root.resetForm()
        onCancel: root.resetForm()
        onFieldChanged: (field, value) => {
            switch (field) {
            case "label": root.formLabel = value; break;
            case "host": root.formHost = value; break;
            case "user": root.formUser = value; break;
            case "port": root.formPort = value; break;
            case "remoteCommand": root.formRemoteCommand = value; break;
            case "tags": root.formTags = value; break;
            case "group": root.formGroup = value; break;
            }
        }
    }
}
