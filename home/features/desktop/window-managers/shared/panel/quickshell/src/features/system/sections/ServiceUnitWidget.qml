import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    property string searchQuery: ""
    property string filterMode: "failed"
    property bool showSystemUnits: false
    property int defaultLimit: 5
    property int searchLimit: 10
    property bool compactMode: false
    property string selectedUnitScope: "user"
    property string selectedUnitName: ""
    property bool detailsExpanded: true
    readonly property var visibleUserUnits: filterUnits(ServiceUnitService.userUnits)
    readonly property var visibleSystemUnits: filterUnits(ServiceUnitService.systemUnits)
    readonly property bool systemAvailable: ServiceUnitService.systemStatus === "ready"
    readonly property var selectedUnit: selectedUnitScope === "system" ? findUnitByName(visibleSystemUnits, selectedUnitName) : findUnitByName(visibleUserUnits, selectedUnitName)
    readonly property string selectedPendingAction: selectedUnit ? ServiceUnitService.pendingActionForUnit(selectedUnitScope, selectedUnitName) : ""

    Layout.fillWidth: true
    Layout.preferredHeight: unitsColumn.implicitHeight + root.pad * 2

    function matchesQuery(unit) {
        var query = String(searchQuery || "").trim().toLowerCase();
        if (query === "")
            return true;

        var haystack = [String(unit.name || ""), String(unit.description || ""), String(unit.active || ""), String(unit.sub || "")].join(" ").toLowerCase();
        return haystack.indexOf(query) !== -1;
    }

    function matchesFilter(unit) {
        var mode = String(filterMode || "failed");
        if (mode === "all")
            return true;
        if (mode === "busy")
            return String(unit.active || "") === "activating" || String(unit.sub || "").indexOf("running") === -1;
        return String(unit.active || "") === "failed" || String(unit.sub || "") === "failed";
    }

    function filterUnits(source) {
        var units = source || [];
        var filtered = [];
        for (var i = 0; i < units.length; i++) {
            var unit = units[i];
            if (!matchesQuery(unit) || !matchesFilter(unit))
                continue;
            filtered.push(unit);
        }
        filtered.sort(function (a, b) {
            return root.unitPriority(a) - root.unitPriority(b);
        });
        var limit = String(searchQuery || "").trim() === "" ? defaultLimit : searchLimit;
        return filtered.slice(0, limit);
    }

    function unitPriority(unit) {
        var active = String(unit.active || "");
        var sub = String(unit.sub || "");
        if (active === "failed" || sub === "failed")
            return 0;
        if (active === "activating" || active === "reloading")
            return 1;
        if (sub.indexOf("auto-restart") !== -1 || sub.indexOf("dead") !== -1)
            return 2;
        return 3;
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

    function running(unit) {
        return String(unit.active || "") === "active" && String(unit.sub || "").indexOf("running") !== -1;
    }

    function findUnitByName(source, unitName) {
        var safeName = String(unitName || "");
        if (safeName === "")
            return null;

        var units = source || [];
        for (var i = 0; i < units.length; i++) {
            if (String(units[i].name || "") === safeName)
                return units[i];
        }
        return null;
    }

    function selectUnit(scope, unitName) {
        var safeScope = String(scope || "user");
        var safeName = String(unitName || "");
        if (safeName === "") {
            selectedUnitName = "";
            detailsExpanded = false;
            return;
        }

        if (selectedUnitScope === safeScope && selectedUnitName === safeName) {
            detailsExpanded = !detailsExpanded;
            return;
        }

        selectedUnitScope = safeScope;
        selectedUnitName = safeName;
        detailsExpanded = !compactMode;
    }

    function syncSelection() {
        if (selectedUnitScope === "system") {
            if (findUnitByName(visibleSystemUnits, selectedUnitName))
                return;
            if (visibleSystemUnits.length > 0) {
                selectUnit("system", visibleSystemUnits[0].name || "");
                return;
            }
        }

        if (findUnitByName(visibleUserUnits, selectedUnitName))
            return;
        if (visibleUserUnits.length > 0) {
            selectUnit("user", visibleUserUnits[0].name || "");
            return;
        }
        if (visibleSystemUnits.length > 0 && showSystemUnits) {
            selectUnit("system", visibleSystemUnits[0].name || "");
            return;
        }
        selectedUnitName = "";
        detailsExpanded = false;
    }

    onVisibleUserUnitsChanged: syncSelection()
    onVisibleSystemUnitsChanged: syncSelection()
    onShowSystemUnitsChanged: syncSelection()
    Component.onCompleted: syncSelection()

    ColumnLayout {
        id: unitsColumn
        Layout.fillWidth: true
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "SERVICES"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
            }

            SharedWidgets.IconButton {
                icon: "arrow-clockwise.svg"
                size: 28
                iconSize: Colors.fontSizeSmall
                iconColor: Colors.textSecondary
                onClicked: ServiceUnitService.refresh()
            }
        }

        SharedWidgets.SearchBar {
            id: unitSearchBar
            placeholder: "Filter services..."
            onTextChanged: root.searchQuery = text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

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
                label: "All"
                selected: root.filterMode === "all"
                onClicked: root.filterMode = "all"
            }
        }

        Text {
            Layout.fillWidth: true
            text: ServiceUnitService.userStatus === "ready" ? ("User units  •  showing " + String(root.visibleUserUnits.length)) : (ServiceUnitService.userMessage || "User services unavailable")
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
        }

        ListView {
            Layout.fillWidth: true
            visible: ServiceUnitService.userStatus === "ready" && visibleUserUnits.length > 0
            implicitHeight: contentHeight
            interactive: false
            clip: true
            spacing: Colors.spacingXS
            model: root.visibleUserUnits

            add: Transition {
                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: Colors.durationFast }
            }
            remove: Transition {
                NumberAnimation { properties: "opacity"; from: 1; to: 0; duration: Colors.durationFast }
            }

            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: root.selectedUnitScope === "user" && root.selectedUnitName === String(modelData.name || "")
                width: ListView.view.width
                radius: Colors.radiusSmall
                color: selected ? Colors.highlight : Colors.highlightLight
                border.color: selected ? Colors.primary : Colors.withAlpha(root.stateColor(modelData), 0.65)
                border.width: 1
                implicitHeight: unitColumn.implicitHeight + Colors.spacingS * 2

                ColumnLayout {
                    id: unitColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingXS

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingS

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingXXS

                            Text {
                                text: modelData.name || "service"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.description || modelData.sub || ""
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: String(modelData.active || "unknown").toUpperCase()
                            color: selected ? Colors.primary : root.stateColor(modelData)
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.Bold
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingS

                        SharedWidgets.FilterChip {
                            label: root.running(modelData) ? "Stop" : "Start"
                            icon: root.running(modelData) ? "󰓛" : "󰐊"
                            enabled: !ServiceUnitService.isUnitPending("user", modelData.name)
                            selected: false
                            onClicked: {
                                if (root.running(modelData))
                                    ServiceUnitService.stopUnit("user", modelData.name);
                                else
                                    ServiceUnitService.startUnit("user", modelData.name);
                            }
                        }

                        SharedWidgets.FilterChip {
                            label: "Restart"
                            icon: "arrow-clockwise.svg"
                            enabled: !ServiceUnitService.isUnitPending("user", modelData.name)
                            selected: false
                            onClicked: ServiceUnitService.restartUnit("user", modelData.name)
                        }

                        Text {
                            text: ServiceUnitService.pendingActionForUnit("user", modelData.name).toUpperCase()
                            color: Colors.warning
                            font.pixelSize: Colors.fontSizeXS
                            visible: ServiceUnitService.isUnitPending("user", modelData.name)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectUnit("user", modelData.name || "")
                }
            }
        }

        SharedWidgets.EmptyState {
            Layout.fillWidth: true
            visible: ServiceUnitService.userStatus === "ready" && visibleUserUnits.length === 0
            icon: "filter.svg"
            message: String(searchQuery || "").trim() === "" ? "No matching user services for this filter." : "No user services match the current search."
        }

        Rectangle {
            Layout.fillWidth: true
            visible: ServiceUnitService.userStatus !== "ready"
            color: Colors.bgWidget
            radius: Colors.radiusSmall
            border.color: Colors.border
            border.width: 1
            implicitHeight: userUnavailable.implicitHeight + Colors.spacingS * 2

            SharedWidgets.EmptyState {
                id: userUnavailable
                anchors.centerIn: parent
                icon: "error.svg"
                message: ServiceUnitService.userMessage || "User services unavailable."
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Colors.radiusSmall
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            implicitHeight: systemHeader.implicitHeight + Colors.spacingS * 2

            RowLayout {
                id: systemHeader
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: Colors.spacingS

                Text {
                    text: "SYSTEM UNITS"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: ServiceUnitService.systemStatus === "ready" ? String(ServiceUnitService.systemUnits.length) : (ServiceUnitService.systemMessage || "unavailable")
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                }

                SharedWidgets.FilterChip {
                    label: root.showSystemUnits ? "Hide" : "Show"
                    selected: root.showSystemUnits
                    enabled: root.systemAvailable
                    onClicked: root.showSystemUnits = !root.showSystemUnits
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            visible: root.showSystemUnits && root.systemAvailable && visibleSystemUnits.length > 0
            implicitHeight: contentHeight
            interactive: false
            clip: true
            spacing: Colors.spacingXS
            model: root.visibleSystemUnits

            add: Transition {
                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: Colors.durationFast }
            }
            remove: Transition {
                NumberAnimation { properties: "opacity"; from: 1; to: 0; duration: Colors.durationFast }
            }

            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: root.selectedUnitScope === "system" && root.selectedUnitName === String(modelData.name || "")
                width: ListView.view.width
                radius: Colors.radiusSmall
                color: selected ? Colors.highlight : Colors.bgWidget
                border.color: selected ? Colors.primary : Colors.withAlpha(root.stateColor(modelData), 0.55)
                border.width: 1
                implicitHeight: systemUnitColumn.implicitHeight + Colors.spacingS * 2

                ColumnLayout {
                    id: systemUnitColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingXS

                    Text {
                        text: modelData.name || "service"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: (modelData.description || "") + "  •  " + String(modelData.active || "unknown")
                        color: root.stateColor(modelData)
                        font.pixelSize: Colors.fontSizeXS
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingS

                        SharedWidgets.FilterChip {
                            label: "Restart"
                            icon: "arrow-clockwise.svg"
                            enabled: !ServiceUnitService.isUnitPending("system", modelData.name)
                            selected: false
                            onClicked: ServiceUnitService.restartUnit("system", modelData.name)
                        }

                        SharedWidgets.FilterChip {
                            label: root.running(modelData) ? "Stop" : "Start"
                            icon: root.running(modelData) ? "󰓛" : "󰐊"
                            enabled: !ServiceUnitService.isUnitPending("system", modelData.name)
                            selected: false
                            onClicked: {
                                if (root.running(modelData))
                                    ServiceUnitService.stopUnit("system", modelData.name);
                                else
                                    ServiceUnitService.startUnit("system", modelData.name);
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectUnit("system", modelData.name || "")
                }
            }
        }

        SharedWidgets.EmptyState {
            Layout.fillWidth: true
            visible: root.showSystemUnits && root.systemAvailable && visibleSystemUnits.length === 0
            icon: "filter.svg"
            message: String(searchQuery || "").trim() === "" ? "No system units matched the current filter." : "No system units match the current search."
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.showSystemUnits && !root.systemAvailable
            color: Colors.bgWidget
            radius: Colors.radiusSmall
            border.color: Colors.border
            border.width: 1
            implicitHeight: systemUnavailable.implicitHeight + Colors.spacingS * 2

            SharedWidgets.EmptyState {
                id: systemUnavailable
                anchors.centerIn: parent
                icon: "error.svg"
                message: ServiceUnitService.systemMessage || "System services unavailable."
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: !!root.selectedUnit && !root.detailsExpanded
            radius: Colors.radiusSmall
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            implicitHeight: collapsedUnitRow.implicitHeight + Colors.spacingS * 2

            RowLayout {
                id: collapsedUnitRow
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: Colors.spacingS

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingXXS

                    Text {
                        text: root.selectedUnit ? String(root.selectedUnit.name || "service") : ""
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.selectedUnit ? ("Details collapsed. Select the row again to reopen " + (root.selectedUnitScope === "system" ? "system" : "user") + " unit actions.") : ""
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                SharedWidgets.IconButton {
                    icon: "add.svg"
                    size: 28
                    iconSize: Colors.fontSizeSmall
                    iconColor: Colors.primary
                    onClicked: root.detailsExpanded = true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: !!root.selectedUnit && root.detailsExpanded
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingXXS

                    Text {
                        text: root.selectedUnit ? String(root.selectedUnit.name || "service") : ""
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.selectedUnit ? ((root.selectedUnitScope === "system" ? "SYSTEM" : "USER") + "  •  " + String(root.selectedUnit.description || root.selectedUnit.sub || "service")) : ""
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    SharedWidgets.FilterChip {
                        label: root.selectedUnit && root.running(root.selectedUnit) ? "Stop" : "Start"
                        icon: root.selectedUnit && root.running(root.selectedUnit) ? "󰓛" : "󰐊"
                        enabled: root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnitScope, root.selectedUnitName)
                        selected: false
                        onClicked: {
                            if (!root.selectedUnit)
                                return;
                            if (root.running(root.selectedUnit))
                                ServiceUnitService.stopUnit(root.selectedUnitScope, root.selectedUnitName);
                            else
                                ServiceUnitService.startUnit(root.selectedUnitScope, root.selectedUnitName);
                        }
                    }

                    SharedWidgets.FilterChip {
                        label: "Restart"
                        icon: "arrow-clockwise.svg"
                        enabled: root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnitScope, root.selectedUnitName)
                        selected: false
                        onClicked: ServiceUnitService.restartUnit(root.selectedUnitScope, root.selectedUnitName)
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    SharedWidgets.FilterChip {
                        label: "Reload"
                        icon: "arrow-clockwise.svg"
                        enabled: root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnitScope, root.selectedUnitName)
                        selected: false
                        onClicked: ServiceUnitService.reloadUnit(root.selectedUnitScope, root.selectedUnitName)
                    }

                    SharedWidgets.FilterChip {
                        label: "Logs"
                        icon: "terminal.svg"
                        enabled: root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnitScope, root.selectedUnitName)
                        selected: false
                        onClicked: ServiceUnitService.openUnitLogsInTerminal(root.selectedUnitScope, root.selectedUnitName)
                    }

                    SharedWidgets.FilterChip {
                        label: "Status"
                        icon: "info.svg"
                        enabled: root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnitScope, root.selectedUnitName)
                        selected: false
                        onClicked: ServiceUnitService.openUnitStatusInTerminal(root.selectedUnitScope, root.selectedUnitName)
                    }

                    SharedWidgets.FilterChip {
                        label: "Copy Name"
                        icon: "copy.svg"
                        enabled: root.selectedUnit && !ServiceUnitService.isUnitPending(root.selectedUnitScope, root.selectedUnitName)
                        selected: false
                        onClicked: ServiceUnitService.copyUnitName(root.selectedUnitScope, root.selectedUnitName)
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    SharedWidgets.Chip {
                        icon: "desktop.svg"
                        iconColor: root.selectedUnit ? root.stateColor(root.selectedUnit) : Colors.textSecondary
                        text: root.selectedUnit ? ("ACTIVE " + String(root.selectedUnit.active || "unknown").toUpperCase()) : ""
                        textColor: root.selectedUnit ? root.stateColor(root.selectedUnit) : Colors.textSecondary
                    }

                    SharedWidgets.Chip {
                        icon: "arrow-counterclockwise.svg"
                        iconColor: root.selectedUnit ? root.stateColor(root.selectedUnit) : Colors.textSecondary
                        text: root.selectedUnit ? ("SUB " + String(root.selectedUnit.sub || "unknown")) : ""
                        textColor: root.selectedUnit ? root.stateColor(root.selectedUnit) : Colors.textSecondary
                    }

                    SharedWidgets.Chip {
                        icon: "settings.svg"
                        iconColor: Colors.textSecondary
                        text: root.selectedUnit ? ("LOAD " + String(root.selectedUnit.load || "unknown")) : ""
                        textColor: Colors.textSecondary
                    }

                    SharedWidgets.Chip {
                        icon: root.selectedUnitScope === "system" ? "󰒋" : "󰌾"
                        iconColor: Colors.secondary
                        text: root.selectedUnitScope === "system" ? "SCOPE SYSTEM" : "SCOPE USER"
                        textColor: Colors.secondary
                    }
                }

                Text {
                    text: root.selectedPendingAction !== "" ? ("PENDING  •  " + root.selectedPendingAction.toUpperCase()) : "READY"
                    color: root.selectedPendingAction !== "" ? Colors.warning : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                }

                Text {
                    text: "DETAILS"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.fillWidth: true
                    color: Colors.cardSurface
                    radius: Colors.radiusSmall
                    border.color: Colors.withAlpha(Colors.border, 0.65)
                    border.width: 1
                    implicitHeight: detailText.implicitHeight + Colors.spacingS * 2

                    Text {
                        id: detailText
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        text: root.selectedUnit ? ("Description: " + String(root.selectedUnit.description || "n/a") + "\nUnit: " + String(root.selectedUnit.name || "") + "\nState: " + String(root.selectedUnit.active || "unknown") + " / " + String(root.selectedUnit.sub || "unknown") + "\nLoad: " + String(root.selectedUnit.load || "unknown")) : ""
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
