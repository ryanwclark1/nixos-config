import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    property string searchQuery: ""
    property string stateFilter: "all"
    property int maxRows: 24
    property string sortField: ProcessService.sortBy === "mem" ? "mem" : "cpu"
    property bool sortDescending: true
    property int selectedPid: 0

    readonly property string trimmedSearch: String(searchQuery || "").trim().toLowerCase()
    readonly property var visibleProcesses: computeVisibleProcesses()
    readonly property var selectedProcess: findProcessByPid(selectedPid)
    readonly property string pendingAction: ProcessService.pendingActionForPid(selectedPid)
    readonly property bool keyboardFocused: tableFocus.activeFocus

    Layout.fillWidth: true
    Layout.preferredHeight: processColumn.implicitHeight + root.pad * 2

    function focusTable() {
        tableFocus.forceActiveFocus();
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

    function computeVisibleProcesses() {
        var source = (ProcessService.processes || []).slice();
        var filtered = [];
        for (var i = 0; i < source.length; ++i) {
            var process = source[i];
            if (!matchesQuery(process) || !matchesState(process))
                continue;
            filtered.push(process);
        }
        filtered.sort(compareProcesses);
        return filtered.slice(0, maxRows);
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

    function syncSelection() {
        if (visibleProcesses.length === 0) {
            selectedPid = 0;
            return;
        }
        if (!findProcessByPid(selectedPid))
            selectedPid = visibleProcesses[0].pid || 0;
    }

    function headerLabel(label, field) {
        if (sortField !== field)
            return label;
        return label + (sortDescending ? " ▼" : " ▲");
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

    onVisibleProcessesChanged: syncSelection()
    Component.onCompleted: syncSelection()

    FocusScope {
        id: tableFocus
        Layout.fillWidth: true
        activeFocusOnTab: true

        Keys.onUpPressed: event => {
            root.moveSelection(-1);
            event.accepted = true;
        }
        Keys.onDownPressed: event => {
            root.moveSelection(1);
            event.accepted = true;
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
            if (event.key === Qt.Key_R) {
                ProcessService.refresh();
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
            if (event.key === Qt.Key_I || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                ProcessService.openProcessInTerminal(root.selectedPid);
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: processColumn
            anchors.fill: parent
            spacing: Colors.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    text: "PROCESS TABLE"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                    font.letterSpacing: Colors.letterSpacingWide
                }

                Item {
                    Layout.fillWidth: true
                }

                SharedWidgets.Chip {
                    icon: keyboardFocused ? "󰌌" : "󰍉"
                    iconColor: keyboardFocused ? Colors.primary : Colors.textSecondary
                    text: keyboardFocused ? "Arrows/J/K active" : (String(visibleProcesses.length) + " rows")
                    textColor: keyboardFocused ? Colors.primary : Colors.textSecondary
                }

                SharedWidgets.IconButton {
                    icon: "󰑐"
                    size: 28
                    iconSize: Colors.fontSizeSmall
                    iconColor: Colors.textSecondary
                    onClicked: ProcessService.refresh()
                }
            }

            SharedWidgets.SearchBar {
                placeholder: "Search PID, user, name, or command..."
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

            Rectangle {
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.55)
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

                        Repeater {
                            model: [
                                { key: "pid", label: "PID", width: 72 },
                                { key: "user", label: "USER", width: 104 },
                                { key: "name", label: "PROCESS", fill: true },
                                { key: "cpu", label: "CPU%", width: 74 },
                                { key: "mem", label: "MEM%", width: 74 },
                                { key: "elapsed", label: "TIME", width: 92 },
                                { key: "state", label: "STATE", width: 70 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.preferredWidth: modelData.width || 120
                                Layout.fillWidth: !!modelData.fill
                                Layout.alignment: Qt.AlignVCenter
                                color: "transparent"
                                implicitHeight: headerText.implicitHeight + 8

                                Text {
                                    id: headerText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.headerLabel(modelData.label, modelData.key)
                                    color: root.sortField === modelData.key ? Colors.primary : Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                    horizontalAlignment: modelData.key === "name" ? Text.AlignLeft : Text.AlignRight
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
                    icon: "󰍉"
                    message: root.trimmedSearch === "" ? "No processes matched the current filter." : "No processes matched the current search."
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: root.visibleProcesses.length > 0

                    Repeater {
                        model: root.visibleProcesses

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool selected: (modelData.pid || 0) === root.selectedPid
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
                                    Layout.preferredWidth: 72
                                    text: String(modelData.pid || 0)
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    font.family: Colors.fontMono
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 104
                                    text: String(modelData.user || "")
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: String(modelData.name || "process")
                                    color: selected ? Colors.text : Colors.text
                                    font.pixelSize: Colors.fontSizeXS
                                    font.weight: selected ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.preferredWidth: 74
                                    text: Number(modelData.cpu || 0).toFixed(1)
                                    color: Number(modelData.cpu || 0) >= 20 ? Colors.primary : Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    font.family: Colors.fontMono
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 74
                                    text: Number(modelData.mem || 0).toFixed(1)
                                    color: Number(modelData.mem || 0) >= 10 ? Colors.accent : Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    font.family: Colors.fontMono
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 92
                                    text: String(modelData.elapsed || "--:--")
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    font.family: Colors.fontMono
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 70
                                    text: String(modelData.state || "")
                                    color: String(modelData.state || "").indexOf("T") !== -1 ? Colors.warning : Colors.secondary
                                    font.pixelSize: Colors.fontSizeXS
                                    font.family: Colors.fontMono
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
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: !!root.selectedProcess
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXXS

                        Text {
                            text: root.selectedProcess ? String(root.selectedProcess.name || "process") : ""
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: root.selectedProcess ? ("PID " + String(root.selectedProcess.pid || 0) + "  •  " + String(root.selectedProcess.user || "user")) : ""
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXS
                            font.family: Colors.fontMono
                        }
                    }

                    Text {
                        text: root.pendingAction !== "" ? ("PENDING  " + root.pendingAction.toUpperCase()) : "READY"
                        color: root.pendingAction !== "" ? Colors.warning : Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.Bold
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    SharedWidgets.Chip {
                        icon: ""
                        iconColor: Colors.primary
                        text: "CPU " + Number(root.selectedProcess ? root.selectedProcess.cpu : 0).toFixed(1) + "%"
                        textColor: Colors.primary
                    }

                    SharedWidgets.Chip {
                        icon: "󰍛"
                        iconColor: Colors.accent
                        text: "RAM " + Number(root.selectedProcess ? root.selectedProcess.mem : 0).toFixed(1) + "%"
                        textColor: Colors.accent
                    }

                    SharedWidgets.Chip {
                        icon: "󰥔"
                        iconColor: Colors.secondary
                        text: root.selectedProcess ? String(root.selectedProcess.elapsed || "--:--") : ""
                        textColor: Colors.secondary
                    }

                    SharedWidgets.Chip {
                        icon: "󰈈"
                        iconColor: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? Colors.warning : Colors.textSecondary
                        text: root.selectedProcess ? ("STATE " + String(root.selectedProcess.state || "?")) : ""
                        textColor: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? Colors.warning : Colors.textSecondary
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
                        label: "Copy Cmd"
                        icon: "󰅍"
                        enabled: !ProcessService.isPidPending(root.selectedPid)
                        selected: false
                        onClicked: ProcessService.copyCommand(root.selectedPid)
                    }
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
