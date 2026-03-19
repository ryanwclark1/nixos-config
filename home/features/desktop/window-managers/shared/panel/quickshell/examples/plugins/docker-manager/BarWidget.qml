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

    // F6: Search/filter
    property string searchQuery: ""

    // F5: Bulk selection
    property bool selectionMode: false
    property var selectedContainers: ({})
    property var selectedImages: ({})
    property var selectedVolumes: ({})
    property var selectedNetworks: ({})

    // F11: Keyboard navigation
    property int focusedCardIndex: -1

    // RunImageDialog state
    property bool runDialogVisible: false
    property string runDialogImage: ""
    property string runDialogContainerName: ""
    property string runDialogHostPort: ""
    property string runDialogContainerPort: ""
    property string runDialogPortStatus: ""

    // System prune confirmation
    property bool pruneConfirmPending: false

    // Cached filtered lists (avoids redundant filter calls across bindings)
    readonly property var _filteredContainers: daemon && daemon.runtimeAvailable && currentTab === "containers" ? filteredList(daemon.containers, searchQuery) : []
    readonly property var _filteredCompose: daemon && daemon.runtimeAvailable && currentTab === "compose" ? filteredList(daemon.composeProjects, searchQuery) : []
    readonly property var _filteredImages: daemon && daemon.runtimeAvailable && currentTab === "images" ? filteredList(daemon.images, searchQuery) : []
    readonly property var _filteredVolumes: daemon && daemon.runtimeAvailable && currentTab === "volumes" ? filteredList(daemon.volumes, searchQuery) : []
    readonly property var _filteredNetworks: daemon && daemon.runtimeAvailable && currentTab === "networks" ? filteredList(daemon.networks, searchQuery) : []

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

    // F6: Filter a list by search query
    function filteredList(sourceList, query) {
        if (!sourceList || !Array.isArray(sourceList))
            return [];
        var q = String(query || "").trim();
        if (q === "")
            return sourceList;
        var result = [];
        for (var i = 0; i < sourceList.length; i++) {
            if (DU.matchesFilter(sourceList[i], q))
                result.push(sourceList[i]);
        }
        return result;
    }

    // F5: Selection helpers
    function _selectedCount() {
        var map;
        if (currentTab === "containers") map = selectedContainers;
        else if (currentTab === "images") map = selectedImages;
        else if (currentTab === "volumes") map = selectedVolumes;
        else if (currentTab === "networks") map = selectedNetworks;
        else return 0;
        var count = 0;
        for (var k in map)
            if (map[k]) count++;
        return count;
    }

    function _toggleSelection(key) {
        var map, setter;
        if (currentTab === "containers") { map = selectedContainers; setter = function(m) { selectedContainers = m; }; }
        else if (currentTab === "images") { map = selectedImages; setter = function(m) { selectedImages = m; }; }
        else if (currentTab === "volumes") { map = selectedVolumes; setter = function(m) { selectedVolumes = m; }; }
        else if (currentTab === "networks") { map = selectedNetworks; setter = function(m) { selectedNetworks = m; }; }
        else return;
        var next = Object.assign({}, map);
        next[key] = !next[key];
        setter(next);
    }

    function _clearSelection() {
        selectedContainers = ({});
        selectedImages = ({});
        selectedVolumes = ({});
        selectedNetworks = ({});
    }

    function _executeBulkAction(action) {
        if (!daemon) return;
        var map, keys, i;
        if (currentTab === "containers") {
            map = selectedContainers;
            keys = Object.keys(map).filter(function(k) { return map[k]; });
            for (i = 0; i < keys.length; i++)
                daemon.executeContainerAction(keys[i], action);
        } else if (currentTab === "images") {
            map = selectedImages;
            keys = Object.keys(map).filter(function(k) { return map[k]; });
            for (i = 0; i < keys.length; i++)
                daemon.removeImage(keys[i]);
        } else if (currentTab === "volumes") {
            map = selectedVolumes;
            keys = Object.keys(map).filter(function(k) { return map[k]; });
            for (i = 0; i < keys.length; i++)
                daemon.removeVolume(keys[i]);
        } else if (currentTab === "networks") {
            map = selectedNetworks;
            keys = Object.keys(map).filter(function(k) { return map[k]; });
            for (i = 0; i < keys.length; i++)
                daemon.removeNetwork(keys[i]);
        }
        _clearSelection();
    }

    // F11: Keyboard helpers
    function _currentListLength() {
        var list;
        if (currentTab === "containers") list = _filteredContainers;
        else if (currentTab === "compose") list = _filteredCompose;
        else if (currentTab === "images") list = _filteredImages;
        else if (currentTab === "volumes") list = _filteredVolumes;
        else if (currentTab === "networks") list = _filteredNetworks;
        else return 0;
        return list ? list.length : 0;
    }

    function _nextTab() {
        var keys = tabModel.map(function(t) { return t.key; });
        var idx = keys.indexOf(currentTab);
        if (idx >= 0 && idx < keys.length - 1) currentTab = keys[idx + 1];
        else if (keys.length > 0) currentTab = keys[0];
    }

    function _prevTab() {
        var keys = tabModel.map(function(t) { return t.key; });
        var idx = keys.indexOf(currentTab);
        if (idx > 0) currentTab = keys[idx - 1];
        else if (keys.length > 0) currentTab = keys[keys.length - 1];
    }

    function _activateFocusedCard() {
        if (focusedCardIndex < 0) return;
        if (currentTab === "containers") {
            if (focusedCardIndex < _filteredContainers.length) toggleContainer(_filteredContainers[focusedCardIndex].id);
        } else if (currentTab === "compose") {
            if (focusedCardIndex < _filteredCompose.length) toggleProject(_filteredCompose[focusedCardIndex].name);
        } else if (currentTab === "images") {
            if (focusedCardIndex < _filteredImages.length) toggleImage(_filteredImages[focusedCardIndex].id);
        }
    }

    onCurrentTabChanged: {
        searchQuery = "";
        focusedCardIndex = -1;
        if (selectionMode)
            _clearSelection();
    }

    // F1: Toggle stats polling on popup open/close
    onPopupOpenChanged: {
        if (daemon)
            daemon.statsPollingActive = popupOpen;
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

                Keys.onPressed: event => {
                    // F11: Keyboard navigation
                    if (event.key === Qt.Key_Escape) {
                        if (root.searchQuery !== "") {
                            root.searchQuery = "";
                            event.accepted = true;
                        } else {
                            root.popupOpen = false;
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Tab && !event.modifiers) {
                        root._nextTab();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
                        root._prevTab();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backtab) {
                        root._prevTab();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        var maxLen = root._currentListLength();
                        if (root.focusedCardIndex < maxLen - 1)
                            root.focusedCardIndex++;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (root.focusedCardIndex > 0)
                            root.focusedCardIndex--;
                        else
                            root.focusedCardIndex = -1;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root._activateFocusedCard();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Slash) {
                        searchInput.forceActiveFocus();
                        event.accepted = true;
                    }
                }

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

                            // F5: Selection mode toggle
                            Rectangle {
                                width: 34
                                height: 30
                                radius: 10
                                color: root.selectionMode ? "#1d4ed8" : "#1e293b"
                                border.width: 1
                                border.color: root.selectionMode ? "#93c5fd" : "#475569"
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u2611"
                                    color: root.selectionMode ? "#93c5fd" : "#e2e8f0"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.selectionMode = !root.selectionMode;
                                        if (!root.selectionMode)
                                            root._clearSelection();
                                    }
                                }
                            }

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

                    // F6: Search bar
                    Rectangle {
                        visible: root.daemon && root.daemon.runtimeAvailable
                        width: parent.width
                        height: 30
                        radius: 10
                        color: "#0f172a"
                        border.width: searchInput.activeFocus ? 2 : 1
                        border.color: searchInput.activeFocus ? "#93c5fd" : "#334155"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6

                            Text {
                                text: "/"
                                color: "#64748b"
                                font.pixelSize: 12
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TextInput {
                                id: searchInput
                                width: parent.width - 20
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#f8fafc"
                                font.pixelSize: 11
                                text: root.searchQuery
                                onTextChanged: root.searchQuery = text
                                Keys.onEscapePressed: {
                                    root.searchQuery = "";
                                    text = "";
                                    popupFocus.forceActiveFocus();
                                }
                            }
                        }

                        Text {
                            visible: root.searchQuery === ""
                            text: "Search..."
                            color: "#475569"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 26
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
                        height: 390
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
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "containers" && root._filteredContainers.length === 0
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
                                    text: root.searchQuery !== "" ? "No containers match the filter." : "No containers were found."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            // ── Compose tab: empty state ──
                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "compose" && root._filteredCompose.length === 0
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
                                    text: root.searchQuery !== "" ? "No compose projects match the filter." : "No compose-labelled projects were found for the current runtime."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            // ════════════════════════════════
                            // ── CONTAINERS TAB ──
                            // ════════════════════════════════
                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "containers" ? root._filteredContainers : []
                                delegate: Rectangle {
                                    id: containerCard
                                    required property var modelData
                                    required property int index
                                    readonly property bool expanded: root.expandedContainers[modelData.id] === true
                                    readonly property bool isFocused: root.focusedCardIndex === index
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: isFocused ? 2 : 1
                                    border.color: isFocused ? "#93c5fd" : (expanded ? "#38bdf8" : "#334155")
                                    implicitHeight: bodyColumn.implicitHeight + 18

                                    Column {
                                        id: bodyColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 8

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            // F5: Selection checkbox
                                            Rectangle {
                                                visible: root.selectionMode
                                                width: 20
                                                height: 20
                                                radius: 4
                                                color: root.selectedContainers[containerCard.modelData.id] ? "#1d4ed8" : "#1e293b"
                                                border.width: 1
                                                border.color: root.selectedContainers[containerCard.modelData.id] ? "#93c5fd" : "#475569"
                                                anchors.verticalCenter: parent.verticalCenter
                                                Text {
                                                    visible: root.selectedContainers[containerCard.modelData.id] === true
                                                    anchors.centerIn: parent
                                                    text: "\u2713"
                                                    color: "#f8fafc"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: root._toggleSelection(containerCard.modelData.id)
                                                }
                                            }

                                            Column {
                                                width: Math.max(120, parent.width - 76 - (root.selectionMode ? 28 : 0))
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

                                                // F1: Container stats (CPU/Mem) inline
                                                Row {
                                                    visible: containerCard.modelData.isRunning && root.daemon && root.daemon.containerStats[containerCard.modelData.id] !== undefined
                                                    spacing: 10
                                                    Text {
                                                        text: "CPU: " + (root.daemon && root.daemon.containerStats[containerCard.modelData.id] ? root.daemon.containerStats[containerCard.modelData.id].cpuPercent : "")
                                                        color: "#94a3b8"
                                                        font.pixelSize: 10
                                                    }
                                                    Text {
                                                        text: "Mem: " + (root.daemon && root.daemon.containerStats[containerCard.modelData.id] ? root.daemon.containerStats[containerCard.modelData.id].memUsage : "")
                                                        color: "#94a3b8"
                                                        font.pixelSize: 10
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
                                                        if (!containerCard.expanded) {
                                                            root.ensureVisible(containerCard.y, containerCard.height + 120);
                                                            if (root.daemon && root.daemon.fetchLogs)
                                                                root.daemon.fetchLogs(containerCard.modelData.id);
                                                        }
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

                                        // F3: Inline log preview
                                        Rectangle {
                                            visible: containerCard.expanded && root.daemon && root.daemon.containerLogs[containerCard.modelData.id] !== undefined
                                            width: parent.width
                                            radius: 8
                                            color: "#020617"
                                            border.width: 1
                                            border.color: "#1e293b"
                                            implicitHeight: Math.min(logPreviewText.implicitHeight + 12, 160)
                                            clip: true

                                            Text {
                                                id: logPreviewText
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                wrapMode: Text.WrapAnywhere
                                                text: root.daemon && root.daemon.containerLogs[containerCard.modelData.id] ? root.daemon.containerLogs[containerCard.modelData.id] : ""
                                                color: "#94a3b8"
                                                font.pixelSize: 9
                                                font.family: "monospace"
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
                                                        text: "Full Logs"
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
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "compose" ? root._filteredCompose : []
                                delegate: Rectangle {
                                    id: projectCard
                                    required property var modelData
                                    required property int index
                                    readonly property bool expanded: root.expandedProjects[modelData.name] === true
                                    readonly property bool isFocused: root.focusedCardIndex === index
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: isFocused ? 2 : 1
                                    border.color: isFocused ? "#93c5fd" : (expanded ? "#38bdf8" : "#334155")
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
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "images" && root._filteredImages.length === 0
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
                                    text: root.searchQuery !== "" ? "No images match the filter." : "No images found."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "images" ? root._filteredImages : []
                                delegate: Rectangle {
                                    id: imageCard
                                    required property var modelData
                                    required property int index
                                    readonly property bool expanded: root.expandedImages[modelData.id] === true
                                    readonly property bool isFocused: root.focusedCardIndex === index
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: isFocused ? 2 : 1
                                    border.color: isFocused ? "#93c5fd" : (expanded ? "#38bdf8" : "#334155")
                                    implicitHeight: imageBodyColumn.implicitHeight + 18

                                    Column {
                                        id: imageBodyColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 6

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            // F5: Selection checkbox
                                            Rectangle {
                                                visible: root.selectionMode
                                                width: 20
                                                height: 20
                                                radius: 4
                                                color: root.selectedImages[imageCard.modelData.id] ? "#1d4ed8" : "#1e293b"
                                                border.width: 1
                                                border.color: root.selectedImages[imageCard.modelData.id] ? "#93c5fd" : "#475569"
                                                anchors.verticalCenter: parent.verticalCenter
                                                Text {
                                                    visible: root.selectedImages[imageCard.modelData.id] === true
                                                    anchors.centerIn: parent
                                                    text: "\u2713"
                                                    color: "#f8fafc"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: root._toggleSelection(imageCard.modelData.id)
                                                }
                                            }

                                            Column {
                                                width: Math.max(120, parent.width - 76 - (root.selectionMode ? 28 : 0))
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
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "volumes" && root._filteredVolumes.length === 0
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
                                    text: root.searchQuery !== "" ? "No volumes match the filter." : "No volumes found."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "volumes" ? root._filteredVolumes : []
                                delegate: Rectangle {
                                    id: volumeCard
                                    required property var modelData
                                    required property int index
                                    readonly property bool isFocused: root.focusedCardIndex === index
                                    readonly property var usedBy: root.daemon && root.daemon.volumeUsageMap[modelData.name] ? root.daemon.volumeUsageMap[modelData.name] : []
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: isFocused ? 2 : 1
                                    border.color: isFocused ? "#93c5fd" : "#334155"
                                    implicitHeight: volumeBodyColumn.implicitHeight + 18

                                    Column {
                                        id: volumeBodyColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 4

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            // F5: Selection checkbox
                                            Rectangle {
                                                visible: root.selectionMode
                                                width: 20
                                                height: 20
                                                radius: 4
                                                color: root.selectedVolumes[volumeCard.modelData.name] ? "#1d4ed8" : "#1e293b"
                                                border.width: 1
                                                border.color: root.selectedVolumes[volumeCard.modelData.name] ? "#93c5fd" : "#475569"
                                                anchors.verticalCenter: parent.verticalCenter
                                                Text {
                                                    visible: root.selectedVolumes[volumeCard.modelData.name] === true
                                                    anchors.centerIn: parent
                                                    text: "\u2713"
                                                    color: "#f8fafc"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: root._toggleSelection(volumeCard.modelData.name)
                                                }
                                            }

                                            Column {
                                                width: Math.max(120, parent.width - 76 - (root.selectionMode ? 28 : 0))
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

                                                // F4: Volume cross-reference
                                                Text {
                                                    visible: volumeCard.usedBy.length > 0
                                                    text: "Used by: " + volumeCard.usedBy.join(", ")
                                                    color: "#93c5fd"
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }
                                            }

                                            Rectangle {
                                                width: 58
                                                height: 28
                                                radius: 10
                                                color: volumeCard.usedBy.length > 0 ? "#111827" : "#3f1d24"
                                                opacity: volumeCard.usedBy.length > 0 ? 0.45 : 1
                                                border.width: 1
                                                border.color: volumeCard.usedBy.length > 0 ? "#475569" : "#f87171"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Del"
                                                    color: volumeCard.usedBy.length > 0 ? "#94a3b8" : "#fca5a5"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    enabled: volumeCard.usedBy.length === 0
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
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "networks" && root.filteredList(root.daemon.networks, root.searchQuery).length === 0
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
                                    text: root.searchQuery !== "" ? "No networks match the filter." : "No networks found."
                                    color: "#cbd5e1"
                                    font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "networks" ? root.filteredList(root.daemon.networks, root.searchQuery) : []
                                delegate: Rectangle {
                                    id: networkCard
                                    required property var modelData
                                    required property int index
                                    readonly property bool isFocused: root.focusedCardIndex === index
                                    readonly property var usedBy: root.daemon && root.daemon.networkUsageMap[modelData.name] ? root.daemon.networkUsageMap[modelData.name] : []
                                    readonly property bool isProtected: modelData.isDefault || usedBy.length > 0
                                    width: listColumn.width
                                    radius: 14
                                    color: "#111827"
                                    border.width: isFocused ? 2 : 1
                                    border.color: isFocused ? "#93c5fd" : "#334155"
                                    implicitHeight: networkBodyColumn.implicitHeight + 18

                                    Column {
                                        id: networkBodyColumn
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 4

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            // F5: Selection checkbox
                                            Rectangle {
                                                visible: root.selectionMode
                                                width: 20
                                                height: 20
                                                radius: 4
                                                color: root.selectedNetworks[networkCard.modelData.name] ? "#1d4ed8" : "#1e293b"
                                                border.width: 1
                                                border.color: root.selectedNetworks[networkCard.modelData.name] ? "#93c5fd" : "#475569"
                                                anchors.verticalCenter: parent.verticalCenter
                                                Text {
                                                    visible: root.selectedNetworks[networkCard.modelData.name] === true
                                                    anchors.centerIn: parent
                                                    text: "\u2713"
                                                    color: "#f8fafc"
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: root._toggleSelection(networkCard.modelData.name)
                                                }
                                            }

                                            Column {
                                                width: Math.max(120, parent.width - 76 - (root.selectionMode ? 28 : 0))
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

                                                // F4: Network cross-reference
                                                Text {
                                                    visible: networkCard.usedBy.length > 0
                                                    text: "Used by: " + networkCard.usedBy.join(", ")
                                                    color: "#93c5fd"
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                    width: parent.width
                                                }
                                            }

                                            Rectangle {
                                                width: 58
                                                height: 28
                                                radius: 10
                                                color: networkCard.isProtected ? "#111827" : "#3f1d24"
                                                opacity: networkCard.isProtected ? 0.45 : 1
                                                border.width: 1
                                                border.color: networkCard.isProtected ? "#475569" : "#f87171"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Del"
                                                    color: networkCard.isProtected ? "#94a3b8" : "#fca5a5"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    enabled: !networkCard.isProtected
                                                    onClicked: { if (root.daemon) root.daemon.removeNetwork(networkCard.modelData.name); }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // F5: Bulk action bar
                    Rectangle {
                        visible: root.selectionMode && root._selectedCount() > 0
                        width: parent.width
                        height: 36
                        radius: 10
                        color: "#1e293b"
                        border.width: 1
                        border.color: "#475569"

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: root._selectedCount() + " selected"
                                color: "#94a3b8"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Repeater {
                                model: {
                                    if (root.currentTab === "containers")
                                        return [{ label: "Stop Selected", action: "stop" }, { label: "Restart Selected", action: "restart" }];
                                    if (root.currentTab === "images")
                                        return [{ label: "Remove Selected", action: "remove" }];
                                    if (root.currentTab === "volumes")
                                        return [{ label: "Remove Selected", action: "remove" }];
                                    if (root.currentTab === "networks")
                                        return [{ label: "Remove Selected", action: "remove" }];
                                    return [];
                                }
                                delegate: Rectangle {
                                    id: bulkActionBtn
                                    required property var modelData
                                    width: bulkLabel.implicitWidth + 16
                                    height: 26
                                    radius: 8
                                    color: "#3f1d24"
                                    border.width: 1
                                    border.color: "#f87171"
                                    Text {
                                        id: bulkLabel
                                        anchors.centerIn: parent
                                        text: bulkActionBtn.modelData.label
                                        color: "#fca5a5"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root._executeBulkAction(bulkActionBtn.modelData.action)
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

                            // F2: Pull progress status
                            Text {
                                visible: root.daemon && root.daemon.pullInProgress
                                text: root.daemon ? root.daemon.pullStatus : ""
                                color: "#38bdf8"
                                font.pixelSize: 10
                                wrapMode: Text.WrapAnywhere
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
                                        activeFocusOnTab: true
                                        KeyNavigation.tab: runHostPortInput
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
                                        activeFocusOnTab: true
                                        KeyNavigation.tab: runContainerPortInput
                                        KeyNavigation.backtab: runNameInput
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
                                        activeFocusOnTab: true
                                        KeyNavigation.backtab: runHostPortInput
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
                                    color: (root.daemon && root.daemon.pullInProgress) ? "#334155" : "#1d4ed8"
                                    opacity: (root.daemon && root.daemon.pullInProgress) ? 0.6 : 1
                                    border.width: 1
                                    border.color: "#93c5fd"
                                    Text {
                                        anchors.centerIn: parent
                                        text: (root.daemon && root.daemon.pullInProgress) ? "Pulling..." : "Run"
                                        color: "#f8fafc"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !(root.daemon && root.daemon.pullInProgress)
                                        onClicked: {
                                            if (root.daemon)
                                                root.daemon.runImage(root.runDialogImage, root.runDialogContainerName, root.runDialogHostPort, root.runDialogContainerPort);
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
