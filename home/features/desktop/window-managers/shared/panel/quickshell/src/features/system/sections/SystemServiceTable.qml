import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU

SharedWidgets.CardBase {
    id: root
    property bool _destroyed: false

    property string searchQuery: ""
    property string filterMode: "failed"
    property string scopeMode: "both"
    property int maxRows: 16
    property int selectedIndex: -1
    property string selectedScope: ""
    property string selectedUnitName: ""
    property Flickable viewportFlickable: null
    property Item selectedRowItem: null
    property int lastSelectedIndex: -1
    property int _clockTick: 0

    readonly property string trimmedSearch: String(searchQuery || "").trim().toLowerCase()
    readonly property var visibleUnits: computeVisibleUnits()
    readonly property var selectedUnit: {
        if (selectedScope !== "" && selectedUnitName !== "") {
            for (var i = 0; i < visibleUnits.length; ++i) {
                var candidate = visibleUnits[i];
                if (String(candidate.scope || "") === selectedScope && String(candidate.name || "") === selectedUnitName)
                    return candidate;
            }
        }
        return (selectedIndex >= 0 && selectedIndex < visibleUnits.length) ? visibleUnits[selectedIndex] : null;
    }
    readonly property var detailData: root.selectedUnit
        && ServiceUnitService.detailScope === root.selectedUnit.scope
        && ServiceUnitService.detailUnitName === root.selectedUnit.name
        ? ServiceUnitService.unitDetail
        : ({})
    readonly property string selectedPendingAction: selectedUnit ? ServiceUnitService.pendingActionForUnit(selectedUnit.scope, selectedUnit.name) : ""
    readonly property bool keyboardFocused: tableFocus.activeFocus

    Layout.fillWidth: true
    Layout.preferredHeight: tableFocus.implicitHeight + root.pad * 2

    function focusTable() {
        tableFocus.forceActiveFocus();
    }

    function clearTableFocus() {
        if (tableFocus.activeFocus)
            tableFocus.focus = false;
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

    function matchesQuery(unit) {
        if (trimmedSearch === "")
            return true;
        var haystack = [
            String(unit.scope || ""),
            String(unit.name || ""),
            String(unit.description || ""),
            String(unit.active || ""),
            String(unit.sub || "")
        ].join(" ").toLowerCase();
        return haystack.indexOf(trimmedSearch) !== -1;
    }

    function matchesFilter(unit) {
        if (filterMode === "all")
            return true;
        if (filterMode === "busy")
            return String(unit.active || "") === "activating" || String(unit.active || "") === "reloading";
        if (filterMode === "running")
            return String(unit.active || "") === "active";
        return String(unit.active || "") === "failed" || String(unit.sub || "").indexOf("failed") !== -1;
    }

    function running(unit) {
        return String(unit.active || "") === "active" && String(unit.sub || "").indexOf("running") !== -1;
    }

    function stateColor(unit) {
        var active = String(unit.active || "");
        if (active === "failed")
            return Colors.error;
        if (active === "active")
            return Colors.success;
        if (active === "activating" || active === "reloading")
            return Colors.warning;
        return Colors.textSecondary;
    }

    function detailStatusColor(status) {
        if (status === "ready")
            return Colors.success;
        if (status === "loading")
            return Colors.warning;
        if (status === "permission-limited")
            return Colors.warning;
        if (status === "error" || status === "missing")
            return Colors.error;
        return Colors.textDisabled;
    }

    function actionStatusColor(status) {
        if (status === "success")
            return Colors.success;
        if (status === "pending")
            return Colors.warning;
        if (status === "error")
            return Colors.error;
        return Colors.textDisabled;
    }

    function fallbackText(value) {
        return String(value || "").trim() === "" ? "Unavailable" : String(value);
    }

    function sourceUnitsForScope(scope) {
        if (scope === "system")
            return ServiceUnitService.systemUnits || [];
        return ServiceUnitService.userUnits || [];
    }

    function computeVisibleUnits() {
        var scopes = [];
        if (scopeMode === "user" || scopeMode === "both")
            scopes.push("user");
        if (scopeMode === "system" || scopeMode === "both")
            scopes.push("system");

        var result = [];
        for (var s = 0; s < scopes.length; ++s) {
            var scope = scopes[s];
            var units = sourceUnitsForScope(scope);
            for (var i = 0; i < units.length; ++i) {
                var unit = units[i];
                var merged = {
                    scope: scope,
                    name: unit.name,
                    description: unit.description,
                    active: unit.active,
                    sub: unit.sub,
                    load: unit.load
                };
                if (!matchesQuery(merged) || !matchesFilter(merged))
                    continue;
                result.push(merged);
            }
        }

        result.sort(function(a, b) {
            var aFailed = String(a.active || "") === "failed" ? 0 : 1;
            var bFailed = String(b.active || "") === "failed" ? 0 : 1;
            if (aFailed !== bFailed)
                return aFailed - bFailed;
            if (String(a.active || "") !== String(b.active || ""))
                return String(a.active || "").localeCompare(String(b.active || ""));
            return String(a.name || "").localeCompare(String(b.name || ""));
        });
        return result.slice(0, maxRows);
    }

    function selectIndex(index) {
        selectedIndex = (index >= 0 && index < visibleUnits.length) ? index : -1;
    }

    function moveSelection(delta) {
        if (visibleUnits.length === 0)
            return;
        var nextIndex = selectedIndex;
        if (nextIndex < 0)
            nextIndex = 0;
        nextIndex = Math.max(0, Math.min(visibleUnits.length - 1, nextIndex + delta));
        selectedIndex = nextIndex;
    }

    function syncSelection() {
        if (visibleUnits.length === 0) {
            selectedIndex = -1;
            selectedScope = "";
            selectedUnitName = "";
            return;
        }
        for (var i = 0; i < visibleUnits.length; ++i) {
            var candidate = visibleUnits[i];
            if (String(candidate.scope || "") === selectedScope && String(candidate.name || "") === selectedUnitName) {
                selectedIndex = i;
                return;
            }
        }
        if (selectedUnit)
            return;
        if (lastSelectedIndex >= 0 && lastSelectedIndex < visibleUnits.length) {
            selectedIndex = lastSelectedIndex;
            selectedScope = String(visibleUnits[lastSelectedIndex].scope || "");
            selectedUnitName = String(visibleUnits[lastSelectedIndex].name || "");
            return;
        }
        selectedIndex = 0;
        selectedScope = String(visibleUnits[0].scope || "");
        selectedUnitName = String(visibleUnits[0].name || "");
    }

    onVisibleUnitsChanged: syncSelection()
    onSelectedIndexChanged: {
        if (selectedIndex >= 0 && selectedIndex < visibleUnits.length) {
            lastSelectedIndex = selectedIndex;
            selectedScope = String(visibleUnits[selectedIndex].scope || "");
            selectedUnitName = String(visibleUnits[selectedIndex].name || "");
        } else {
            selectedScope = "";
            selectedUnitName = "";
        }
        Qt.callLater(function() { if (_destroyed) return; ensureSelectedVisible(); });
        if (root.selectedUnit)
            ServiceUnitService.setDetailUnit(root.selectedUnit.scope, root.selectedUnit.name);
        else
            ServiceUnitService.setDetailUnit("", "");
    }
    Component.onCompleted: {
        syncSelection();
        if (root.selectedUnit)
            ServiceUnitService.setDetailUnit(root.selectedUnit.scope, root.selectedUnit.name);
    }
    Component.onDestruction: _destroyed = true

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        onTriggered: root._clockTick = root._clockTick + 1
    }

    FocusScope {
        id: tableFocus
        Layout.fillWidth: true
        activeFocusOnTab: true
        implicitHeight: serviceColumn.implicitHeight

        Keys.onUpPressed: event => {
            root.moveSelection(-1);
            event.accepted = true;
        }
        Keys.onDownPressed: event => {
            root.moveSelection(1);
            event.accepted = true;
        }
        Keys.onPressed: event => {
            if (!root.selectedUnit)
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
            if (event.key === Qt.Key_R) {
                ServiceUnitService.restartUnit(root.selectedUnit.scope, root.selectedUnit.name);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_S) {
                if (root.running(root.selectedUnit))
                    ServiceUnitService.stopUnit(root.selectedUnit.scope, root.selectedUnit.name);
                else
                    ServiceUnitService.startUnit(root.selectedUnit.scope, root.selectedUnit.name);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_L || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                ServiceUnitService.openUnitLogsInTerminal(root.selectedUnit.scope, root.selectedUnit.name);
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: serviceColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Colors.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    text: "SERVICE TABLE"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                    font.letterSpacing: Colors.letterSpacingWide
                }

                Item {
                    Layout.fillWidth: true
                }

                SharedWidgets.Chip {
                    icon: keyboardFocused ? "󰌌" : "󰒓"
                    iconColor: keyboardFocused ? Colors.primary : Colors.textSecondary
                    text: keyboardFocused ? "Arrows/J/K active" : (String(visibleUnits.length) + " rows")
                    textColor: keyboardFocused ? Colors.primary : Colors.textSecondary
                }

                SharedWidgets.IconButton {
                    icon: "󰑐"
                    size: 28
                    iconSize: Colors.fontSizeSmall
                    iconColor: Colors.textSecondary
                    tooltipText: "Refresh"
                    onClicked: ServiceUnitService.refresh()
                }
            }

            SharedWidgets.SearchBar {
                placeholder: "Search service name or description..."
                onTextChanged: root.searchQuery = text
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SharedWidgets.FilterChip {
                    label: "Both"
                    selected: root.scopeMode === "both"
                    onClicked: root.scopeMode = "both"
                }

                SharedWidgets.FilterChip {
                    label: "User"
                    selected: root.scopeMode === "user"
                    onClicked: root.scopeMode = "user"
                }

                SharedWidgets.FilterChip {
                    label: "System"
                    selected: root.scopeMode === "system"
                    onClicked: root.scopeMode = "system"
                }

                Item {
                    Layout.fillWidth: true
                }

                SharedWidgets.FilterChip {
                    label: "Failed"
                    selected: root.filterMode === "failed"
                    onClicked: root.filterMode = "failed"
                }

                SharedWidgets.FilterChip {
                    label: "Busy"
                    selected: root.filterMode === "busy"
                    onClicked: root.filterMode = "busy"
                }

                SharedWidgets.FilterChip {
                    label: "Running"
                    selected: root.filterMode === "running"
                    onClicked: root.filterMode = "running"
                }

                SharedWidgets.FilterChip {
                    label: "All"
                    selected: root.filterMode === "all"
                    onClicked: root.filterMode = "all"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: keyboardFocused ? Colors.primary : Colors.border
                border.width: 1
                implicitHeight: tableColumn.implicitHeight + Colors.spacingS * 2

                ColumnLayout {
                    id: tableColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingS

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Colors.radiusSmall
                        color: Colors.withAlpha(Colors.highlight, 0.35)
                        implicitHeight: headerRow.implicitHeight + Colors.spacingXS * 2

                        RowLayout {
                            id: headerRow
                            anchors.fill: parent
                            anchors.margins: Colors.spacingXS
                            spacing: Colors.spacingS

                            Text {
                                Layout.preferredWidth: 70
                                text: "SCOPE"
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.preferredWidth: 92
                                text: "STATE"
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "UNIT"
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.preferredWidth: 120
                                text: "SUBSTATE"
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    SharedWidgets.EmptyState {
                        Layout.fillWidth: true
                        visible: root.visibleUnits.length === 0
                        icon: "󰜺"
                        message: root.trimmedSearch === "" ? "No matching services for the current filter." : "No services matched the current search."
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXXS
                        visible: root.visibleUnits.length > 0

                        Repeater {
                            model: root.visibleUnits

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool selected: index === root.selectedIndex
                                Layout.fillWidth: true
                                radius: Colors.radiusSmall
                                color: selected ? Colors.highlight : "transparent"
                                border.color: selected ? Colors.primary : "transparent"
                                border.width: 1
                                implicitHeight: rowLayout.implicitHeight + Colors.spacingXS * 2

                                RowLayout {
                                    id: rowLayout
                                    anchors.fill: parent
                                    anchors.margins: Colors.spacingXS
                                    spacing: Colors.spacingS

                                    Text {
                                        Layout.preferredWidth: 70
                                        text: String(modelData.scope || "").toUpperCase()
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        Layout.preferredWidth: 92
                                        text: String(modelData.active || "").toUpperCase()
                                        color: root.stateColor(modelData)
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.Bold
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: String(modelData.name || "service")
                                        color: Colors.text
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: selected ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.preferredWidth: 120
                                        text: String(modelData.sub || "")
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        font.family: Colors.fontMono
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideLeft
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectIndex(index);
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
            }

            Rectangle {
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1
                implicitHeight: detailColumn.implicitHeight + Colors.spacingM * 2

                ColumnLayout {
                    id: detailColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingM
                    spacing: Colors.spacingS

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !!root.selectedUnit

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingXXS

                            Text {
                                text: root.selectedUnit ? String(root.selectedUnit.name || "service") : ""
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.selectedUnit ? (String(root.selectedUnit.scope || "").toUpperCase() + "  •  " + String(root.selectedUnit.description || root.selectedUnit.sub || "")) : ""
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeXS
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: root.selectedPendingAction !== "" ? ("PENDING  " + root.selectedPendingAction.toUpperCase()) : "READY"
                            color: root.selectedPendingAction !== "" ? Colors.warning : Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.Bold
                        }
                    }

                    SharedWidgets.EmptyState {
                        Layout.fillWidth: true
                        visible: !root.selectedUnit
                        icon: "󰒓"
                        message: root.visibleUnits.length === 0 ? "No service selected. Adjust filters or wait for service discovery." : "Select a service to inspect live unit detail."
                    }

                    Flow {
                        Layout.fillWidth: true
                        visible: !!root.selectedUnit
                        width: parent.width
                        spacing: Colors.spacingS

                        SharedWidgets.Chip {
                            icon: "󰒓"
                            iconColor: root.selectedUnit ? root.stateColor(root.selectedUnit) : Colors.textSecondary
                            text: root.selectedUnit ? String(root.selectedUnit.active || "").toUpperCase() : ""
                            textColor: root.selectedUnit ? root.stateColor(root.selectedUnit) : Colors.textSecondary
                        }

                        SharedWidgets.Chip {
                            icon: "󱄅"
                            iconColor: Colors.secondary
                            text: root.selectedUnit ? String(root.selectedUnit.sub || "") : ""
                            textColor: Colors.secondary
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        visible: !!root.selectedUnit
                        width: parent.width
                        spacing: Colors.spacingS

                        SharedWidgets.FilterChip {
                            label: root.selectedUnit && root.running(root.selectedUnit) ? "Stop" : "Start"
                            icon: root.selectedUnit && root.running(root.selectedUnit) ? "󰓛" : "󰐊"
                            enabled: !!root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnit.scope, root.selectedUnit.name)
                            selected: false
                            onClicked: {
                                if (!root.selectedUnit)
                                    return;
                                if (root.running(root.selectedUnit))
                                    ServiceUnitService.stopUnit(root.selectedUnit.scope, root.selectedUnit.name);
                                else
                                    ServiceUnitService.startUnit(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Restart"
                            icon: "󰑐"
                            enabled: !!root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnit.scope, root.selectedUnit.name)
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.restartUnit(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Logs"
                            icon: "󰌱"
                            enabled: !!root.selectedUnit
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.openUnitLogsInTerminal(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Status"
                            icon: "󰋼"
                            enabled: !!root.selectedUnit
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.openUnitStatusInTerminal(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Copy Unit"
                            icon: "󰅍"
                            enabled: !!root.selectedUnit
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.copyUnitName(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Copy Path"
                            icon: "󰅍"
                            enabled: !!root.selectedUnit && !!root.detailData.fragmentPath
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.copyUnitFragmentPath(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: !!root.selectedUnit
                        radius: Colors.radiusSmall
                        color: Colors.cardSurface
                        border.color: Colors.withAlpha(root.detailStatusColor(ServiceUnitService.detailStatus), 0.4)
                        border.width: 1
                        implicitHeight: liveDetailColumn.implicitHeight + Colors.spacingM * 2

                        ColumnLayout {
                            id: liveDetailColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingS

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "LIVE UNIT DETAIL"
                                    color: Colors.textDisabled
                                    font.pixelSize: Colors.fontSizeXS
                                    font.weight: Font.Bold
                                    font.letterSpacing: Colors.letterSpacingWide
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                SharedWidgets.Chip {
                                    icon: ServiceUnitService.detailBusy ? "󰑐" : "󰄬"
                                    iconColor: root.detailStatusColor(ServiceUnitService.detailStatus)
                                    text: ServiceUnitService.detailStatus.toUpperCase()
                                    textColor: root.detailStatusColor(ServiceUnitService.detailStatus)
                                }

                                SharedWidgets.Chip {
                                    icon: ServiceUnitService.detailDegraded ? "󰀦" : "󰥔"
                                    iconColor: ServiceUnitService.detailDegraded ? Colors.warning : Colors.textSecondary
                                    text: "Updated " + MU.formatAge(ServiceUnitService.detailLastUpdatedMs, root._clockTick)
                                    textColor: ServiceUnitService.detailDegraded ? Colors.warning : Colors.textSecondary
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: ServiceUnitService.detailMessage !== ""
                                text: ServiceUnitService.detailMessage
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: root.selectedUnit
                                    && ServiceUnitService.lastActionScope === root.selectedUnit.scope
                                    && ServiceUnitService.lastActionUnitName === root.selectedUnit.name
                                    && ServiceUnitService.lastActionMessage !== ""
                                text: ServiceUnitService.lastActionMessage + "  •  " + MU.formatAge(ServiceUnitService.lastActionAt, root._clockTick)
                                color: root.actionStatusColor(ServiceUnitService.lastActionState)
                                font.pixelSize: Colors.fontSizeXS
                                wrapMode: Text.WordWrap
                            }

                            Flow {
                                Layout.fillWidth: true
                                width: parent.width
                                spacing: Colors.spacingS

                                SharedWidgets.Chip {
                                    icon: "󰈐"
                                    iconColor: Colors.primary
                                    text: "PID " + (root.detailData.mainPid !== undefined && root.detailData.mainPid !== null ? String(root.detailData.mainPid) : "Unavailable")
                                    textColor: Colors.primary
                                }

                                SharedWidgets.Chip {
                                    icon: "󰜎"
                                    iconColor: Colors.secondary
                                    text: "EXIT " + (root.detailData.execMainStatus !== undefined && root.detailData.execMainStatus !== null ? String(root.detailData.execMainStatus) : "Unavailable")
                                    textColor: Colors.secondary
                                }

                                SharedWidgets.Chip {
                                    icon: "󰍛"
                                    iconColor: Colors.accent
                                    text: "MEM " + MU.formatBytes(root.detailData.memoryCurrent)
                                    textColor: Colors.accent
                                }

                                SharedWidgets.Chip {
                                    icon: "󰓅"
                                    iconColor: Colors.warning
                                    text: "TASKS " + (root.detailData.tasksCurrent !== undefined && root.detailData.tasksCurrent !== null ? String(root.detailData.tasksCurrent) : "Unavailable")
                                    textColor: Colors.warning
                                }

                                SharedWidgets.Chip {
                                    icon: ServiceUnitService.detailPermissionLimited ? "󰌾" : "󰄬"
                                    iconColor: ServiceUnitService.detailPermissionLimited ? Colors.warning : Colors.success
                                    text: ServiceUnitService.detailPermissionLimited ? "Permission limited" : "Live unit healthy"
                                    textColor: ServiceUnitService.detailPermissionLimited ? Colors.warning : Colors.success
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                color: Colors.cardSurface
                                radius: Colors.radiusSmall
                                border.color: Colors.borderFocus
                                border.width: 1
                                implicitHeight: fragmentBlock.implicitHeight + Colors.spacingS * 2

                                ColumnLayout {
                                    id: fragmentBlock
                                    anchors.fill: parent
                                    anchors.margins: Colors.spacingS
                                    spacing: Colors.spacingXXS

                                    Text {
                                        text: "FRAGMENT PATH"
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.fallbackText(root.detailData.fragmentPath)
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        font.family: Colors.fontMono
                                        wrapMode: Text.WrapAnywhere
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                color: Colors.cardSurface
                                radius: Colors.radiusSmall
                                border.color: Colors.borderFocus
                                border.width: 1
                                implicitHeight: logsBlock.implicitHeight + Colors.spacingS * 2

                                ColumnLayout {
                                    id: logsBlock
                                    anchors.fill: parent
                                    anchors.margins: Colors.spacingS
                                    spacing: Colors.spacingXXS

                                    Text {
                                        text: "RECENT LOGS"
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: !root.detailData.recentLogs || root.detailData.recentLogs.length === 0
                                        text: "Unavailable"
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        font.family: Colors.fontMono
                                    }

                                    Repeater {
                                        model: root.detailData.recentLogs || []

                                        delegate: Text {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            text: String(modelData || "")
                                            color: Colors.textSecondary
                                            font.pixelSize: Colors.fontSizeXS
                                            font.family: Colors.fontMono
                                            wrapMode: Text.WrapAnywhere
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
