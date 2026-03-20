import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

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
            spacing: Appearance.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Text {
                    text: "SERVICE TABLE"
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Bold
                    font.letterSpacing: Appearance.letterSpacingWide
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
                    icon: "arrow-clockwise.svg"
                    size: 28
                    iconSize: Appearance.fontSizeSmall
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
                spacing: Appearance.spacingS

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
                radius: Appearance.radiusSmall
                color: Colors.cardSurface
                border.color: keyboardFocused ? Colors.primary : Colors.border
                border.width: 1
                implicitHeight: tableColumn.implicitHeight + Appearance.spacingS * 2

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

                            Text {
                                Layout.preferredWidth: 70
                                text: "SCOPE"
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.preferredWidth: 92
                                text: "STATE"
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "UNIT"
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.preferredWidth: 120
                                text: "SUBSTATE"
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    SharedWidgets.EmptyState {
                        Layout.fillWidth: true
                        visible: root.visibleUnits.length === 0
                        icon: "filter.svg"
                        message: root.trimmedSearch === "" ? "No matching services for the current filter." : "No services matched the current search."
                    }

                    ListView {
                        id: serviceListView
                        Layout.fillWidth: true
                        implicitHeight: contentHeight
                        interactive: false
                        clip: true
                        visible: root.visibleUnits.length > 0
                        model: root.visibleUnits
                        spacing: Appearance.spacingXXS

                        add: ListTransitions.addFadeHeight
                        remove: ListTransitions.removeFadeHeight
                        displaced: ListTransitions.displaced

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.selectedIndex
                            width: ListView.view.width
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
                                    Layout.preferredWidth: 70
                                    text: String(modelData.scope || "").toUpperCase()
                                    color: Colors.textSecondary
                                    font.pixelSize: Appearance.fontSizeXS
                                    font.weight: Font.Bold
                                }

                                Text {
                                    Layout.preferredWidth: 92
                                    text: String(modelData.active || "").toUpperCase()
                                    color: root.stateColor(modelData)
                                    font.pixelSize: Appearance.fontSizeXS
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: String(modelData.name || "service")
                                    color: Colors.text
                                    font.pixelSize: Appearance.fontSizeXS
                                    font.weight: selected ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.preferredWidth: 120
                                    text: String(modelData.sub || "")
                                    color: Colors.textSecondary
                                    font.pixelSize: Appearance.fontSizeXS
                                    font.family: Appearance.fontMono
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

            Rectangle {
                Layout.fillWidth: true
                radius: Appearance.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1
                implicitHeight: detailColumn.implicitHeight + Appearance.spacingM * 2

                ColumnLayout {
                    id: detailColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingM
                    spacing: Appearance.spacingS

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !!root.selectedUnit

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: root.selectedUnit ? String(root.selectedUnit.name || "service") : ""
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeSmall
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.selectedUnit ? (String(root.selectedUnit.scope || "").toUpperCase() + "  •  " + String(root.selectedUnit.description || root.selectedUnit.sub || "")) : ""
                                color: Colors.textDisabled
                                font.pixelSize: Appearance.fontSizeXS
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: root.selectedPendingAction !== "" ? ("PENDING  " + root.selectedPendingAction.toUpperCase()) : "READY"
                            color: root.selectedPendingAction !== "" ? Colors.warning : Colors.textDisabled
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.Bold
                        }
                    }

                    SharedWidgets.EmptyState {
                        Layout.fillWidth: true
                        visible: !root.selectedUnit
                        icon: "settings.svg"
                        message: root.visibleUnits.length === 0 ? "No service selected. Adjust filters or wait for service discovery." : "Select a service to inspect live unit detail."
                    }

                    Flow {
                        Layout.fillWidth: true
                        visible: !!root.selectedUnit
                        width: parent.width
                        spacing: Appearance.spacingS

                        SharedWidgets.Chip {
                            icon: "settings.svg"
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
                        spacing: Appearance.spacingS

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
                            icon: "arrow-clockwise.svg"
                            enabled: !!root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnit.scope, root.selectedUnit.name)
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.restartUnit(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Logs"
                            icon: "terminal.svg"
                            enabled: !!root.selectedUnit
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.openUnitLogsInTerminal(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Status"
                            icon: "info.svg"
                            enabled: !!root.selectedUnit
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.openUnitStatusInTerminal(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Copy Unit"
                            icon: "copy.svg"
                            enabled: !!root.selectedUnit
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.copyUnitName(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Copy Path"
                            icon: "copy.svg"
                            enabled: !!root.selectedUnit && !!root.detailData.fragmentPath
                            selected: false
                            onClicked: {
                                if (root.selectedUnit)
                                    ServiceUnitService.copyUnitFragmentPath(root.selectedUnit.scope, root.selectedUnit.name);
                            }
                        }
                    }

                    ServiceUnitLiveDetail {
                        visible: !!root.selectedUnit
                        selectedUnit: root.selectedUnit
                        detailData: root.detailData
                        clockTick: root._clockTick
                        detailStatusColorFn: root.detailStatusColor
                        actionStatusColorFn: root.actionStatusColor
                        fallbackTextFn: root.fallbackText
                    }
                }
            }
        }
    }
}
