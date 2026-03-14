pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

Item {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null
    readonly property string pluginId: pluginManifest && pluginManifest.id ? String(pluginManifest.id) : "docker.manager"
    readonly property var daemon: pluginService ? pluginService.daemonInstances[pluginId] : null

    property bool popupOpen: false
    property bool composeView: false
    property bool showPorts: true
    property bool autoScrollOnExpand: true
    property var expandedContainers: ({})
    property var expandedProjects: ({})

    implicitWidth: triggerRect.implicitWidth
    implicitHeight: triggerRect.implicitHeight

    function loadPrefs() {
        if (!pluginApi)
            return;
        composeView = pluginApi.loadSetting("groupByCompose", false) === true;
        showPorts = pluginApi.loadSetting("showPorts", true) === true;
        autoScrollOnExpand = pluginApi.loadSetting("autoScrollOnExpand", true) === true;
    }

    function savePref(key, value) {
        if (!pluginApi || !pluginApi.saveSetting)
            return;
        pluginApi.saveSetting(key, value);
        if (root.daemon && root.daemon.reloadFromSettings)
            root.daemon.reloadFromSettings();
        else if (root.pluginService && root.pluginService.pluginRuntimeUpdated)
            root.pluginService.pluginRuntimeUpdated();
    }

    function runtimeCountText() {
        if (!daemon)
            return "?";
        return String(daemon.runningContainers || 0);
    }

    function runtimeBadgeColor() {
        if (!daemon)
            return "#6b7280";
        if (!daemon.runtimeAvailable)
            return "#7f1d1d";
        if (daemon.runningContainers > 0)
            return "#0f766e";
        return "#334155";
    }

    function runtimeAccentColor() {
        if (!daemon)
            return "#d1d5db";
        if (!daemon.runtimeAvailable)
            return "#fca5a5";
        if (daemon.runningContainers > 0)
            return "#99f6e4";
        return "#cbd5e1";
    }

    function ensureVisible(itemY, itemHeight) {
        if (!autoScrollOnExpand)
            return;
        var minY = itemY;
        var maxY = itemY + itemHeight;
        if (minY < scroller.contentY)
            scroller.contentY = Math.max(0, minY - 12);
        else if (maxY > scroller.contentY + scroller.height)
            scroller.contentY = Math.min(scroller.contentHeight - scroller.height, maxY - scroller.height + 12);
    }

    function toggleContainer(containerKey) {
        var next = Object.assign({}, expandedContainers);
        next[containerKey] = !next[containerKey];
        expandedContainers = next;
    }

    function toggleProject(projectKey) {
        var next = Object.assign({}, expandedProjects);
        next[projectKey] = !next[projectKey];
        expandedProjects = next;
    }

    function containerActionLabel(containerData) {
        return containerData && containerData.isRunning ? "Restart" : "Start";
    }

    Component.onCompleted: loadPrefs()

    Connections {
        target: root.pluginService ? root.pluginService : null
        function onPluginRuntimeUpdated() {
            root.loadPrefs();
        }
    }

    Rectangle {
        id: triggerRect
        radius: 13
        height: 28
        implicitWidth: badgeRow.implicitWidth + 22
        color: root.runtimeBadgeColor()
        border.width: 1
        border.color: Qt.lighter(root.runtimeAccentColor(), 1.15)

        Row {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.daemon && root.daemon.runtimeAvailable ? (String(root.daemon.runtimeName || "Docker").charAt(0)) : "!"
                color: root.runtimeAccentColor()
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                text: root.runtimeCountText()
                color: "#f8fafc"
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                visible: root.daemon && root.daemon.busy
                text: "..."
                color: "#e2e8f0"
                font.pixelSize: 11
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.popupOpen = !root.popupOpen
        }
    }

    PopupWindow {
        id: popup
        visible: root.popupOpen
        color: "transparent"
        anchor.item: triggerRect
        implicitWidth: 430
        implicitHeight: Math.min(560, popupBody.implicitHeight)

        Rectangle {
            id: popupBody
            width: 430
            implicitHeight: Math.min(contentColumn.implicitHeight + 28, 560)
            radius: 16
            color: "#0f172a"
            border.width: 1
            border.color: "#334155"

            FocusScope {
                id: popupFocus
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: root.popupOpen = false

                Column {
                    id: contentColumn
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Row {
                        width: parent.width
                        spacing: 8

                        Column {
                            width: Math.max(160, parent.width - actionButtons.width - 8)
                            spacing: 4

                            Text {
                                text: "Docker Manager"
                                color: "#f8fafc"
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: root.daemon ? root.daemon.statusMessage : "Waiting for plugin daemon."
                                color: "#94a3b8"
                                font.pixelSize: 11
                            }
                        }

                        Row {
                            id: actionButtons
                            spacing: 6

                            Rectangle {
                                width: 34
                                height: 30
                                radius: 10
                                color: "#1e293b"
                                border.width: 1
                                border.color: "#475569"
                                Text {
                                    anchors.centerIn: parent
                                    text: "R"
                                    color: "#e2e8f0"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (root.daemon && root.daemon.scheduleRefresh)
                                            root.daemon.scheduleRefresh(0);
                                    }
                                }
                            }

                            Rectangle {
                                width: 34
                                height: 30
                                radius: 10
                                color: "#1e293b"
                                border.width: 1
                                border.color: "#475569"
                                Text {
                                    anchors.centerIn: parent
                                    text: "X"
                                    color: "#e2e8f0"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.popupOpen = false
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.daemon && root.daemon.noticeMessage !== ""
                        width: parent.width
                        height: noticeText.implicitHeight + 16
                        radius: 12
                        color: root.daemon && root.daemon.noticeKind === "error"
                            ? "#3f1d24"
                            : (root.daemon && root.daemon.noticeKind === "warn" ? "#3b2f16" : "#12334b")
                        border.width: 1
                        border.color: root.daemon && root.daemon.noticeKind === "error"
                            ? "#f87171"
                            : (root.daemon && root.daemon.noticeKind === "warn" ? "#fbbf24" : "#38bdf8")

                        Text {
                            id: noticeText
                            anchors.fill: parent
                            anchors.margins: 8
                            wrapMode: Text.WordWrap
                            text: root.daemon ? root.daemon.noticeMessage : ""
                            color: "#f8fafc"
                            font.pixelSize: 11
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: 120
                            height: 30
                            radius: 10
                            color: !root.composeView ? "#1d4ed8" : "#1e293b"
                            border.width: 1
                            border.color: !root.composeView ? "#93c5fd" : "#475569"
                            Text {
                                anchors.centerIn: parent
                                text: "Containers"
                                color: "#f8fafc"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.composeView = false;
                                    root.savePref("groupByCompose", false);
                                }
                            }
                        }

                        Rectangle {
                            width: 120
                            height: 30
                            radius: 10
                            enabled: root.daemon && root.daemon.composeProjects && root.daemon.composeProjects.length > 0
                            color: root.composeView ? "#1d4ed8" : "#1e293b"
                            opacity: enabled ? 1 : 0.45
                            border.width: 1
                            border.color: root.composeView ? "#93c5fd" : "#475569"
                            Text {
                                anchors.centerIn: parent
                                text: "Compose"
                                color: "#f8fafc"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: parent.enabled
                                onClicked: {
                                    root.composeView = true;
                                    root.savePref("groupByCompose", true);
                                }
                            }
                        }

                        Rectangle {
                            width: 120
                            height: 30
                            radius: 10
                            color: root.showPorts ? "#1e3a2a" : "#1e293b"
                            border.width: 1
                            border.color: root.showPorts ? "#6ee7b7" : "#475569"
                            Text {
                                anchors.centerIn: parent
                                text: root.showPorts ? "Ports On" : "Ports Off"
                                color: "#f8fafc"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.showPorts = !root.showPorts;
                                    root.savePref("showPorts", root.showPorts);
                                }
                            }
                        }
                    }

                    Flickable {
                        id: scroller
                        width: parent.width
                        height: 430
                        clip: true
                        contentHeight: listColumn.implicitHeight

                        Column {
                            id: listColumn
                            width: scroller.width
                            spacing: 8

                            Rectangle {
                                visible: !root.daemon || !root.daemon.runtimeAvailable
                                width: parent.width
                                radius: 14
                                color: "#1f2937"
                                border.width: 1
                                border.color: "#7f1d1d"
                                implicitHeight: unavailableText.implicitHeight + 20

                                Text {
                                    id: unavailableText
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    wrapMode: Text.WordWrap
                                    text: root.daemon ? root.daemon.statusMessage : "Docker Manager daemon is not ready."
                                    color: "#fecaca"
                                    font.pixelSize: 12
                                }
                            }

                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && !root.composeView && root.daemon.containers.length === 0
                                width: parent.width
                                radius: 14
                                color: "#111827"
                                border.width: 1
                                border.color: "#334155"
                                implicitHeight: emptyText.implicitHeight + 20

                                Text {
                                    id: emptyText
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    wrapMode: Text.WordWrap
                                    text: "No containers were found."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.composeView && root.daemon.composeProjects.length === 0
                                width: parent.width
                                radius: 14
                                color: "#111827"
                                border.width: 1
                                border.color: "#334155"
                                implicitHeight: emptyComposeText.implicitHeight + 20

                                Text {
                                    id: emptyComposeText
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    wrapMode: Text.WordWrap
                                    text: "No compose-labelled projects were found for the current runtime."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && !root.composeView ? root.daemon.containers : []
                                delegate: Rectangle {
                                    id: containerCard
                                    required property var modelData
                                    readonly property bool expanded: root.expandedContainers[modelData.id] === true
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: 1
                                    border.color: expanded ? "#38bdf8" : "#334155"
                                    implicitHeight: bodyColumn.implicitHeight + 18

                                    Column {
                                        id: bodyColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 8

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            Column {
                                                width: Math.max(120, parent.width - 76)
                                                spacing: 2

                                                Text {
                                                    text: containerCard.modelData.name || containerCard.modelData.id
                                                    color: "#f8fafc"
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: containerCard.modelData.image || ""
                                                    color: "#94a3b8"
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: containerCard.modelData.status || containerCard.modelData.state || ""
                                                    color: containerCard.modelData.isRunning ? "#5eead4" : (containerCard.modelData.isPaused ? "#fcd34d" : "#cbd5e1")
                                                    font.pixelSize: 11
                                                }
                                            }

                                            Rectangle {
                                                width: 58
                                                height: 28
                                                radius: 10
                                                color: containerCard.expanded ? "#0f172a" : "#1e293b"
                                                border.width: 1
                                                border.color: "#475569"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: containerCard.expanded ? "Hide" : "Show"
                                                    color: "#f8fafc"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        root.toggleContainer(containerCard.modelData.id);
                                                        if (!containerCard.expanded)
                                                            root.ensureVisible(containerCard.y, containerCard.height + 120);
                                                    }
                                                }
                                            }
                                        }

                                        Flow {
                                            visible: containerCard.expanded && root.showPorts && containerCard.modelData.ports && containerCard.modelData.ports.length > 0
                                            width: parent.width
                                            spacing: 6

                                            Repeater {
                                                model: containerCard.modelData.ports
                                                delegate: Rectangle {
                                                    id: portChip
                                                    required property var modelData
                                                    height: 24
                                                    radius: 12
                                                    color: "#0f2238"
                                                    border.width: 1
                                                    border.color: "#1d4ed8"
                                                    width: portLabel.implicitWidth + 18

                                                    Text {
                                                        id: portLabel
                                                        anchors.centerIn: parent
                                                        text: portChip.modelData.hostPort + " -> " + String(portChip.modelData.containerPort || "").replace(/\/(tcp|udp)$/, "")
                                                        color: "#bfdbfe"
                                                        font.pixelSize: 10
                                                    }
                                                }
                                            }
                                        }

                                        Column {
                                            visible: containerCard.expanded
                                            width: parent.width
                                            spacing: 6

                                            Row {
                                                width: parent.width
                                                spacing: 6

                                                Repeater {
                                                    model: [
                                                        {
                                                            label: root.containerActionLabel(containerCard.modelData),
                                                            enabled: containerCard.modelData.isPaused !== true,
                                                            action: function() {
                                                                root.daemon.executeContainerAction(containerCard.modelData.id || containerCard.modelData.name, containerCard.modelData.isRunning ? "restart" : "start");
                                                            }
                                                        },
                                                        {
                                                            label: containerCard.modelData.isPaused ? "Unpause" : "Pause",
                                                            enabled: containerCard.modelData.isRunning || containerCard.modelData.isPaused,
                                                            action: function() {
                                                                root.daemon.executeContainerAction(containerCard.modelData.id || containerCard.modelData.name, containerCard.modelData.isPaused ? "unpause" : "pause");
                                                            }
                                                        },
                                                        {
                                                            label: "Stop",
                                                            enabled: containerCard.modelData.isRunning || containerCard.modelData.isPaused,
                                                            action: function() {
                                                                root.daemon.executeContainerAction(containerCard.modelData.id || containerCard.modelData.name, "stop");
                                                            }
                                                        }
                                                    ]
                                                    delegate: Rectangle {
                                                        id: containerActionButton
                                                        required property var modelData
                                                        width: Math.floor((parent.width - 12) / 3)
                                                        height: 30
                                                        radius: 10
                                                        color: containerActionButton.modelData.enabled ? "#1e293b" : "#111827"
                                                        opacity: containerActionButton.modelData.enabled ? 1 : 0.45
                                                        border.width: 1
                                                        border.color: "#475569"
                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: containerActionButton.modelData.label
                                                            color: "#f8fafc"
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            enabled: parent.opacity >= 1
                                                            onClicked: containerActionButton.modelData.action()
                                                        }
                                                    }
                                                }
                                            }

                                            Row {
                                                width: parent.width
                                                spacing: 6

                                                Rectangle {
                                                    width: Math.floor((parent.width - 6) / 2)
                                                    height: 30
                                                    radius: 10
                                                    color: containerCard.modelData.isRunning ? "#1e293b" : "#111827"
                                                    opacity: containerCard.modelData.isRunning ? 1 : 0.45
                                                    border.width: 1
                                                    border.color: "#475569"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "Shell"
                                                        color: "#f8fafc"
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        enabled: containerCard.modelData.isRunning
                                                        onClicked: root.daemon.openShell(containerCard.modelData.id || containerCard.modelData.name)
                                                    }
                                                }

                                                Rectangle {
                                                    width: Math.floor((parent.width - 6) / 2)
                                                    height: 30
                                                    radius: 10
                                                    color: "#1e293b"
                                                    border.width: 1
                                                    border.color: "#475569"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "Logs"
                                                        color: "#f8fafc"
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: root.daemon.openLogs(containerCard.modelData.id || containerCard.modelData.name)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.composeView ? root.daemon.composeProjects : []
                                delegate: Rectangle {
                                    id: projectCard
                                    required property var modelData
                                    readonly property bool expanded: root.expandedProjects[modelData.name] === true
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: 1
                                    border.color: expanded ? "#38bdf8" : "#334155"
                                    implicitHeight: projectColumn.implicitHeight + 18

                                    Column {
                                        id: projectColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 8

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            Column {
                                                width: Math.max(120, parent.width - 76)
                                                spacing: 2

                                                Text {
                                                    text: projectCard.modelData.name
                                                    color: "#f8fafc"
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: projectCard.modelData.runningCount + " / " + projectCard.modelData.totalCount + " running"
                                                    color: "#94a3b8"
                                                    font.pixelSize: 11
                                                }
                                            }

                                            Rectangle {
                                                width: 58
                                                height: 28
                                                radius: 10
                                                color: projectCard.expanded ? "#0f172a" : "#1e293b"
                                                border.width: 1
                                                border.color: "#475569"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: projectCard.expanded ? "Hide" : "Show"
                                                    color: "#f8fafc"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        root.toggleProject(projectCard.modelData.name);
                                                        if (!projectCard.expanded)
                                                            root.ensureVisible(projectCard.y, projectCard.height + 160);
                                                    }
                                                }
                                            }
                                        }

                                        Column {
                                            visible: projectCard.expanded
                                            width: parent.width
                                            spacing: 6

                                            Row {
                                                width: parent.width
                                                spacing: 6

                                                Repeater {
                                                    model: [
                                                        {
                                                            label: "Start",
                                                            enabled: projectCard.modelData.runningCount < projectCard.modelData.totalCount,
                                                            action: function() { root.daemon.executeComposeAction(projectCard.modelData, "start"); }
                                                        },
                                                        {
                                                            label: "Restart",
                                                            enabled: projectCard.modelData.runningCount > 0,
                                                            action: function() { root.daemon.executeComposeAction(projectCard.modelData, "restart"); }
                                                        },
                                                        {
                                                            label: "Stop",
                                                            enabled: projectCard.modelData.runningCount > 0,
                                                            action: function() { root.daemon.executeComposeAction(projectCard.modelData, "stop"); }
                                                        }
                                                    ]
                                                    delegate: Rectangle {
                                                        id: projectActionButton
                                                        required property var modelData
                                                        width: Math.floor((parent.width - 12) / 3)
                                                        height: 30
                                                        radius: 10
                                                        color: projectActionButton.modelData.enabled ? "#1e293b" : "#111827"
                                                        opacity: projectActionButton.modelData.enabled ? 1 : 0.45
                                                        border.width: 1
                                                        border.color: "#475569"
                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: projectActionButton.modelData.label
                                                            color: "#f8fafc"
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            enabled: parent.opacity >= 1
                                                            onClicked: projectActionButton.modelData.action()
                                                        }
                                                    }
                                                }
                                            }

                                            Row {
                                                width: parent.width
                                                spacing: 6

                                                Repeater {
                                                    model: [
                                                        {
                                                            label: "Pull",
                                                            enabled: true,
                                                            action: function() { root.daemon.executeComposeAction(projectCard.modelData, "pull"); }
                                                        },
                                                        {
                                                            label: "Logs",
                                                            enabled: true,
                                                            action: function() { root.daemon.executeComposeAction(projectCard.modelData, "logs"); }
                                                        }
                                                    ]
                                                    delegate: Rectangle {
                                                        id: projectSecondaryActionButton
                                                        required property var modelData
                                                        width: Math.floor((parent.width - 6) / 2)
                                                        height: 30
                                                        radius: 10
                                                        color: "#1e293b"
                                                        border.width: 1
                                                        border.color: "#475569"
                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: projectSecondaryActionButton.modelData.label
                                                            color: "#f8fafc"
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            onClicked: projectSecondaryActionButton.modelData.action()
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: parent.width
                                                height: 1
                                                color: "#1e293b"
                                            }

                                            Repeater {
                                                model: projectCard.modelData.containers
                                                delegate: Rectangle {
                                                    id: childContainerCard
                                                    required property var modelData
                                                    width: parent.width
                                                    radius: 12
                                                    color: "#0f172a"
                                                    border.width: 1
                                                    border.color: "#1e293b"
                                                    implicitHeight: childColumn.implicitHeight + 14

                                                    Column {
                                                        id: childColumn
                                                        anchors.fill: parent
                                                        anchors.margins: 7
                                                        spacing: 4

                                                        Text {
                                                            text: (childContainerCard.modelData.composeService || childContainerCard.modelData.name || childContainerCard.modelData.id)
                                                            color: "#f8fafc"
                                                            font.pixelSize: 12
                                                            font.bold: true
                                                        }

                                                        Text {
                                                            text: childContainerCard.modelData.status || childContainerCard.modelData.state || ""
                                                            color: childContainerCard.modelData.isRunning ? "#5eead4" : (childContainerCard.modelData.isPaused ? "#fcd34d" : "#cbd5e1")
                                                            font.pixelSize: 10
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
