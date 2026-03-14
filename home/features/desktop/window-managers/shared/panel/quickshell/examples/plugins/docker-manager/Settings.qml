import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null
    readonly property string pluginId: pluginManifest && pluginManifest.id ? String(pluginManifest.id) : "docker.manager"
    readonly property var daemon: pluginService ? pluginService.daemonInstances[pluginId] : null

    implicitWidth: 420
    implicitHeight: contentColumn.implicitHeight

    function saveSetting(key, value) {
        if (!pluginApi || !pluginApi.saveSetting)
            return;
        pluginApi.saveSetting(key, value);
        if (root.daemon && root.daemon.reloadFromSettings)
            root.daemon.reloadFromSettings();
        else if (root.pluginService && root.pluginService.pluginRuntimeUpdated)
            root.pluginService.pluginRuntimeUpdated();
    }

    function resetDefaults() {
        if (!pluginApi || !pluginApi.removeSetting)
            return;
        var keys = [
            "dockerBinary",
            "debounceDelay",
            "fallbackRefreshInterval",
            "terminalCommand",
            "shellPath",
            "showPorts",
            "autoScrollOnExpand",
            "groupByCompose"
        ];
        for (var i = 0; i < keys.length; ++i)
            pluginApi.removeSetting(keys[i]);
        loadValues();
        if (root.daemon && root.daemon.reloadFromSettings)
            root.daemon.reloadFromSettings();
    }

    function loadValues() {
        if (!pluginApi || !pluginApi.loadSetting)
            return;
        dockerBinaryField.text = String(pluginApi.loadSetting("dockerBinary", "docker"));
        debounceValue.value = Number(pluginApi.loadSetting("debounceDelay", 300));
        refreshValue.value = Number(pluginApi.loadSetting("fallbackRefreshInterval", 30000));
        terminalField.text = String(pluginApi.loadSetting("terminalCommand", "kitty -e bash -lc"));
        shellField.text = String(pluginApi.loadSetting("shellPath", "/bin/sh"));
        showPortsCheck.checked = pluginApi.loadSetting("showPorts", true) === true;
        autoScrollCheck.checked = pluginApi.loadSetting("autoScrollOnExpand", true) === true;
        composeViewCheck.checked = pluginApi.loadSetting("groupByCompose", false) === true;
    }

    Component.onCompleted: loadValues()

    Column {
        id: contentColumn
        width: parent ? parent.width : root.implicitWidth
        spacing: 12

        Text {
            text: "Docker Manager Settings"
            color: "#f8fafc"
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Configure the container runtime, refresh behavior, and popup preferences for the Docker Manager plugin."
            color: "#cbd5e1"
            font.pixelSize: 12
        }

        Rectangle {
            width: parent.width
            radius: 12
            color: "#0f172a"
            border.width: 1
            border.color: "#334155"
            implicitHeight: infoText.implicitHeight + 18

            Text {
                id: infoText
                anchors.fill: parent
                anchors.margins: 9
                wrapMode: Text.WordWrap
                text: root.daemon
                    ? ("Runtime: " + root.daemon.runtimeName + " | " + root.daemon.statusMessage)
                    : "The daemon will pick up changes as soon as this settings page saves them."
                color: "#e2e8f0"
                font.pixelSize: 11
            }
        }

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            Text {
                text: "Runtime Binary"
                color: "#e2e8f0"
                font.pixelSize: 12
            }

            TextField {
                id: dockerBinaryField
                Layout.fillWidth: true
                placeholderText: "docker"
                onEditingFinished: root.saveSetting("dockerBinary", text.trim() || "docker")
            }

            Text {
                text: "Debounce Delay (ms)"
                color: "#e2e8f0"
                font.pixelSize: 12
            }

            SpinBox {
                id: debounceValue
                Layout.fillWidth: true
                from: 100
                to: 5000
                stepSize: 50
                editable: true
                onValueModified: root.saveSetting("debounceDelay", value)
            }

            Text {
                text: "Fallback Refresh (ms)"
                color: "#e2e8f0"
                font.pixelSize: 12
            }

            SpinBox {
                id: refreshValue
                Layout.fillWidth: true
                from: 5000
                to: 300000
                stepSize: 1000
                editable: true
                onValueModified: root.saveSetting("fallbackRefreshInterval", value)
            }

            Text {
                text: "Terminal Command"
                color: "#e2e8f0"
                font.pixelSize: 12
            }

            TextField {
                id: terminalField
                Layout.fillWidth: true
                placeholderText: "kitty -e bash -lc"
                onEditingFinished: root.saveSetting("terminalCommand", text.trim() || "kitty -e bash -lc")
            }

            Text {
                text: "Shell Path"
                color: "#e2e8f0"
                font.pixelSize: 12
            }

            TextField {
                id: shellField
                Layout.fillWidth: true
                placeholderText: "/bin/sh"
                onEditingFinished: root.saveSetting("shellPath", text.trim() || "/bin/sh")
            }
        }

        Column {
            width: parent.width
            spacing: 6

            CheckBox {
                id: showPortsCheck
                text: "Show port mappings in expanded rows"
                onToggled: root.saveSetting("showPorts", checked)
            }

            CheckBox {
                id: autoScrollCheck
                text: "Auto-scroll popup when rows expand"
                onToggled: root.saveSetting("autoScrollOnExpand", checked)
            }

            CheckBox {
                id: composeViewCheck
                text: "Default popup view to compose projects"
                onToggled: root.saveSetting("groupByCompose", checked)
            }
        }

        Row {
            spacing: 10

            Button {
                text: "Reload Now"
                onClicked: {
                    if (root.daemon && root.daemon.reloadFromSettings)
                        root.daemon.reloadFromSettings();
                }
            }

            Button {
                text: "Reset Defaults"
                onClicked: root.resetDefaults()
            }
        }
    }
}
