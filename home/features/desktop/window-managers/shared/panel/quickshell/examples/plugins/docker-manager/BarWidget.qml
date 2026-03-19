pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "DockerUtils.js" as DU

Item {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null
    readonly property string pluginId: pluginManifest && pluginManifest.id ? String(pluginManifest.id) : "docker.manager"
    readonly property var daemon: pluginService ? pluginService.daemonInstances[pluginId] : null

    property bool popupOpen: false
    property string currentTab: "containers"
    property bool showPorts: true
    property bool autoScrollOnExpand: true
    property var expandedContainers: ({})
    property var expandedProjects: ({})
    property var expandedImages: ({})

    // RunImageDialog state
    property bool runDialogVisible: false
    property string runDialogImage: ""
    property string runDialogContainerName: ""
    property string runDialogHostPort: ""
    property string runDialogContainerPort: ""
    property string runDialogPortStatus: ""

    // System prune confirmation
    property bool pruneConfirmPending: false

    implicitWidth: triggerRect.implicitWidth
    implicitHeight: triggerRect.implicitHeight

    function loadPrefs() {
        if (!pluginApi)
            return;
        // Backward compat: migrate old boolean groupByCompose to currentTab
        if (pluginApi.loadSetting("groupByCompose", false) === true && currentTab === "containers")
            currentTab = "compose";
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

    function toggleImage(imageKey) {
        var next = Object.assign({}, expandedImages);
        next[imageKey] = !next[imageKey];
        expandedImages = next;
    }

    function containerActionLabel(containerData) {
        return containerData && containerData.isRunning ? "Restart" : "Start";
    }

    function healthDot(healthStatus) {
        if (healthStatus === "healthy") return "\u25CF ";
        if (healthStatus === "starting") return "\u25CF ";
        if (healthStatus === "unhealthy") return "\u25CF ";
        return "";
    }

    function healthDotColor(healthStatus) {
        if (healthStatus === "healthy") return "#5eead4";
        if (healthStatus === "starting") return "#fcd34d";
        if (healthStatus === "unhealthy") return "#f87171";
        return "transparent";
    }

    function tabCountText(tabKey) {
        if (!daemon) return "";
        if (tabKey === "containers") return String(daemon.containers ? daemon.containers.length : 0);
        if (tabKey === "compose") return String(daemon.composeProjects ? daemon.composeProjects.length : 0);
        if (tabKey === "images") return String(daemon.imageCount || 0);
        if (tabKey === "volumes") return String(daemon.volumeCount || 0);
        if (tabKey === "networks") return String(daemon.networkCount || 0);
        return "";
    }

    function openRunDialog(imageName) {
        runDialogImage = String(imageName || "");
        runDialogContainerName = "";
        var port = DU.guessDefaultPort(imageName);
        runDialogHostPort = String(port);
        runDialogContainerPort = String(port);
        runDialogPortStatus = "";
        runDialogVisible = true;
    }

    property var tabModel: {
        var tabs = [
            { key: "containers", label: "CTR", icon: "\uf489" },
            { key: "compose", label: "CMP", icon: "\uf387" }
        ];
        if (daemon && daemon.showImages)
            tabs.push({ key: "images", label: "IMG", icon: "\ueb47" });
        if (daemon && daemon.showVolumes)
            tabs.push({ key: "volumes", label: "VOL", icon: "\uf7c2" });
        if (daemon && daemon.showNetworks)
            tabs.push({ key: "networks", label: "NET", icon: "\uf6ff" });
        return tabs;
    }

    Component.onCompleted: loadPrefs()

    Connections {
        target: root.pluginService ? root.pluginService : null
        function onPluginRuntimeUpdated() {
            root.loadPrefs();
        }
    }

    Timer {
        id: pruneConfirmTimer
        interval: 2000
        repeat: false
        onTriggered: root.pruneConfirmPending = false
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

                    // Header row
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

                            // System Prune button
                            Rectangle {
                                width: 34
                                height: 30
                                radius: 10
                                color: root.pruneConfirmPending ? "#7f1d1d" : "#1e293b"
                                border.width: 1
                                border.color: root.pruneConfirmPending ? "#f87171" : "#475569"
                                Text {
                                    anchors.centerIn: parent
                                    text: root.pruneConfirmPending ? "!" : "P"
                                    color: root.pruneConfirmPending ? "#fca5a5" : "#e2e8f0"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (!root.daemon) return;
                                        if (root.daemon.confirmPrune && !root.pruneConfirmPending) {
                                            root.pruneConfirmPending = true;
                                            pruneConfirmTimer.restart();
                                        } else {
                                            root.pruneConfirmPending = false;
                                            root.daemon.systemPrune();
                                        }
                                    }
                                }
                            }

                            // Refresh button
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

                            // Close button
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

                    // Notice banner
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

                    // Tab strip
                    Row {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.tabModel
                            delegate: Rectangle {
                                id: tabButton
                                required property var modelData
                                required property int index
                                readonly property bool isActive: root.currentTab === modelData.key
                                readonly property bool isDisabled: modelData.key === "compose"
                                    && (!root.daemon || !root.daemon.composeProjects || root.daemon.composeProjects.length === 0)
                                width: Math.floor((parent.width - (root.tabModel.length - 1) * 4) / root.tabModel.length)
                                height: 30
                                radius: 10
                                color: isActive ? "#1d4ed8" : "#1e293b"
                                opacity: isDisabled ? 0.45 : 1
                                border.width: 1
                                border.color: isActive ? "#93c5fd" : "#475569"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: tabButton.modelData.label
                                        color: "#f8fafc"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    Text {
                                        text: root.tabCountText(tabButton.modelData.key)
                                        color: "#94a3b8"
                                        font.pixelSize: 9
                                        visible: text !== ""
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !tabButton.isDisabled
                                    onClicked: root.currentTab = tabButton.modelData.key
                                }
                            }
                        }
                    }

                    // Ports toggle (only on containers tab)
                    Rectangle {
                        visible: root.currentTab === "containers"
                        width: parent.width
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

                    // Main scrollable content
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

                            // ── Unavailable state ──
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

                            // ── Containers tab: empty state ──
                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "containers" && root.daemon.containers.length === 0
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

                            // ── Compose tab: empty state ──
                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "compose" && root.daemon.composeProjects.length === 0
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

                            // ════════════════════════════════
                            // ── CONTAINERS TAB ──
                            // ════════════════════════════════
                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "containers" ? root.daemon.containers : []
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

                                                Row {
                                                    spacing: 2
                                                    Text {
                                                        visible: containerCard.modelData.healthStatus !== ""
                                                        text: root.healthDot(containerCard.modelData.healthStatus)
                                                        color: root.healthDotColor(containerCard.modelData.healthStatus)
                                                        font.pixelSize: 11
                                                    }
                                                    Text {
                                                        text: containerCard.modelData.status || containerCard.modelData.state || ""
                                                        color: containerCard.modelData.isRunning ? "#5eead4" : (containerCard.modelData.isPaused ? "#fcd34d" : "#cbd5e1")
                                                        font.pixelSize: 11
                                                    }
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

                            // ════════════════════════════════
                            // ── COMPOSE TAB ──
                            // ════════════════════════════════
                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "compose" ? root.daemon.composeProjects : []
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

                                                        Row {
                                                            spacing: 2
                                                            Text {
                                                                visible: childContainerCard.modelData.healthStatus !== ""
                                                                text: root.healthDot(childContainerCard.modelData.healthStatus)
                                                                color: root.healthDotColor(childContainerCard.modelData.healthStatus)
                                                                font.pixelSize: 10
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

                            // ════════════════════════════════
                            // ── IMAGES TAB ──
                            // ════════════════════════════════

                            // Images header
                            Row {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "images"
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: (root.daemon ? root.daemon.imageCount : 0) + " image" + ((root.daemon && root.daemon.imageCount !== 1) ? "s" : "")
                                    color: "#94a3b8"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - pruneImagesBtn.width - 6
                                }

                                Rectangle {
                                    id: pruneImagesBtn
                                    width: 120
                                    height: 28
                                    radius: 10
                                    color: "#1e293b"
                                    border.width: 1
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Prune Dangling"
                                        color: "#f8fafc"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: { if (root.daemon) root.daemon.pruneImages(); }
                                    }
                                }
                            }

                            // Images empty
                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "images" && root.daemon.imageCount === 0
                                width: parent.width
                                radius: 14
                                color: "#111827"
                                border.width: 1
                                border.color: "#334155"
                                implicitHeight: emptyImagesText.implicitHeight + 20
                                Text {
                                    id: emptyImagesText
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    wrapMode: Text.WordWrap
                                    text: "No images found."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "images" ? root.daemon.images : []
                                delegate: Rectangle {
                                    id: imageCard
                                    required property var modelData
                                    readonly property bool expanded: root.expandedImages[modelData.id] === true
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: 1
                                    border.color: expanded ? "#38bdf8" : "#334155"
                                    implicitHeight: imageBodyColumn.implicitHeight + 18

                                    Column {
                                        id: imageBodyColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 6

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            Column {
                                                width: Math.max(120, parent.width - 76)
                                                spacing: 2

                                                Text {
                                                    text: imageCard.modelData.repo + (imageCard.modelData.tag && imageCard.modelData.tag !== "<none>" ? ":" + imageCard.modelData.tag : "")
                                                    color: "#f8fafc"
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Row {
                                                    spacing: 8
                                                    Text {
                                                        text: imageCard.modelData.size ? DU.formatBytes(imageCard.modelData.size) : ""
                                                        color: "#94a3b8"
                                                        font.pixelSize: 11
                                                        visible: text !== ""
                                                    }
                                                    Text {
                                                        text: imageCard.modelData.created || ""
                                                        color: "#94a3b8"
                                                        font.pixelSize: 11
                                                        visible: text !== ""
                                                    }
                                                }

                                                Rectangle {
                                                    height: 20
                                                    radius: 10
                                                    width: inUseLabel.implicitWidth + 14
                                                    color: imageCard.modelData.inUse ? "#0f2238" : "#1c1917"
                                                    border.width: 1
                                                    border.color: imageCard.modelData.inUse ? "#1d4ed8" : "#78716c"
                                                    Text {
                                                        id: inUseLabel
                                                        anchors.centerIn: parent
                                                        text: imageCard.modelData.inUse ? "In use" : "Unused"
                                                        color: imageCard.modelData.inUse ? "#93c5fd" : "#a8a29e"
                                                        font.pixelSize: 9
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: 58
                                                height: 28
                                                radius: 10
                                                color: imageCard.expanded ? "#0f172a" : "#1e293b"
                                                border.width: 1
                                                border.color: "#475569"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: imageCard.expanded ? "Hide" : "Show"
                                                    color: "#f8fafc"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        root.toggleImage(imageCard.modelData.id);
                                                        if (!imageCard.expanded)
                                                            root.ensureVisible(imageCard.y, imageCard.height + 80);
                                                    }
                                                }
                                            }
                                        }

                                        Column {
                                            visible: imageCard.expanded
                                            width: parent.width
                                            spacing: 6

                                            Text {
                                                text: "ID: " + (imageCard.modelData.id || "").slice(0, 20)
                                                color: "#64748b"
                                                font.pixelSize: 10
                                            }

                                            Row {
                                                width: parent.width
                                                spacing: 6

                                                Rectangle {
                                                    width: Math.floor((parent.width - 6) / 2)
                                                    height: 30
                                                    radius: 10
                                                    color: "#1e293b"
                                                    border.width: 1
                                                    border.color: "#475569"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "Run"
                                                        color: "#f8fafc"
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: {
                                                            var ref = imageCard.modelData.repo;
                                                            if (imageCard.modelData.tag && imageCard.modelData.tag !== "<none>")
                                                                ref += ":" + imageCard.modelData.tag;
                                                            root.openRunDialog(ref);
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    width: Math.floor((parent.width - 6) / 2)
                                                    height: 30
                                                    radius: 10
                                                    color: imageCard.modelData.inUse ? "#111827" : "#3f1d24"
                                                    opacity: imageCard.modelData.inUse ? 0.45 : 1
                                                    border.width: 1
                                                    border.color: imageCard.modelData.inUse ? "#475569" : "#f87171"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "Remove"
                                                        color: imageCard.modelData.inUse ? "#94a3b8" : "#fca5a5"
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        enabled: !imageCard.modelData.inUse
                                                        onClicked: { if (root.daemon) root.daemon.removeImage(imageCard.modelData.id); }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ════════════════════════════════
                            // ── VOLUMES TAB ──
                            // ════════════════════════════════

                            Row {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "volumes"
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: (root.daemon ? root.daemon.volumeCount : 0) + " volume" + ((root.daemon && root.daemon.volumeCount !== 1) ? "s" : "")
                                    color: "#94a3b8"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - pruneVolumesBtn.width - 6
                                }

                                Rectangle {
                                    id: pruneVolumesBtn
                                    width: 130
                                    height: 28
                                    radius: 10
                                    color: "#1e293b"
                                    border.width: 1
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Remove Unused"
                                        color: "#f8fafc"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: { if (root.daemon) root.daemon.pruneVolumes(); }
                                    }
                                }
                            }

                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "volumes" && root.daemon.volumeCount === 0
                                width: parent.width
                                radius: 14
                                color: "#111827"
                                border.width: 1
                                border.color: "#334155"
                                implicitHeight: emptyVolumesText.implicitHeight + 20
                                Text {
                                    id: emptyVolumesText
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    wrapMode: Text.WordWrap
                                    text: "No volumes found."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "volumes" ? root.daemon.volumes : []
                                delegate: Rectangle {
                                    id: volumeCard
                                    required property var modelData
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: 1
                                    border.color: "#334155"
                                    implicitHeight: volumeBodyColumn.implicitHeight + 18

                                    Column {
                                        id: volumeBodyColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 4

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            Column {
                                                width: Math.max(120, parent.width - 76)
                                                spacing: 2

                                                Text {
                                                    text: volumeCard.modelData.name
                                                    color: "#f8fafc"
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Text {
                                                    text: "Driver: " + volumeCard.modelData.driver
                                                    color: "#94a3b8"
                                                    font.pixelSize: 11
                                                }

                                                Text {
                                                    visible: volumeCard.modelData.mountpoint !== ""
                                                    text: volumeCard.modelData.mountpoint
                                                    color: "#64748b"
                                                    font.pixelSize: 10
                                                    elide: Text.ElideMiddle
                                                    width: parent.width
                                                }
                                            }

                                            Rectangle {
                                                width: 58
                                                height: 28
                                                radius: 10
                                                color: "#3f1d24"
                                                border.width: 1
                                                border.color: "#f87171"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Del"
                                                    color: "#fca5a5"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: { if (root.daemon) root.daemon.removeVolume(volumeCard.modelData.name); }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ════════════════════════════════
                            // ── NETWORKS TAB ──
                            // ════════════════════════════════

                            Row {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "networks"
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: (root.daemon ? root.daemon.networkCount : 0) + " network" + ((root.daemon && root.daemon.networkCount !== 1) ? "s" : "")
                                    color: "#94a3b8"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - pruneNetworksBtn.width - 6
                                }

                                Rectangle {
                                    id: pruneNetworksBtn
                                    width: 130
                                    height: 28
                                    radius: 10
                                    color: "#1e293b"
                                    border.width: 1
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Remove Unused"
                                        color: "#f8fafc"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: { if (root.daemon) root.daemon.pruneNetworks(); }
                                    }
                                }
                            }

                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "networks" && root.daemon.networkCount === 0
                                width: parent.width
                                radius: 14
                                color: "#111827"
                                border.width: 1
                                border.color: "#334155"
                                implicitHeight: emptyNetworksText.implicitHeight + 20
                                Text {
                                    id: emptyNetworksText
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    wrapMode: Text.WordWrap
                                    text: "No networks found."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "networks" ? root.daemon.networks : []
                                delegate: Rectangle {
                                    id: networkCard
                                    required property var modelData
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: 1
                                    border.color: "#334155"
                                    implicitHeight: networkBodyColumn.implicitHeight + 18

                                    Column {
                                        id: networkBodyColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 4

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            Column {
                                                width: Math.max(120, parent.width - 76)
                                                spacing: 2

                                                Text {
                                                    text: networkCard.modelData.name
                                                    color: "#f8fafc"
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }

                                                Row {
                                                    spacing: 8
                                                    Text {
                                                        text: "Driver: " + networkCard.modelData.driver
                                                        color: "#94a3b8"
                                                        font.pixelSize: 11
                                                    }
                                                    Text {
                                                        visible: networkCard.modelData.scope !== ""
                                                        text: "Scope: " + networkCard.modelData.scope
                                                        color: "#94a3b8"
                                                        font.pixelSize: 11
                                                    }
                                                }

                                                Rectangle {
                                                    visible: networkCard.modelData.isDefault
                                                    height: 20
                                                    radius: 10
                                                    width: defaultNetLabel.implicitWidth + 14
                                                    color: "#1c1917"
                                                    border.width: 1
                                                    border.color: "#78716c"
                                                    Text {
                                                        id: defaultNetLabel
                                                        anchors.centerIn: parent
                                                        text: "Default"
                                                        color: "#a8a29e"
                                                        font.pixelSize: 9
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: 58
                                                height: 28
                                                radius: 10
                                                color: networkCard.modelData.isDefault ? "#111827" : "#3f1d24"
                                                opacity: networkCard.modelData.isDefault ? 0.45 : 1
                                                border.width: 1
                                                border.color: networkCard.modelData.isDefault ? "#475569" : "#f87171"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Del"
                                                    color: networkCard.modelData.isDefault ? "#94a3b8" : "#fca5a5"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    enabled: !networkCard.modelData.isDefault
                                                    onClicked: { if (root.daemon) root.daemon.removeNetwork(networkCard.modelData.name); }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ════════════════════════════════
                    // ── RUN IMAGE DIALOG ──
                    // ════════════════════════════════
                    Rectangle {
                        visible: root.runDialogVisible
                        width: parent.width
                        radius: 14
                        color: "#1e293b"
                        border.width: 1
                        border.color: "#38bdf8"
                        implicitHeight: runDialogColumn.implicitHeight + 24

                        Column {
                            id: runDialogColumn
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: "Run Image"
                                color: "#f8fafc"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
                                text: "Image: " + root.runDialogImage
                                color: "#94a3b8"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Row {
                                width: parent.width
                                spacing: 6
                                Text {
                                    text: "Name:"
                                    color: "#e2e8f0"
                                    font.pixelSize: 11
                                    width: 50
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: parent.width - 56
                                    height: 28
                                    radius: 8
                                    color: "#0f172a"
                                    border.width: 1
                                    border.color: "#475569"
                                    TextInput {
                                        id: runNameInput
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        color: "#f8fafc"
                                        font.pixelSize: 11
                                        text: root.runDialogContainerName
                                        onTextChanged: root.runDialogContainerName = text
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: 6
                                Text {
                                    text: "Host:"
                                    color: "#e2e8f0"
                                    font.pixelSize: 11
                                    width: 50
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: 80
                                    height: 28
                                    radius: 8
                                    color: "#0f172a"
                                    border.width: 1
                                    border.color: "#475569"
                                    TextInput {
                                        id: runHostPortInput
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        color: "#f8fafc"
                                        font.pixelSize: 11
                                        text: root.runDialogHostPort
                                        onTextChanged: root.runDialogHostPort = text
                                    }
                                }
                                Text {
                                    text: ":"
                                    color: "#94a3b8"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: 80
                                    height: 28
                                    radius: 8
                                    color: "#0f172a"
                                    border.width: 1
                                    border.color: "#475569"
                                    TextInput {
                                        id: runContainerPortInput
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        color: "#f8fafc"
                                        font.pixelSize: 11
                                        text: root.runDialogContainerPort
                                        onTextChanged: root.runDialogContainerPort = text
                                    }
                                }

                                Rectangle {
                                    width: 60
                                    height: 28
                                    radius: 8
                                    color: "#0f172a"
                                    border.width: 1
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Check"
                                        color: "#93c5fd"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (root.daemon) {
                                                root.runDialogPortStatus = "...";
                                                root.daemon.checkPortAvailable(Number(root.runDialogHostPort) || 0, function(available) {
                                                    root.runDialogPortStatus = available ? "Free" : "In use";
                                                });
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: root.runDialogPortStatus !== ""
                                text: "Port status: " + root.runDialogPortStatus
                                color: root.runDialogPortStatus === "Free" ? "#5eead4" : (root.runDialogPortStatus === "In use" ? "#f87171" : "#94a3b8")
                                font.pixelSize: 10
                            }

                            Row {
                                width: parent.width
                                spacing: 6

                                Rectangle {
                                    width: Math.floor((parent.width - 6) / 2)
                                    height: 30
                                    radius: 10
                                    color: "#1d4ed8"
                                    border.width: 1
                                    border.color: "#93c5fd"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Run"
                                        color: "#f8fafc"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (root.daemon)
                                                root.daemon.runImage(root.runDialogImage, root.runDialogContainerName, root.runDialogHostPort, root.runDialogContainerPort);
                                            root.runDialogVisible = false;
                                        }
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
                                        text: "Cancel"
                                        color: "#f8fafc"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.runDialogVisible = false
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
