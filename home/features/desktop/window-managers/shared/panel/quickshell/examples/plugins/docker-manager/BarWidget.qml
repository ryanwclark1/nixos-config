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

    // F6: Search/filter (debounced)
    property string searchQuery: ""
    property string _pendingSearch: ""

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
        if (!daemon) return "?";
        return String(daemon.runningContainers || 0);
    }

    function runtimeBadgeColor() {
        if (!daemon) return "#6b7280";
        if (!daemon.runtimeAvailable) return "#7f1d1d";
        if (daemon.runningContainers > 0) return "#0f766e";
        return "#334155";
    }

    function runtimeAccentColor() {
        if (!daemon) return "#d1d5db";
        if (!daemon.runtimeAvailable) return "#fca5a5";
        if (daemon.runningContainers > 0) return "#99f6e4";
        return "#cbd5e1";
    }

    function ensureVisible(itemY, itemHeight) {
        if (!autoScrollOnExpand) return;
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

    function filteredList(sourceList, query) {
        if (!sourceList || !Array.isArray(sourceList)) return [];
        var q = String(query || "").trim();
        if (q === "") return sourceList;
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
        for (var k in map) if (map[k]) count++;
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
            for (i = 0; i < keys.length; i++) daemon.executeContainerAction(keys[i], action);
        } else if (currentTab === "images") {
            map = selectedImages;
            keys = Object.keys(map).filter(function(k) { return map[k]; });
            for (i = 0; i < keys.length; i++) daemon.removeImage(keys[i]);
        } else if (currentTab === "volumes") {
            map = selectedVolumes;
            keys = Object.keys(map).filter(function(k) { return map[k]; });
            for (i = 0; i < keys.length; i++) daemon.removeVolume(keys[i]);
        } else if (currentTab === "networks") {
            map = selectedNetworks;
            keys = Object.keys(map).filter(function(k) { return map[k]; });
            for (i = 0; i < keys.length; i++) daemon.removeNetwork(keys[i]);
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
        _pendingSearch = "";
        searchQuery = "";
        searchDebounceTimer.stop();
        focusedCardIndex = -1;
        if (selectionMode) _clearSelection();
    }

    onPopupOpenChanged: {
        if (daemon) daemon.statsPollingActive = popupOpen;
    }

    property var tabModel: {
        var tabs = [
            { key: "containers", label: "CTR", icon: "\uf489" },
            { key: "compose", label: "CMP", icon: "\uf387" }
        ];
        if (daemon && daemon.showImages) tabs.push({ key: "images", label: "IMG", icon: "\ueb47" });
        if (daemon && daemon.showVolumes) tabs.push({ key: "volumes", label: "VOL", icon: "\uf7c2" });
        if (daemon && daemon.showNetworks) tabs.push({ key: "networks", label: "NET", icon: "\uf6ff" });
        return tabs;
    }

    Component.onCompleted: loadPrefs()

    Connections {
        target: root.pluginService ? root.pluginService : null
        function onPluginRuntimeUpdated() { root.loadPrefs(); }
    }

    Timer { id: pruneConfirmTimer; interval: 2000; repeat: false; onTriggered: root.pruneConfirmPending = false }
    Timer { id: searchDebounceTimer; interval: 150; repeat: false; onTriggered: root.searchQuery = root._pendingSearch }

    Rectangle {
        id: triggerRect
        radius: 13; height: 28
        implicitWidth: badgeRow.implicitWidth + 22
        color: root.runtimeBadgeColor()
        border.width: 1; border.color: Qt.lighter(root.runtimeAccentColor(), 1.15)

        Row {
            id: badgeRow; anchors.centerIn: parent; spacing: 6
            Text { text: root.daemon && root.daemon.runtimeAvailable ? (String(root.daemon.runtimeName || "Docker").charAt(0)) : "!"; color: root.runtimeAccentColor(); font.pixelSize: 13; font.bold: true }
            Text { text: root.runtimeCountText(); color: "#f8fafc"; font.pixelSize: 12; font.bold: true }
            Text { visible: root.daemon && root.daemon.busy; text: "..."; color: "#e2e8f0"; font.pixelSize: 11 }
        }
        MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: root.popupOpen = !root.popupOpen }
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
            radius: 16; color: "#0f172a"; border.width: 1; border.color: "#334155"

            FocusScope {
                id: popupFocus
                anchors.fill: parent; focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (root.searchQuery !== "" || root._pendingSearch !== "") { root._pendingSearch = ""; root.searchQuery = ""; searchDebounceTimer.stop(); event.accepted = true; }
                        else { root.popupOpen = false; event.accepted = true; }
                    } else if (event.key === Qt.Key_Tab && !event.modifiers) { root._nextTab(); event.accepted = true; }
                    else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) { root._prevTab(); event.accepted = true; }
                    else if (event.key === Qt.Key_Backtab) { root._prevTab(); event.accepted = true; }
                    else if (event.key === Qt.Key_Down) { var maxLen = root._currentListLength(); if (root.focusedCardIndex < maxLen - 1) root.focusedCardIndex++; event.accepted = true; }
                    else if (event.key === Qt.Key_Up) { if (root.focusedCardIndex > 0) root.focusedCardIndex--; else root.focusedCardIndex = -1; event.accepted = true; }
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root._activateFocusedCard(); event.accepted = true; }
                    else if (event.key === Qt.Key_Slash) { searchInput.forceActiveFocus(); event.accepted = true; }
                }

                Column {
                    id: contentColumn
                    anchors.fill: parent; anchors.margins: 14; spacing: 12

                    // Header
                    Row {
                        width: parent.width; spacing: 8
                        Column {
                            width: Math.max(160, parent.width - actionButtons.width - 8); spacing: 4
                            Text { text: "Docker Manager"; color: "#f8fafc"; font.pixelSize: 16; font.bold: true }
                            Text { width: parent.width; wrapMode: Text.WordWrap; text: root.daemon ? root.daemon.statusMessage : "Waiting for plugin daemon."; color: "#94a3b8"; font.pixelSize: 11 }
                        }
                        Row {
                            id: actionButtons; spacing: 6
                            Rectangle {
                                width: 34; height: 30; radius: 10
                                color: root.selectionMode ? "#1d4ed8" : "#1e293b"; border.width: 1; border.color: root.selectionMode ? "#93c5fd" : "#475569"
                                Text { anchors.centerIn: parent; text: "\u2611"; color: root.selectionMode ? "#93c5fd" : "#e2e8f0"; font.pixelSize: 14; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: { root.selectionMode = !root.selectionMode; if (!root.selectionMode) root._clearSelection(); } }
                            }
                            Rectangle {
                                width: 34; height: 30; radius: 10
                                color: root.pruneConfirmPending ? "#7f1d1d" : "#1e293b"; border.width: 1; border.color: root.pruneConfirmPending ? "#f87171" : "#475569"
                                Text { anchors.centerIn: parent; text: root.pruneConfirmPending ? "!" : "P"; color: root.pruneConfirmPending ? "#fca5a5" : "#e2e8f0"; font.pixelSize: 12; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: { if (!root.daemon) return; if (root.daemon.confirmPrune && !root.pruneConfirmPending) { root.pruneConfirmPending = true; pruneConfirmTimer.restart(); } else { root.pruneConfirmPending = false; root.daemon.systemPrune(); } } }
                            }
                            Rectangle {
                                width: 34; height: 30; radius: 10; color: "#1e293b"; border.width: 1; border.color: "#475569"
                                Text { anchors.centerIn: parent; text: "R"; color: "#e2e8f0"; font.pixelSize: 12; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: { if (root.daemon && root.daemon.scheduleRefresh) root.daemon.scheduleRefresh(0); } }
                            }
                            Rectangle {
                                width: 34; height: 30; radius: 10; color: "#1e293b"; border.width: 1; border.color: "#475569"
                                Text { anchors.centerIn: parent; text: "X"; color: "#e2e8f0"; font.pixelSize: 12; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: root.popupOpen = false }
                            }
                        }
                    }

                    // Notice banner
                    Rectangle {
                        visible: root.daemon && root.daemon.noticeMessage !== ""
                        width: parent.width; height: noticeText.implicitHeight + 16; radius: 12
                        color: root.daemon && root.daemon.noticeKind === "error" ? "#3f1d24" : (root.daemon && root.daemon.noticeKind === "warn" ? "#3b2f16" : "#12334b")
                        border.width: 1; border.color: root.daemon && root.daemon.noticeKind === "error" ? "#f87171" : (root.daemon && root.daemon.noticeKind === "warn" ? "#fbbf24" : "#38bdf8")
                        Text { id: noticeText; anchors.fill: parent; anchors.margins: 8; wrapMode: Text.WordWrap; text: root.daemon ? root.daemon.noticeMessage : ""; color: "#f8fafc"; font.pixelSize: 11 }
                    }

                    // Tab strip
                    Row {
                        width: parent.width; spacing: 4
                        Repeater {
                            model: root.tabModel
                            delegate: Rectangle {
                                id: tabButton; required property var modelData; required property int index
                                readonly property bool isActive: root.currentTab === modelData.key
                                readonly property bool isDisabled: modelData.key === "compose" && (!root.daemon || !root.daemon.composeProjects || root.daemon.composeProjects.length === 0)
                                width: Math.floor((parent.width - (root.tabModel.length - 1) * 4) / root.tabModel.length); height: 30; radius: 10
                                color: isActive ? "#1d4ed8" : "#1e293b"; opacity: isDisabled ? 0.45 : 1; border.width: 1; border.color: isActive ? "#93c5fd" : "#475569"
                                Row {
                                    anchors.centerIn: parent; spacing: 4
                                    Text { text: tabButton.modelData.label; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                                    Text { text: root.tabCountText(tabButton.modelData.key); color: "#94a3b8"; font.pixelSize: 9; visible: text !== "" }
                                }
                                MouseArea { anchors.fill: parent; enabled: !tabButton.isDisabled; onClicked: root.currentTab = tabButton.modelData.key }
                            }
                        }
                    }

                    // Search bar
                    Rectangle {
                        visible: root.daemon && root.daemon.runtimeAvailable
                        width: parent.width; height: 30; radius: 10; color: "#0f172a"
                        border.width: searchInput.activeFocus ? 2 : 1; border.color: searchInput.activeFocus ? "#93c5fd" : "#334155"
                        Row {
                            anchors.fill: parent; anchors.margins: 6; spacing: 6
                            Text { text: "/"; color: "#64748b"; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            TextInput {
                                id: searchInput; width: parent.width - 20; anchors.verticalCenter: parent.verticalCenter
                                color: "#f8fafc"; font.pixelSize: 11; text: root._pendingSearch
                                onTextChanged: { root._pendingSearch = text; searchDebounceTimer.restart(); }
                                Keys.onEscapePressed: { root._pendingSearch = ""; root.searchQuery = ""; text = ""; searchDebounceTimer.stop(); popupFocus.forceActiveFocus(); }
                            }
                        }
                        Text { visible: root._pendingSearch === ""; text: "Search..."; color: "#475569"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 26 }
                    }

                    // Ports toggle (containers tab only)
                    Rectangle {
                        visible: root.currentTab === "containers"
                        width: parent.width; height: 30; radius: 10
                        color: root.showPorts ? "#1e3a2a" : "#1e293b"; border.width: 1; border.color: root.showPorts ? "#6ee7b7" : "#475569"
                        Text { anchors.centerIn: parent; text: root.showPorts ? "Ports On" : "Ports Off"; color: "#f8fafc"; font.pixelSize: 11; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: { root.showPorts = !root.showPorts; root.savePref("showPorts", root.showPorts); } }
                    }

                    // Main scrollable content
                    Flickable {
                        id: scroller
                        width: parent.width; height: 390; clip: true
                        contentHeight: listColumn.implicitHeight

                        Column {
                            id: listColumn
                            width: scroller.width; spacing: 8

                            // Unavailable state
                            Rectangle {
                                visible: !root.daemon || !root.daemon.runtimeAvailable
                                width: parent.width; radius: 14; color: "#1f2937"; border.width: 1; border.color: "#7f1d1d"
                                implicitHeight: unavailableText.implicitHeight + 20
                                Text { id: unavailableText; anchors.fill: parent; anchors.margins: 10; wrapMode: Text.WordWrap; text: root.daemon ? root.daemon.statusMessage : "Docker Manager daemon is not ready."; color: "#fecaca"; font.pixelSize: 12 }
                            }

                            // Empty states
                            Rectangle {
                                visible: root.currentTab === "containers" && root.daemon && root.daemon.runtimeAvailable && root._filteredContainers.length === 0
                                width: parent.width; radius: 14; color: "#111827"; border.width: 1; border.color: "#334155"; implicitHeight: emptyText.implicitHeight + 20
                                Text { id: emptyText; anchors.fill: parent; anchors.margins: 10; wrapMode: Text.WordWrap; text: root.searchQuery !== "" ? "No containers match the filter." : "No containers were found."; color: "#cbd5e1"; font.pixelSize: 12 }
                            }
                            Rectangle {
                                visible: root.currentTab === "compose" && root.daemon && root.daemon.runtimeAvailable && root._filteredCompose.length === 0
                                width: parent.width; radius: 14; color: "#111827"; border.width: 1; border.color: "#334155"; implicitHeight: emptyComposeText.implicitHeight + 20
                                Text { id: emptyComposeText; anchors.fill: parent; anchors.margins: 10; wrapMode: Text.WordWrap; text: root.searchQuery !== "" ? "No compose projects match the filter." : "No compose-labelled projects were found for the current runtime."; color: "#cbd5e1"; font.pixelSize: 12 }
                            }

                            // ── CONTAINERS TAB ──
                            Repeater {
                                model: root._filteredContainers
                                delegate: ContainerCard {
                                    required property var modelData
                                    required property int index
                                    modelData: modelData
                                    index: index
                                    daemon: root.daemon
                                    selectionMode: root.selectionMode
                                    selectedMap: root.selectedContainers
                                    showPorts: root.showPorts
                                    isFocused: root.focusedCardIndex === index
                                    _expandedMap: root.expandedContainers
                                    width: listColumn.width
                                    onToggleExpanded: key => root.toggleContainer(key)
                                    onSelectionToggled: key => root._toggleSelection(key)
                                    onEnsureVisibleRequested: (itemY, itemHeight) => root.ensureVisible(itemY, itemHeight)
                                }
                            }

                            // ── COMPOSE TAB ──
                            Repeater {
                                model: root._filteredCompose
                                delegate: ComposeCard {
                                    required property var modelData
                                    required property int index
                                    modelData: modelData; index: index
                                    daemon: root.daemon
                                    isFocused: root.focusedCardIndex === index
                                    _expandedMap: root.expandedProjects
                                    width: listColumn.width
                                    onToggleExpanded: key => root.toggleProject(key)
                                    onEnsureVisibleRequested: (itemY, itemHeight) => root.ensureVisible(itemY, itemHeight)
                                }
                            }

                            // ── IMAGES TAB ──
                            Row {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "images"
                                width: parent.width; spacing: 6
                                Text { text: (root.daemon ? root.daemon.imageCount : 0) + " image" + ((root.daemon && root.daemon.imageCount !== 1) ? "s" : ""); color: "#94a3b8"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - pruneImagesBtn.width - 6 }
                                Rectangle {
                                    id: pruneImagesBtn; width: 120; height: 28; radius: 10; color: "#1e293b"; border.width: 1; border.color: "#475569"
                                    Text { anchors.centerIn: parent; text: "Prune Dangling"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                                    MouseArea { anchors.fill: parent; onClicked: { if (root.daemon) root.daemon.pruneImages(); } }
                                }
                            }
                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "images" && root._filteredImages.length === 0
                                width: parent.width; radius: 14; color: "#111827"; border.width: 1; border.color: "#334155"; implicitHeight: emptyImagesText.implicitHeight + 20
                                Text { id: emptyImagesText; anchors.fill: parent; anchors.margins: 10; wrapMode: Text.WordWrap; text: root.searchQuery !== "" ? "No images match the filter." : "No images found."; color: "#cbd5e1"; font.pixelSize: 12 }
                            }
                            Repeater {
                                model: root._filteredImages
                                delegate: ImageCard {
                                    required property var modelData
                                    required property int index
                                    modelData: modelData; index: index
                                    daemon: root.daemon; selectionMode: root.selectionMode
                                    selectedMap: root.selectedImages; isFocused: root.focusedCardIndex === index
                                    _expandedMap: root.expandedImages; width: listColumn.width
                                    onToggleExpanded: key => root.toggleImage(key)
                                    onSelectionToggled: key => root._toggleSelection(key)
                                    onEnsureVisibleRequested: (itemY, itemHeight) => root.ensureVisible(itemY, itemHeight)
                                    onRunRequested: imageName => root.openRunDialog(imageName)
                                }
                            }

                            // ── VOLUMES TAB ──
                            Row {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "volumes"
                                width: parent.width; spacing: 6
                                Text { text: (root.daemon ? root.daemon.volumeCount : 0) + " volume" + ((root.daemon && root.daemon.volumeCount !== 1) ? "s" : ""); color: "#94a3b8"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - pruneVolumesBtn.width - 6 }
                                Rectangle {
                                    id: pruneVolumesBtn; width: 130; height: 28; radius: 10; color: "#1e293b"; border.width: 1; border.color: "#475569"
                                    Text { anchors.centerIn: parent; text: "Remove Unused"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                                    MouseArea { anchors.fill: parent; onClicked: { if (root.daemon) root.daemon.pruneVolumes(); } }
                                }
                            }
                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "volumes" && root._filteredVolumes.length === 0
                                width: parent.width; radius: 14; color: "#111827"; border.width: 1; border.color: "#334155"; implicitHeight: emptyVolumesText.implicitHeight + 20
                                Text { id: emptyVolumesText; anchors.fill: parent; anchors.margins: 10; wrapMode: Text.WordWrap; text: root.searchQuery !== "" ? "No volumes match the filter." : "No volumes found."; color: "#cbd5e1"; font.pixelSize: 12 }
                            }
                            Repeater {
                                model: root._filteredVolumes
                                delegate: VolumeCard {
                                    required property var modelData
                                    required property int index
                                    modelData: modelData; index: index
                                    daemon: root.daemon; selectionMode: root.selectionMode
                                    selectedMap: root.selectedVolumes; isFocused: root.focusedCardIndex === index
                                    width: listColumn.width
                                    onSelectionToggled: key => root._toggleSelection(key)
                                }
                            }

                            // ── NETWORKS TAB ──
                            Row {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "networks"
                                width: parent.width; spacing: 6
                                Text { text: (root.daemon ? root.daemon.networkCount : 0) + " network" + ((root.daemon && root.daemon.networkCount !== 1) ? "s" : ""); color: "#94a3b8"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - pruneNetworksBtn.width - 6 }
                                Rectangle {
                                    id: pruneNetworksBtn; width: 130; height: 28; radius: 10; color: "#1e293b"; border.width: 1; border.color: "#475569"
                                    Text { anchors.centerIn: parent; text: "Remove Unused"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                                    MouseArea { anchors.fill: parent; onClicked: { if (root.daemon) root.daemon.pruneNetworks(); } }
                                }
                            }
                            Rectangle {
                                visible: root.daemon && root.daemon.runtimeAvailable && root.currentTab === "networks" && root._filteredNetworks.length === 0
                                width: parent.width; radius: 14; color: "#111827"; border.width: 1; border.color: "#334155"; implicitHeight: emptyNetworksText.implicitHeight + 20
                                Text { id: emptyNetworksText; anchors.fill: parent; anchors.margins: 10; wrapMode: Text.WordWrap; text: root.searchQuery !== "" ? "No networks match the filter." : "No networks found."; color: "#cbd5e1"; font.pixelSize: 12 }
                            }
                            Repeater {
                                model: root._filteredNetworks
                                delegate: NetworkCard {
                                    required property var modelData
                                    required property int index
                                    modelData: modelData; index: index
                                    daemon: root.daemon; selectionMode: root.selectionMode
                                    selectedMap: root.selectedNetworks; isFocused: root.focusedCardIndex === index
                                    width: listColumn.width
                                    onSelectionToggled: key => root._toggleSelection(key)
                                }
                            }
                        }
                    }

                    // Bulk action bar
                    BulkActionBar {
                        visible: root.selectionMode && root._selectedCount() > 0
                        width: parent.width
                        currentTab: root.currentTab
                        selectedCount: root._selectedCount()
                        onBulkActionRequested: action => root._executeBulkAction(action)
                    }

                    // Run image dialog
                    RunImageDialog {
                        visible: root.runDialogVisible
                        width: parent.width
                        daemon: root.daemon
                        imageName: root.runDialogVisible ? root.runDialogImage : ""
                        containerName: root.runDialogContainerName
                        hostPort: root.runDialogHostPort
                        containerPort: root.runDialogContainerPort
                        portStatus: root.runDialogPortStatus
                        onContainerNameChanged: root.runDialogContainerName = containerName
                        onHostPortChanged: root.runDialogHostPort = hostPort
                        onContainerPortChanged: root.runDialogContainerPort = containerPort
                        onPortStatusChanged: root.runDialogPortStatus = portStatus
                        onCloseRequested: root.runDialogVisible = false
                    }
                }
            }
        }
    }
}
