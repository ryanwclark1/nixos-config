import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    property string searchQuery: ""
    property string stateFilter: "all"
    property int maxItems: 6
    property int searchLimit: 12
    property int selectedPid: 0
    property bool compactMode: false
    property bool detailsExpanded: true

    readonly property string trimmedSearch: String(searchQuery || "").trim().toLowerCase()
    readonly property var visibleProcesses: computeVisibleProcesses()
    readonly property var selectedProcess: findVisibleProcessByPid(selectedPid)
    readonly property string pendingAction: ProcessService.pendingActionForPid(selectedPid)

    Layout.fillWidth: true
    Layout.preferredHeight: processColumn.implicitHeight + root.pad * 2

    function matchesQuery(process) {
        if (trimmedSearch === "")
            return true;

        var haystack = [String(process.pid || ""), String(process.user || ""), String(process.name || ""), String(process.command || "")].join(" ").toLowerCase();
        return haystack.indexOf(trimmedSearch) !== -1;
    }

    function matchesStateFilter(process) {
        if (stateFilter === "all")
            return true;
        if (stateFilter === "running")
            return String(process.state || "").indexOf("T") === -1;
        if (stateFilter === "stopped")
            return String(process.state || "").indexOf("T") !== -1;
        return Number(process.cpu || 0) >= 10 || Number(process.mem || 0) >= 5;
    }

    function computeVisibleProcesses() {
        var source = ProcessService.processes || [];
        var filtered = [];
        for (var i = 0; i < source.length; i++) {
            var process = source[i];
            if (!matchesQuery(process) || !matchesStateFilter(process))
                continue;
            filtered.push(process);
        }
        var limit = trimmedSearch === "" ? maxItems : searchLimit;
        return filtered.slice(0, limit);
    }

    function findVisibleProcessByPid(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0)
            return null;

        for (var i = 0; i < visibleProcesses.length; i++) {
            if ((visibleProcesses[i].pid || 0) === safePid)
                return visibleProcesses[i];
        }
        return null;
    }

    function selectProcess(pid) {
        var safePid = parseInt(pid, 10) || 0;
        if (safePid <= 0) {
            selectedPid = 0;
            detailsExpanded = false;
            return;
        }

        if (selectedPid === safePid) {
            detailsExpanded = !detailsExpanded;
            return;
        }

        selectedPid = safePid;
        detailsExpanded = !compactMode;
    }

    function syncSelection() {
        if (visibleProcesses.length === 0) {
            selectedPid = 0;
            detailsExpanded = false;
            return;
        }

        if (!findVisibleProcessByPid(selectedPid)) {
            selectedPid = visibleProcesses[0].pid || 0;
            detailsExpanded = !compactMode;
        }
    }

    onVisibleProcessesChanged: syncSelection()
    Component.onCompleted: syncSelection()

    ColumnLayout {
        id: processColumn
        Layout.fillWidth: true
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "TOP PROCESSES"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
            }

            SharedWidgets.IconButton {
                icon: "󰑐"
                size: 28
                iconSize: Colors.fontSizeSmall
                iconColor: Colors.textSecondary
                onClicked: ProcessService.refresh()
            }

            SharedWidgets.FilterChip {
                label: "CPU"
                selected: ProcessService.sortBy === "cpu"
                onClicked: {
                    ProcessService.sortBy = "cpu";
                    ProcessService.refresh();
                }
            }

            SharedWidgets.FilterChip {
                label: "RAM"
                selected: ProcessService.sortBy === "mem"
                onClicked: {
                    ProcessService.sortBy = "mem";
                    ProcessService.refresh();
                }
            }
        }

        SharedWidgets.SearchBar {
            id: processSearchBar
            placeholder: "Filter by PID, user, name, or command..."
            onTextChanged: root.searchQuery = text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

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
        }

        Text {
            Layout.fillWidth: true
            text: ProcessService.busy ? "Refreshing process snapshot..." : (root.trimmedSearch === "" ? ("Showing " + String(root.visibleProcesses.length) + " hottest processes by " + (ProcessService.sortBy === "cpu" ? "CPU." : "RAM.")) : ("Showing " + String(root.visibleProcesses.length) + " matches for \"" + root.searchQuery + "\"."))
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
        }

        SharedWidgets.EmptyState {
            Layout.fillWidth: true
            visible: !ProcessService.busy && root.visibleProcesses.length === 0
            icon: "󰍉"
            message: root.trimmedSearch === "" ? "No processes matched the current filter." : "No processes matched the current search."
        }

        Rectangle {
            Layout.fillWidth: true
            visible: !!root.selectedProcess && !root.detailsExpanded
            radius: Colors.radiusSmall
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            implicitHeight: collapsedProcessRow.implicitHeight + Colors.spacingS * 2

            RowLayout {
                id: collapsedProcessRow
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: Colors.spacingS

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingXXS

                    Text {
                        text: root.selectedProcess ? (String(root.selectedProcess.name || "process") + "  •  PID " + String(root.selectedProcess.pid || 0)) : ""
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "Details collapsed. Select the row again to reopen actions."
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                SharedWidgets.IconButton {
                    icon: "󰐕"
                    size: 28
                    iconSize: Colors.fontSizeSmall
                    iconColor: Colors.primary
                    onClicked: root.detailsExpanded = true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS
            visible: root.visibleProcesses.length > 0

            Repeater {
                id: processRepeater
                model: root.visibleProcesses

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    readonly property bool selected: (modelData.pid || 0) === root.selectedPid
                    implicitHeight: processRow.implicitHeight + Colors.spacingS * 2
                    radius: Colors.radiusSmall
                    color: selected ? Colors.highlight : Colors.highlightLight
                    border.color: selected ? Colors.primary : Colors.withAlpha(Colors.border, 0.75)
                    border.width: 1

                    Behavior on color {
                        CAnim {}
                    }

                    Behavior on border.color {
                        CAnim {}
                    }

                    RowLayout {
                        id: processRow
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: Colors.spacingS

                        Text {
                            text: "󰆍"
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeMedium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingXXS

                            Text {
                                text: modelData.name || "process"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: selected ? Font.DemiBold : Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: String(modelData.user || "user") + "  •  PID " + String(modelData.pid || 0)
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeXS
                                font.family: Colors.fontMono
                            }
                        }

                        ColumnLayout {
                            spacing: Colors.spacingXXS
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: (ProcessService.sortBy === "cpu" ? "CPU " : "RAM ") + Number(ProcessService.sortBy === "cpu" ? (modelData.cpu || 0) : (modelData.mem || 0)).toFixed(1) + "%"
                                color: ProcessService.sortBy === "cpu" ? Colors.primary : Colors.accent
                                font.pixelSize: Colors.fontSizeXS
                                font.family: Colors.fontMono
                            }

                            Text {
                                text: String(modelData.elapsed || "--:--")
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.family: Colors.fontMono
                            }
                        }

                        SharedWidgets.IconButton {
                            icon: "󰐊"
                            size: 28
                            iconSize: Colors.fontSizeSmall
                            iconColor: selected ? Colors.primary : Colors.textSecondary
                            onClicked: root.selectProcess(modelData.pid)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectProcess(modelData.pid)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: !!root.selectedProcess && root.detailsExpanded
                implicitHeight: detailColumn.implicitHeight + Colors.spacingM * 2
                radius: Colors.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: detailColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingM
                    spacing: Colors.spacingS

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXXS

                        Text {
                            text: root.selectedProcess ? (root.selectedProcess.name || "process") : ""
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: root.selectedProcess ? ("PID " + String(root.selectedProcess.pid || 0) + "  •  " + String(root.selectedProcess.user || "user")) : ""
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXS
                            font.family: Colors.fontMono
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Colors.spacingS

                        SharedWidgets.FilterChip {
                            label: "TERM"
                            icon: "󰐊"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.terminateProcess(root.selectedPid)
                        }

                        SharedWidgets.FilterChip {
                            label: "KILL"
                            icon: "󰅖"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.killProcess(root.selectedPid)
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Colors.spacingS

                        SharedWidgets.Chip {
                            icon: "󰍛"
                            iconColor: Colors.primary
                            text: "CPU " + Number(root.selectedProcess ? root.selectedProcess.cpu : 0).toFixed(1) + "%"
                            textColor: Colors.primary
                        }

                        SharedWidgets.Chip {
                            icon: "󰾆"
                            iconColor: Colors.accent
                            text: "RAM " + Number(root.selectedProcess ? root.selectedProcess.mem : 0).toFixed(1) + "%"
                            textColor: Colors.accent
                        }

                        SharedWidgets.Chip {
                            icon: "󰈈"
                            iconColor: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? Colors.warning : Colors.textSecondary
                            text: root.selectedProcess ? ("STATE " + String(root.selectedProcess.state || "?")) : ""
                            textColor: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? Colors.warning : Colors.textSecondary
                        }

                        SharedWidgets.Chip {
                            icon: "󰥔"
                            iconColor: Colors.secondary
                            text: root.selectedProcess ? String(root.selectedProcess.elapsed || "--:--") : ""
                            textColor: Colors.secondary
                        }

                        SharedWidgets.Chip {
                            icon: "󰘚"
                            iconColor: Colors.textSecondary
                            text: root.selectedProcess ? ("PPID " + String(root.selectedProcess.parentPid || 0)) : ""
                            textColor: Colors.textSecondary
                        }

                        SharedWidgets.Chip {
                            icon: "󰓅"
                            iconColor: root.selectedProcess && Number(root.selectedProcess.nice || 0) < 0 ? Colors.primary : Colors.textSecondary
                            text: root.selectedProcess ? ("NICE " + String(root.selectedProcess.nice || 0)) : ""
                            textColor: root.selectedProcess && Number(root.selectedProcess.nice || 0) < 0 ? Colors.primary : Colors.textSecondary
                        }
                    }

                    Text {
                        text: root.pendingAction !== "" ? ("PENDING  •  " + root.pendingAction.toUpperCase()) : "READY"
                        color: root.pendingAction !== "" ? Colors.warning : Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.Bold
                    }

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Colors.spacingS

                        SharedWidgets.FilterChip {
                            label: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? "Resume" : "Suspend"
                            icon: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? "󰐎" : "󰏤"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.togglePause(root.selectedPid)
                        }

                        SharedWidgets.FilterChip {
                            label: "Inspect"
                            icon: "󰆍"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.openProcessInTerminal(root.selectedPid)
                        }

                        SharedWidgets.FilterChip {
                            label: "Files"
                            icon: "󰈔"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.openProcessDetailsInTerminal(root.selectedPid)
                        }

                        SharedWidgets.FilterChip {
                            label: "Copy Cmd"
                            icon: "󰅍"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.copyCommand(root.selectedPid)
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Colors.spacingS

                        SharedWidgets.FilterChip {
                            label: "Lower Load"
                            icon: "󰁅"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.reniceProcess(root.selectedPid, Number(root.selectedProcess ? root.selectedProcess.nice : 0) + 5)
                        }

                        SharedWidgets.FilterChip {
                            label: "Boost"
                            icon: "󰁝"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.reniceProcess(root.selectedPid, Number(root.selectedProcess ? root.selectedProcess.nice : 0) - 5)
                        }

                        SharedWidgets.FilterChip {
                            label: "Copy PID"
                            icon: "󰌹"
                            enabled: !ProcessService.isPidPending(root.selectedPid)
                            selected: false
                            onClicked: ProcessService.copyPid(root.selectedPid)
                        }
                    }

                    Text {
                        text: "COMMAND"
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
                        implicitHeight: commandText.implicitHeight + Colors.spacingS * 2

                        Text {
                            id: commandText
                            anchors.fill: parent
                            anchors.margins: Colors.spacingS
                            text: root.selectedProcess ? String(root.selectedProcess.command || root.selectedProcess.name || "") : ""
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
