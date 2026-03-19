pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root

    required property var modelData
    required property int index
    property var daemon: null
    property bool selectionMode: false
    property var selectedMap: ({})
    property bool showPorts: true
    property bool isFocused: false

    readonly property bool expanded: _expandedMap[modelData.id] === true
    property var _expandedMap: ({})

    signal toggleExpanded(string key)
    signal selectionToggled(string key)
    signal ensureVisibleRequested(real itemY, real itemHeight)

    width: parent ? parent.width : 400
    radius: 14
    color: "#111827"
    border.width: isFocused ? 2 : 1
    border.color: isFocused ? "#93c5fd" : (expanded ? "#38bdf8" : "#334155")
    implicitHeight: bodyColumn.implicitHeight + 18

    function _healthDot(status) {
        if (status === "healthy" || status === "starting" || status === "unhealthy") return "\u25CF ";
        return "";
    }
    function _healthDotColor(status) {
        if (status === "healthy") return "#5eead4";
        if (status === "starting") return "#fcd34d";
        if (status === "unhealthy") return "#f87171";
        return "transparent";
    }
    function _actionLabel() {
        return modelData && modelData.isRunning ? "Restart" : "Start";
    }

    Column {
        id: bodyColumn
        anchors.fill: parent
        anchors.margins: 9
        spacing: 8

        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                visible: root.selectionMode
                width: 20; height: 20; radius: 4
                color: root.selectedMap[root.modelData.id] ? "#1d4ed8" : "#1e293b"
                border.width: 1
                border.color: root.selectedMap[root.modelData.id] ? "#93c5fd" : "#475569"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    visible: root.selectedMap[root.modelData.id] === true
                    anchors.centerIn: parent; text: "\u2713"; color: "#f8fafc"; font.pixelSize: 12; font.bold: true
                }
                MouseArea { anchors.fill: parent; onClicked: root.selectionToggled(root.modelData.id) }
            }

            Column {
                width: Math.max(120, parent.width - 76 - (root.selectionMode ? 28 : 0))
                spacing: 2

                Text {
                    text: root.modelData.name || root.modelData.id
                    color: "#f8fafc"; font.pixelSize: 13; font.bold: true
                    elide: Text.ElideRight; width: parent.width
                }
                Text {
                    text: root.modelData.image || ""
                    color: "#94a3b8"; font.pixelSize: 11
                    elide: Text.ElideRight; width: parent.width
                }
                Row {
                    spacing: 2
                    Text {
                        visible: root.modelData.healthStatus !== ""
                        text: root._healthDot(root.modelData.healthStatus)
                        color: root._healthDotColor(root.modelData.healthStatus)
                        font.pixelSize: 11
                    }
                    Text {
                        text: root.modelData.status || root.modelData.state || ""
                        color: root.modelData.isRunning ? "#5eead4" : (root.modelData.isPaused ? "#fcd34d" : "#cbd5e1")
                        font.pixelSize: 11
                    }
                }
                Row {
                    visible: root.modelData.isRunning && root.daemon && root.daemon.containerStats[root.modelData.id] !== undefined
                    spacing: 10
                    Text {
                        text: "CPU: " + (root.daemon && root.daemon.containerStats[root.modelData.id] ? root.daemon.containerStats[root.modelData.id].cpuPercent : "")
                        color: "#94a3b8"; font.pixelSize: 10
                    }
                    Text {
                        text: "Mem: " + (root.daemon && root.daemon.containerStats[root.modelData.id] ? root.daemon.containerStats[root.modelData.id].memUsage : "")
                        color: "#94a3b8"; font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                width: 58; height: 28; radius: 10
                color: root.expanded ? "#0f172a" : "#1e293b"
                border.width: 1; border.color: "#475569"
                Text { anchors.centerIn: parent; text: root.expanded ? "Hide" : "Show"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.toggleExpanded(root.modelData.id);
                        if (!root.expanded) {
                            root.ensureVisibleRequested(root.y, root.height + 120);
                            if (root.daemon && root.daemon.fetchLogs)
                                root.daemon.fetchLogs(root.modelData.id);
                        }
                    }
                }
            }
        }

        Flow {
            visible: root.expanded && root.showPorts && root.modelData.ports && root.modelData.ports.length > 0
            width: parent.width; spacing: 6
            Repeater {
                model: root.modelData.ports
                delegate: Rectangle {
                    id: portChip; required property var modelData
                    height: 24; radius: 12; color: "#0f2238"; border.width: 1; border.color: "#1d4ed8"
                    width: portLabel.implicitWidth + 18
                    Text { id: portLabel; anchors.centerIn: parent; text: portChip.modelData.hostPort + " -> " + String(portChip.modelData.containerPort || "").replace(/\/(tcp|udp)$/, ""); color: "#bfdbfe"; font.pixelSize: 10 }
                }
            }
        }

        Rectangle {
            visible: root.expanded && root.daemon && root.daemon.containerLogs[root.modelData.id] !== undefined
            width: parent.width; radius: 8; color: "#020617"; border.width: 1; border.color: "#1e293b"
            implicitHeight: Math.min(logText.implicitHeight + 12, 160); clip: true
            Text {
                id: logText; anchors.fill: parent; anchors.margins: 6; wrapMode: Text.WrapAnywhere
                text: root.daemon && root.daemon.containerLogs[root.modelData.id] ? root.daemon.containerLogs[root.modelData.id] : ""
                color: "#94a3b8"; font.pixelSize: 9; font.family: "monospace"
            }
        }

        Column {
            visible: root.expanded; width: parent.width; spacing: 6

            Row {
                width: parent.width; spacing: 6
                Repeater {
                    model: [
                        { label: root._actionLabel(), enabled: root.modelData.isPaused !== true, action: function() { root.daemon.executeContainerAction(root.modelData.id || root.modelData.name, root.modelData.isRunning ? "restart" : "start"); } },
                        { label: root.modelData.isPaused ? "Unpause" : "Pause", enabled: root.modelData.isRunning || root.modelData.isPaused, action: function() { root.daemon.executeContainerAction(root.modelData.id || root.modelData.name, root.modelData.isPaused ? "unpause" : "pause"); } },
                        { label: "Stop", enabled: root.modelData.isRunning || root.modelData.isPaused, action: function() { root.daemon.executeContainerAction(root.modelData.id || root.modelData.name, "stop"); } }
                    ]
                    delegate: Rectangle {
                        id: actionBtn; required property var modelData
                        width: Math.floor((parent.width - 12) / 3); height: 30; radius: 10
                        color: actionBtn.modelData.enabled ? "#1e293b" : "#111827"; opacity: actionBtn.modelData.enabled ? 1 : 0.45
                        border.width: 1; border.color: "#475569"
                        Text { anchors.centerIn: parent; text: actionBtn.modelData.label; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                        MouseArea { anchors.fill: parent; enabled: parent.opacity >= 1; onClicked: actionBtn.modelData.action() }
                    }
                }
            }

            Row {
                width: parent.width; spacing: 6
                Rectangle {
                    width: Math.floor((parent.width - 6) / 2); height: 30; radius: 10
                    color: root.modelData.isRunning ? "#1e293b" : "#111827"; opacity: root.modelData.isRunning ? 1 : 0.45
                    border.width: 1; border.color: "#475569"
                    Text { anchors.centerIn: parent; text: "Shell"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                    MouseArea { anchors.fill: parent; enabled: root.modelData.isRunning; onClicked: root.daemon.openShell(root.modelData.id || root.modelData.name) }
                }
                Rectangle {
                    width: Math.floor((parent.width - 6) / 2); height: 30; radius: 10
                    color: "#1e293b"; border.width: 1; border.color: "#475569"
                    Text { anchors.centerIn: parent; text: "Full Logs"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: root.daemon.openLogs(root.modelData.id || root.modelData.name) }
                }
            }

            Rectangle {
                visible: !root.modelData.isRunning && !root.modelData.isPaused
                width: parent.width; height: 30; radius: 10; color: "#3f1d24"; border.width: 1; border.color: "#f87171"
                Text { anchors.centerIn: parent; text: "Remove Container"; color: "#fca5a5"; font.pixelSize: 10; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: { if (root.daemon) root.daemon.removeContainer(root.modelData.id || root.modelData.name); } }
            }
        }
    }
}
