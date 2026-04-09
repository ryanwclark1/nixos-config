import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../shared"
import "../../../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    property string searchQuery: ""
    property string stateFilter: "all"
    property int maxRows: 24
    /// Mirrors SystemStatsMenu / bar surface statKey: "ramStatus" | "cpuStatus" | "" (combined or other hosts).
    property string statContext: ""
    property string sortField: "cpu"
    property bool sortDescending: true
    property bool compactMode: false
    property string displayMode: "flat"
    property int selectedPid: 0
    property Flickable viewportFlickable: null
    property Item selectedRowItem: null
    property var collapsedPids: ({})
    property int lastSelectedIndex: 0
    property int lastSelectedParentPid: 0
    property int _clockTick: 0
    property bool jumpHighlighted: false

    readonly property string trimmedSearch: String(searchQuery || "").trim().toLowerCase()
    readonly property bool compactTableLayout: root.compactMode || (root.width > 0 && root.width < 520)
    readonly property var processColumnMap: ({
        pid: { label: "PID", width: compactTableLayout ? 64 : 72 },
        user: { label: "USER", width: compactTableLayout ? 84 : 104 },
        name: { label: "PROCESS", fill: true },
        cpu: { label: "CPU%", width: compactTableLayout ? 60 : 74 },
        mem: { label: "MEM%", width: compactTableLayout ? 60 : 74 },
        elapsed: { label: "TIME", width: 92, visible: !compactTableLayout },
        state: { label: "STATE", width: 70, visible: !compactTableLayout }
    })
    readonly property var processColumns: buildProcessColumns()
    readonly property var visibleProcesses: computeVisibleProcesses()
    readonly property var selectedProcess: findProcessByPid(selectedPid)
    readonly property var detailData: ProcessService.detailPid === selectedPid ? ProcessService.processDetail : ({})
    readonly property string pendingAction: ProcessService.pendingActionForPid(selectedPid)
    readonly property bool keyboardFocused: tableFocus.activeFocus

    Layout.fillWidth: true
    Layout.preferredHeight: tableFocus.implicitHeight + root.pad * 2

    onStatContextChanged: applyContextDefaultSort()

    function applyContextDefaultSort() {
        var nextField;
        if (statContext === "ramStatus")
            nextField = "mem";
        else if (statContext === "cpuStatus")
            nextField = "cpu";
        else
            nextField = ProcessService.sortBy === "mem" ? "mem" : "cpu";
        sortField = nextField;
        sortDescending = nextField === "cpu" || nextField === "mem" || nextField === "pid";
    }

    function focusTable() {
        tableFocus.forceActiveFocus();
    }

    function clearTableFocus() {
        if (tableFocus.activeFocus)
            tableFocus.focus = false;
    }

    function pulseJumpHighlight() {
        jumpHighlighted = true;
        jumpHighlightTimer.restart();
    }

    function ensureSelectedVisible() {
        if (!viewportFlickable || !selectedRowItem)
            return;

        var mapped = selectedRowItem.mapToItem(viewportFlickable.contentItem, 0, 0);
        var top = mapped.y;
        var bottom = top + selectedRowItem.height;
        var viewportTop = viewportFlickable.contentY;
        var viewportBottom = viewportTop + viewportFlickable.height;
        var nextContentY = viewportTop;

        if (top < viewportTop)
            nextContentY = top;
        else if (bottom > viewportBottom)
            nextContentY = bottom - viewportFlickable.height;

        var maxContentY = Math.max(0, viewportFlickable.contentHeight - viewportFlickable.height);
        viewportFlickable.contentY = Math.max(0, Math.min(maxContentY, nextContentY));
    }

    function matchesQuery(process) {
        if (trimmedSearch === "")
            return true;

        var haystack = [
            String(process.pid || ""),
            String(process.user || ""),
            String(process.name || ""),
            String(process.command || "")
        ].join(" ").toLowerCase();
        return haystack.indexOf(trimmedSearch) !== -1;
    }

    function matchesState(process) {
        if (stateFilter === "all")
            return true;
        if (stateFilter === "running")
            return String(process.state || "").indexOf("T") === -1;
        if (stateFilter === "stopped")
            return String(process.state || "").indexOf("T") !== -1;
        return Number(process.cpu || 0) >= 10 || Number(process.mem || 0) >= 5;
    }

    function compareProcesses(a, b) {
        var left;
        var right;
        if (sortField === "pid") {
            left = Number(a.pid || 0);
            right = Number(b.pid || 0);
        } else if (sortField === "user" || sortField === "name" || sortField === "elapsed" || sortField === "state") {
            left = String(a[sortField] || "");
            right = String(b[sortField] || "");
        } else {
            left = Number(a[sortField] || 0);
            right = Number(b[sortField] || 0);
        }

        if (left === right)
            return 0;
        if (left < right)
            return sortDescending ? 1 : -1;
        return sortDescending ? -1 : 1;
    }

    function isCollapsed(pid) {
        return !!collapsedPids[String(parseInt(pid, 10) || 0)];
    }

    function setCollapsed(pid, collapsed) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return;
        var next = Object.assign({}, collapsedPids || {});
        if (collapsed)
            next[String(safePid)] = true;
        else
            delete next[String(safePid)];
        collapsedPids = next;
    }

    function toggleCollapsed(pid) {
        setCollapsed(pid, !isCollapsed(pid));
    }

    function clearCollapsed() {
        collapsedPids = ({});
    }

    function computeVisibleProcesses() {
        var source = (ProcessService.processes || []).slice();
        var filtered = [];
        for (var i = 0; i < source.length; ++i) {
            var process = source[i];
            if (!matchesQuery(process) || !matchesState(process))
                continue;
            filtered.push(process);
        }

        if (displayMode !== "tree") {
            filtered.sort(compareProcesses);
            return filtered.slice(0, maxRows);
        }

        var byParent = {};
        var byPid = {};
        for (var j = 0; j < filtered.length; ++j) {
            var entry = filtered[j];
            var pidKey = String(entry.pid || 0);
            var parentKey = String(entry.parentPid || 0);
            byPid[pidKey] = entry;
            if (!byParent[parentKey])
                byParent[parentKey] = [];
            byParent[parentKey].push(entry);
        }

        for (var parentId in byParent)
            byParent[parentId].sort(compareProcesses);

        var descendantCounts = {};

        function countDescendants(pid) {
            var pidKey = String(pid || 0);
            if (descendantCounts[pidKey] !== undefined)
                return descendantCounts[pidKey];

            var total = 0;
            var children = byParent[pidKey] || [];
            for (var childIndex = 0; childIndex < children.length; ++childIndex) {
                var childPid = children[childIndex].pid || 0;
                total += 1 + countDescendants(childPid);
            }
            descendantCounts[pidKey] = total;
            return total;
        }

        var ordered = [];
        var visited = {};

        function walk(parentPid, depth) {
            var children = byParent[String(parentPid)] || [];
            for (var childIndex = 0; childIndex < children.length; ++childIndex) {
                var child = children[childIndex];
                var childPid = String(child.pid || 0);
                if (visited[childPid])
                    continue;
                visited[childPid] = true;
                var copy = Object.assign({}, child);
                copy._depth = depth;
                copy._hasChildren = (byParent[childPid] || []).length > 0;
                copy._collapsed = root.isCollapsed(child.pid);
                copy._descendantCount = countDescendants(child.pid);
                ordered.push(copy);
                if (copy._collapsed)
                    continue;
                walk(child.pid || 0, depth + 1);
            }
        }

        var roots = [];
        for (var k = 0; k < filtered.length; ++k) {
            var candidate = filtered[k];
            if (!byPid[String(candidate.parentPid || 0)])
                roots.push(candidate);
        }
        roots.sort(compareProcesses);
        for (var rootIndex = 0; rootIndex < roots.length; ++rootIndex) {
            var rootProcess = roots[rootIndex];
            var rootPid = String(rootProcess.pid || 0);
            if (visited[rootPid])
                continue;
            visited[rootPid] = true;
            var rootCopy = Object.assign({}, rootProcess);
            rootCopy._depth = 0;
            rootCopy._hasChildren = (byParent[rootPid] || []).length > 0;
            rootCopy._collapsed = root.isCollapsed(rootProcess.pid);
            rootCopy._descendantCount = countDescendants(rootProcess.pid);
            ordered.push(rootCopy);
            if (rootCopy._collapsed)
                continue;
            walk(rootProcess.pid || 0, 1);
        }

        for (var m = 0; m < filtered.length; ++m) {
            var dangling = filtered[m];
            var danglingPid = String(dangling.pid || 0);
            if (visited[danglingPid])
                continue;
            visited[danglingPid] = true;
            var danglingCopy = Object.assign({}, dangling);
            danglingCopy._depth = 0;
            danglingCopy._hasChildren = (byParent[danglingPid] || []).length > 0;
            danglingCopy._collapsed = root.isCollapsed(dangling.pid);
            danglingCopy._descendantCount = countDescendants(dangling.pid);
            ordered.push(danglingCopy);
            if (danglingCopy._collapsed)
                continue;
            walk(dangling.pid || 0, 1);
        }

        return ordered.slice(0, maxRows);
    }

    function findProcessByPid(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return null;
        for (var i = 0; i < visibleProcesses.length; ++i) {
            if ((visibleProcesses[i].pid || 0) === safePid)
                return visibleProcesses[i];
        }
        return null;
    }

    function setSort(field) {
        if (sortField === field)
            sortDescending = !sortDescending;
        else {
            sortField = field;
            sortDescending = field === "cpu" || field === "mem" || field === "pid";
        }
    }

    function selectProcess(pid) {
        var safePid = parseInt(pid, 10) || 0;
        selectedPid = safePid > 0 ? safePid : 0;
    }

    function moveSelection(delta) {
        if (visibleProcesses.length === 0)
            return;

        var nextIndex = 0;
        for (var i = 0; i < visibleProcesses.length; ++i) {
            if ((visibleProcesses[i].pid || 0) === selectedPid) {
                nextIndex = i;
                break;
            }
        }
        nextIndex = Math.max(0, Math.min(visibleProcesses.length - 1, nextIndex + delta));
        selectedPid = visibleProcesses[nextIndex].pid || 0;
    }

    function moveTreeHorizontally(delta) {
        if (displayMode !== "tree" || !selectedProcess)
            return false;

        var hasChildren = !!selectedProcess._hasChildren;
        if (delta > 0) {
            if (hasChildren && selectedProcess._collapsed) {
                setCollapsed(selectedPid, false);
                return true;
            }
            return false;
        }

        if (hasChildren && !selectedProcess._collapsed) {
            setCollapsed(selectedPid, true);
            return true;
        }

        var parentPid = parseInt(selectedProcess.parentPid, 10) || 0;
        if (parentPid > 0 && findProcessByPid(parentPid)) {
            selectedPid = parentPid;
            return true;
        }
        return false;
    }

    function syncSelection() {
        if (visibleProcesses.length === 0) {
            selectedPid = 0;
            return;
        }
        if (findProcessByPid(selectedPid))
            return;

        if (lastSelectedParentPid > 0 && findProcessByPid(lastSelectedParentPid)) {
            selectedPid = lastSelectedParentPid;
            return;
        }

        var fallbackIndex = Math.max(0, Math.min(visibleProcesses.length - 1, lastSelectedIndex));
        selectedPid = visibleProcesses[fallbackIndex].pid || visibleProcesses[0].pid || 0;
    }

    function headerLabel(label, field) {
        return label;
    }

    function buildProcessColumns() {
        var order = ["pid", "user", "name", "cpu", "mem", "elapsed", "state"];
        var columns = [];
        for (var i = 0; i < order.length; ++i) {
            var key = order[i];
            var definition = processColumnMap[key];
            if (!definition || definition.visible === false)
                continue;
            var column = {
                key: key,
                label: definition.label || "",
                fill: !!definition.fill
            };
            if (definition.width)
                column.width = definition.width;
            columns.push(column);
        }
        return columns;
    }

    function columnWidth(key) {
        var definition = processColumnMap[key];
        return definition && definition.width ? definition.width : 0;
    }

    function columnVisible(key) {
        var definition = processColumnMap[key];
        return !!definition && definition.visible !== false;
    }


    onVisibleProcessesChanged: syncSelection()
    onSelectedPidChanged: {
        for (var i = 0; i < visibleProcesses.length; ++i) {
            if ((visibleProcesses[i].pid || 0) === selectedPid) {
                lastSelectedIndex = i;
                lastSelectedParentPid = parseInt(visibleProcesses[i].parentPid, 10) || 0;
                break;
            }
        }
        Qt.callLater(ensureSelectedVisible);
        ProcessService.setDetailPid(selectedPid);
    }
    Component.onCompleted: {
        applyContextDefaultSort();
        syncSelection();
        ProcessService.setDetailPid(selectedPid);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        onTriggered: root._clockTick = root._clockTick + 1
    }

    Timer {
        id: jumpHighlightTimer
        interval: 800
        repeat: false
        onTriggered: root.jumpHighlighted = false
    }

    FocusScope {
        id: tableFocus
        Layout.fillWidth: true
        activeFocusOnTab: true
        implicitHeight: processColumn.implicitHeight

        Keys.onUpPressed: event => {
            root.moveSelection(-1);
            event.accepted = true;
        }
        Keys.onDownPressed: event => {
            root.moveSelection(1);
            event.accepted = true;
        }
        Keys.onLeftPressed: event => {
            event.accepted = root.moveTreeHorizontally(-1);
        }
        Keys.onRightPressed: event => {
            event.accepted = root.moveTreeHorizontally(1);
        }
        Keys.onPressed: event => {
            if (!root.selectedProcess)
                return;

            if (event.key === Qt.Key_J) {
                root.moveSelection(1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_K) {
                root.moveSelection(-1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_H) {
                event.accepted = root.moveTreeHorizontally(-1);
                return;
            }
            if (event.key === Qt.Key_L) {
                event.accepted = root.moveTreeHorizontally(1);
                return;
            }
            if (event.key === Qt.Key_R) {
                ProcessService.refresh();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal || event.key === Qt.Key_BracketRight) {
                ProcessService.reniceProcess(root.selectedPid, Number(root.selectedProcess.nice || 0) + 1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Minus || event.key === Qt.Key_Underscore || event.key === Qt.Key_BracketLeft) {
                ProcessService.reniceProcess(root.selectedPid, Number(root.selectedProcess.nice || 0) - 1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_X) {
                ProcessService.terminateProcess(root.selectedPid);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Delete) {
                ProcessService.killProcess(root.selectedPid);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Space) {
                ProcessService.togglePause(root.selectedPid);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_C) {
                ProcessService.copyCommand(root.selectedPid);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Y) {
                ProcessService.copyPid(root.selectedPid);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_D) {
                ProcessService.openProcessDetailsInTerminal(root.selectedPid);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_I || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                ProcessService.openProcessInTerminal(root.selectedPid);
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: processColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Text {
                    text: "PROCESS TABLE"
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Bold
                    font.letterSpacing: Appearance.letterSpacingWide
                }

                Item {
                    Layout.fillWidth: true
                }

                SharedWidgets.Chip {
                    icon: IconHelpers.processFocusIcon(keyboardFocused)
                    iconColor: keyboardFocused ? Colors.primary : Colors.textSecondary
                    text: keyboardFocused
                        ? (root.compactTableLayout ? "Keys active" : "Arrows/J/K active")
                        : (String(visibleProcesses.length) + " rows")
                    textColor: keyboardFocused ? Colors.primary : Colors.textSecondary
                }

                SharedWidgets.IconButton {
                    icon: "arrow-clockwise.svg"
                    size: 28
                    iconSize: Appearance.fontSizeSmall
                    iconColor: Colors.textSecondary
                    tooltipText: "Refresh"
                    onClicked: ProcessService.refresh()
                }
            }

            SharedWidgets.SearchBar {
                placeholder: root.compactTableLayout
                    ? "Search PID, user, or command..."
                    : "Search PID, user, name, or command..."
                onTextChanged: root.searchQuery = text
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Appearance.spacingS

                SharedWidgets.FilterChip {
                    label: "All"
                    selected: root.stateFilter === "all"
                    onClicked: root.stateFilter = "all"
                }

                SharedWidgets.FilterChip {
                    label: "Running"
                    selected: root.stateFilter === "running"
                    onClicked: root.stateFilter = "running"
                }

                SharedWidgets.FilterChip {
                    label: "Stopped"
                    selected: root.stateFilter === "stopped"
                    onClicked: root.stateFilter = "stopped"
                }

                SharedWidgets.FilterChip {
                    label: "High Load"
                    selected: root.stateFilter === "high"
                    onClicked: root.stateFilter = "high"
                }

                SharedWidgets.FilterChip {
                    label: "Flat"
                    selected: root.displayMode === "flat"
                    onClicked: root.displayMode = "flat"
                }

                SharedWidgets.FilterChip {
                    label: "Tree"
                    selected: root.displayMode === "tree"
                    onClicked: root.displayMode = "tree"
                }

                SharedWidgets.FilterChip {
                    visible: root.displayMode === "tree"
                    label: "Expand All"
                    enabled: Object.keys(root.collapsedPids || {}).length > 0
                    selected: false
                    onClicked: root.clearCollapsed()
                }

                SharedWidgets.FilterChip {
                    visible: root.displayMode === "tree"
                    label: "Collapse Sel"
                    enabled: !!root.selectedProcess && !!root.selectedProcess._hasChildren && !root.selectedProcess._collapsed
                    selected: false
                    onClicked: root.setCollapsed(root.selectedPid, true)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.radiusSmall
                color: Colors.cardSurface
                border.color: root.jumpHighlighted ? Colors.primary : (keyboardFocused ? Colors.primary : Colors.border)
                border.width: 1
                implicitHeight: tableColumn.implicitHeight + Appearance.spacingS * 2
                Behavior on border.color {
                    enabled: !Colors.isTransitioning
                    CAnim {}
                }

                ColumnLayout {
                    id: tableColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS
                    spacing: Appearance.spacingS

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Appearance.radiusSmall
                        color: Colors.withAlpha(Colors.highlight, 0.35)
                        implicitHeight: headerRow.implicitHeight + Appearance.spacingXS * 2

                        RowLayout {
                            id: headerRow
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingXS
                            spacing: Appearance.spacingS

                            Repeater {
                                model: root.processColumns

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.preferredWidth: modelData.width || 120
                                    Layout.fillWidth: !!modelData.fill
                                    Layout.alignment: Qt.AlignVCenter
                                    color: "transparent"
                                    implicitHeight: headerContent.implicitHeight + 8

                                    RowLayout {
                                        id: headerContent
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Appearance.spacingXXS

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.headerLabel(modelData.label, modelData.key)
                                            color: root.sortField === modelData.key ? Colors.primary : Colors.textSecondary
                                            font.pixelSize: Appearance.fontSizeXS
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                            horizontalAlignment: modelData.key === "name" ? Text.AlignLeft : Text.AlignRight
                                        }

                                        SharedWidgets.SvgIcon {
                                            visible: root.sortField === modelData.key
                                            source: IconHelpers.sortIndicatorIcon(!root.sortDescending)
                                            color: Colors.primary
                                            size: Appearance.fontSizeXS
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setSort(modelData.key)
                                    }
                                }
                            }
                        }
                    }

                    SharedWidgets.EmptyState {
                        Layout.fillWidth: true
                        visible: !ProcessService.busy && root.visibleProcesses.length === 0
                        icon: "search-visual.svg"
                        message: root.trimmedSearch === "" ? "No processes matched the current filter." : "No processes matched the current search."
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingXXS
                        visible: root.visibleProcesses.length > 0

                        Repeater {
                            model: root.visibleProcesses

                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool selected: (modelData.pid || 0) === root.selectedPid
                                Layout.fillWidth: true
                                radius: Appearance.radiusSmall
                                color: selected ? Colors.highlight : "transparent"
                                border.color: selected ? Colors.primary : "transparent"
                                border.width: 1
                                implicitHeight: rowLayout.implicitHeight + Appearance.spacingXS * 2

                                RowLayout {
                                    id: rowLayout
                                    anchors.fill: parent
                                    anchors.margins: Appearance.spacingXS
                                    spacing: Appearance.spacingS

                                    Text {
                                        Layout.preferredWidth: root.columnWidth("pid")
                                        text: String(modelData.pid || 0)
                                        color: Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.family: Appearance.fontMono
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        Layout.preferredWidth: root.columnWidth("user")
                                        text: String(modelData.user || "")
                                        color: Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeXS
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Appearance.spacingXS

                                        Item {
                                            Layout.preferredWidth: Math.min(root.compactTableLayout ? 48 : 84, Number(modelData._depth || 0) * (root.compactTableLayout ? 8 : 12))
                                            Layout.fillHeight: true
                                        }

                                        SharedWidgets.IconButton {
                                            visible: root.displayMode === "tree"
                                            enabled: !!modelData._hasChildren
                                            icon: IconHelpers.treeDisclosureIcon(modelData._collapsed, modelData._hasChildren)
                                            size: 18
                                            iconSize: Appearance.fontSizeXS
                                            iconColor: selected ? Colors.primary : Colors.textDisabled
                                            tooltipText: modelData._hasChildren ? (modelData._collapsed ? "Expand" : "Collapse") : "No children"
                                            onClicked: {
                                                root.selectProcess(modelData.pid);
                                                if (modelData._hasChildren)
                                                    root.toggleCollapsed(modelData.pid);
                                                root.focusTable();
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: String(modelData.name || "process")
                                            color: Colors.text
                                            font.pixelSize: Appearance.fontSizeXS
                                            font.weight: selected ? Font.DemiBold : Font.Medium
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: root.displayMode === "tree" && !!modelData._hasChildren
                                            text: modelData._collapsed
                                                ? ("+" + String(modelData._descendantCount || 0))
                                                : String(modelData._descendantCount || 0)
                                            color: selected ? Colors.primary : Colors.textDisabled
                                            font.pixelSize: Appearance.fontSizeXS
                                            font.family: Appearance.fontMono
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: root.columnWidth("cpu")
                                        text: Number(modelData.cpu || 0).toFixed(1)
                                        color: Number(modelData.cpu || 0) >= 20 ? Colors.primary : Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.family: Appearance.fontMono
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        Layout.preferredWidth: root.columnWidth("mem")
                                        text: Number(modelData.mem || 0).toFixed(1)
                                        color: Number(modelData.mem || 0) >= 10 ? Colors.accent : Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.family: Appearance.fontMono
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        visible: root.columnVisible("elapsed")
                                        Layout.preferredWidth: root.columnWidth("elapsed")
                                        text: String(modelData.elapsed || "--:--")
                                        color: Colors.textSecondary
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.family: Appearance.fontMono
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        visible: root.columnVisible("state")
                                        Layout.preferredWidth: root.columnWidth("state")
                                        text: String(modelData.state || "")
                                        color: String(modelData.state || "").indexOf("T") !== -1 ? Colors.warning : Colors.secondary
                                        font.pixelSize: Appearance.fontSizeXS
                                        font.family: Appearance.fontMono
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectProcess(modelData.pid);
                                        root.focusTable();
                                    }
                                }

                                onSelectedChanged: {
                                    if (selected)
                                        root.selectedRowItem = this;
                                    else if (root.selectedRowItem === this)
                                        root.selectedRowItem = null;
                                }
                                Component.onCompleted: {
                                    if (selected)
                                        root.selectedRowItem = this;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Colors.withAlpha(Colors.primary, 0.1)
                    border.color: Colors.withAlpha(Colors.primary, 0.35)
                    border.width: 1
                    opacity: root.jumpHighlighted ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.durationSlow
                        }
                    }
                }
            }

            ProcessDetailPanel {
                selectedProcess: root.selectedProcess
                detailData: root.detailData
                selectedPid: root.selectedPid
                pendingAction: root.pendingAction
                clockTick: root._clockTick
            }
        }
    }
}
