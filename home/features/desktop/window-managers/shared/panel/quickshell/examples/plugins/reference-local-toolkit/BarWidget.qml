import QtQuick

Item {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null

    property string displayLabel: "Ref"
    property bool showUpdated: false
    property int count: 0
    property string lastUpdated: ""

    implicitWidth: badge.implicitWidth
    implicitHeight: 26

    function _normalizedStatePayload(payload) {
        var raw = payload && typeof payload === "object" ? payload : ({});
        return {
            count: Math.max(0, Number(raw.count || raw.clicks || 0)),
            lastUpdated: String(raw.lastUpdated || "")
        };
    }

    function _migrateStateIfNeeded() {
        if (!pluginApi || !pluginApi.migrateState)
            return;
        pluginApi.migrateState(2, function(payload, nextVersion) {
            var next = payload && typeof payload === "object" ? Object.assign({}, payload) : ({});
            if (nextVersion === 2) {
                if (next.count === undefined && next.clicks !== undefined)
                    next.count = next.clicks;
                delete next.clicks;
                if (next.lastUpdated === undefined)
                    next.lastUpdated = "";
            }
            return next;
        });
    }

    function syncFromPlugin() {
        if (!pluginApi)
            return;
        displayLabel = String(pluginApi.loadSetting("label", "Ref"));
        showUpdated = pluginApi.loadSetting("showUpdated", false) === true;
        _migrateStateIfNeeded();
        var state = _normalizedStatePayload(pluginApi.loadStateEnvelope().payload);
        count = state.count;
        lastUpdated = state.lastUpdated;
    }

    function persistState() {
        if (!pluginApi)
            return;
        pluginApi.saveStateEnvelope({
            stateVersion: 2,
            updatedAt: new Date().toISOString(),
            payload: {
                count: count,
                lastUpdated: lastUpdated
            }
        });
    }

    function incrementCount() {
        count += 1;
        lastUpdated = new Date().toISOString();
        persistState();
        if (pluginService && pluginService.pluginRuntimeUpdated)
            pluginService.pluginRuntimeUpdated();
    }

    Component.onCompleted: syncFromPlugin()

    Connections {
        target: pluginService ? pluginService : null
        function onPluginRuntimeUpdated() {
            root.syncFromPlugin();
        }
    }

    Rectangle {
        id: badge
        radius: 13
        height: 26
        implicitWidth: content.implicitWidth + 18
        color: mouseArea.pressed ? "#4c6ef5" : "#2d3d74"
        border.width: 1
        border.color: "#8fb0ff"

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: displayLabel
                color: "#f6f7fb"
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                text: String(count)
                color: "#c9d6ff"
                font.pixelSize: 12
            }

            Text {
                visible: showUpdated && lastUpdated !== ""
                text: "•"
                color: "#a9c2ff"
                font.pixelSize: 12
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.incrementCount()
        }
    }
}
