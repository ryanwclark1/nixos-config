import QtQuick

Item {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null

    property string currentLabel: "Ref"
    property bool showUpdated: false
    property string failureMode: "none"
    property int count: 0
    property string lastUpdated: ""

    implicitWidth: 360
    implicitHeight: content.implicitHeight

    function _choiceIndex(list, value) {
        var current = String(value);
        for (var i = 0; i < list.length; ++i) {
            if (String(list[i]) === current)
                return i;
        }
        return 0;
    }

    function _cycleSetting(key, values, currentValue) {
        if (!pluginApi)
            return;
        var idx = _choiceIndex(values, currentValue);
        pluginApi.saveSetting(key, values[(idx + 1) % values.length]);
        notifyRuntimeRefresh();
        refresh();
    }

    function notifyRuntimeRefresh() {
        if (pluginService && pluginService.pluginRuntimeUpdated)
            pluginService.pluginRuntimeUpdated();
    }

    function resetPlugin() {
        if (!pluginApi)
            return;
        pluginApi.removeSetting("label");
        pluginApi.removeSetting("showUpdated");
        pluginApi.removeSetting("failureMode");
        pluginApi.removeSetting("lastSummaryQuery");
        pluginApi.saveStateEnvelope({
            stateVersion: 2,
            updatedAt: new Date().toISOString(),
            payload: {
                count: 0,
                lastUpdated: ""
            }
        });
        notifyRuntimeRefresh();
        refresh();
    }

    function refresh() {
        if (!pluginApi)
            return;
        currentLabel = String(pluginApi.loadSetting("label", "Ref"));
        showUpdated = pluginApi.loadSetting("showUpdated", false) === true;
        failureMode = String(pluginApi.loadSetting("failureMode", "none"));
        var state = pluginApi.loadState();
        if (!state || typeof state !== "object")
            state = ({});
        count = Math.max(0, Number(state.count || state.clicks || 0));
        lastUpdated = String(state.lastUpdated || "");
    }

    Component.onCompleted: refresh()

    Connections {
        target: pluginService ? pluginService : null
        function onPluginRuntimeUpdated() {
            root.refresh();
        }
    }

    Column {
        id: content
        width: parent ? parent.width : root.implicitWidth
        spacing: 10

        Text {
            text: pluginManifest ? pluginManifest.name : "Reference Local Toolkit"
            color: "#f5f7ff"
            font.pixelSize: 16
            font.bold: true
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: "#c4ccef"
            font.pixelSize: 12
            text: "Local reference plugin for bar widgets, launcher items, settings writes, state persistence, and controlled failure injection."
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: "#9aa7db"
            font.pixelSize: 12
            text: "Launcher trigger is fixed by manifest to !ref. Failure mode only affects the launcher provider so degraded diagnostics can be reproduced safely."
        }

        Rectangle {
            width: parent.width
            height: 36
            radius: 10
            color: "#223058"
            border.width: 1
            border.color: "#5168b5"

            Text {
                anchors.centerIn: parent
                text: "Label: " + currentLabel + "  |  Count: " + count
                color: "#f6f8ff"
                font.pixelSize: 12
            }
        }

        Rectangle {
            width: parent.width
            height: 36
            radius: 10
            color: "#1f2b4b"
            border.width: 1
            border.color: "#4f619e"

            Text {
                anchors.centerIn: parent
                text: lastUpdated === "" ? "Last updated: never" : ("Last updated: " + lastUpdated)
                color: "#d7dfff"
                font.pixelSize: 12
            }
        }

        Rectangle {
            width: parent.width
            height: 40
            radius: 10
            color: "#27407a"
            border.width: 1
            border.color: "#8eb4ff"

            Text {
                anchors.centerIn: parent
                text: "Cycle Label"
                color: "#f8fbff"
                font.pixelSize: 13
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root._cycleSetting("label", ["Ref", "Beacon", "Pulse"], root.currentLabel)
            }
        }

        Rectangle {
            width: parent.width
            height: 40
            radius: 10
            color: "#27407a"
            border.width: 1
            border.color: "#8eb4ff"

            Text {
                anchors.centerIn: parent
                text: showUpdated ? "Hide Updated Marker" : "Show Updated Marker"
                color: "#f8fbff"
                font.pixelSize: 13
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!pluginApi)
                        return;
                    pluginApi.saveSetting("showUpdated", !root.showUpdated);
                    root.notifyRuntimeRefresh();
                    root.refresh();
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 40
            radius: 10
            color: failureMode === "none" ? "#27407a" : "#7a3d27"
            border.width: 1
            border.color: failureMode === "none" ? "#8eb4ff" : "#ffb38e"

            Text {
                anchors.centerIn: parent
                text: "Failure Mode: " + failureMode + " (cycle)"
                color: "#f8fbff"
                font.pixelSize: 13
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root._cycleSetting("failureMode", ["none", "query", "execute"], root.failureMode)
            }
        }

        Rectangle {
            width: parent.width
            height: 40
            radius: 10
            color: "#56314b"
            border.width: 1
            border.color: "#f1a8cf"

            Text {
                anchors.centerIn: parent
                text: "Reset Plugin State + Settings"
                color: "#fff6fb"
                font.pixelSize: 13
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.resetPlugin()
            }
        }
    }
}
