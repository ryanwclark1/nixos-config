pragma ComponentBehavior: Bound
import QtQuick
import "DockerUtils.js" as DU

Rectangle {
    id: root

    required property var modelData
    required property int index
    property var daemon: null
    property bool isFocused: false
    readonly property bool expanded: _expandedMap[modelData.name] === true
    property var _expandedMap: ({})

    signal toggleExpanded(string key)
    signal ensureVisibleRequested(real itemY, real itemHeight)

    width: parent ? parent.width : 400
    radius: 14
    color: "#111827"
    border.width: isFocused ? 2 : 1
    border.color: isFocused ? "#93c5fd" : (expanded ? "#38bdf8" : "#334155")
    implicitHeight: projectColumn.implicitHeight + 18

    Column {
        id: projectColumn
        anchors.fill: parent; anchors.margins: 9; spacing: 8

        Row {
            width: parent.width; spacing: 8
            Column {
                width: Math.max(120, parent.width - 76); spacing: 2
                Text { text: root.modelData.name; color: "#f8fafc"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; width: parent.width }
                Text { text: root.modelData.runningCount + " / " + root.modelData.totalCount + " running"; color: "#94a3b8"; font.pixelSize: 11 }
            }
            Rectangle {
                width: 58; height: 28; radius: 10
                color: root.expanded ? "#0f172a" : "#1e293b"; border.width: 1; border.color: "#475569"
                Text { anchors.centerIn: parent; text: root.expanded ? "Hide" : "Show"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.toggleExpanded(root.modelData.name);
                        if (!root.expanded)
                            root.ensureVisibleRequested(root.y, root.height + 160);
                    }
                }
            }
        }

        Column {
            visible: root.expanded; width: parent.width; spacing: 6

            Row {
                width: parent.width; spacing: 6
                Repeater {
                    model: [
                        { label: "Start", enabled: root.modelData.runningCount < root.modelData.totalCount, action: function() { root.daemon.executeComposeAction(root.modelData, "start"); } },
                        { label: "Restart", enabled: root.modelData.runningCount > 0, action: function() { root.daemon.executeComposeAction(root.modelData, "restart"); } },
                        { label: "Stop", enabled: root.modelData.runningCount > 0, action: function() { root.daemon.executeComposeAction(root.modelData, "stop"); } }
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
                Repeater {
                    model: [
                        { label: "Pull", action: function() { root.daemon.executeComposeAction(root.modelData, "pull"); } },
                        { label: "Logs", action: function() { root.daemon.executeComposeAction(root.modelData, "logs"); } },
                        { label: "Edit", action: function() { root.daemon.executeComposeAction(root.modelData, "edit"); } }
                    ]
                    delegate: Rectangle {
                        id: secBtn; required property var modelData
                        width: Math.floor((parent.width - 12) / 3); height: 30; radius: 10
                        color: "#1e293b"; border.width: 1; border.color: "#475569"
                        Text { anchors.centerIn: parent; text: secBtn.modelData.label; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: secBtn.modelData.action() }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#1e293b" }

            Repeater {
                model: root.modelData.containers
                delegate: Rectangle {
                    id: childCard; required property var modelData
                    width: parent.width; radius: 12; color: "#0f172a"; border.width: 1; border.color: "#1e293b"
                    implicitHeight: childCol.implicitHeight + 14
                    Column {
                        id: childCol; anchors.fill: parent; anchors.margins: 7; spacing: 4
                        Text { text: childCard.modelData.composeService || childCard.modelData.name || childCard.modelData.id; color: "#f8fafc"; font.pixelSize: 12; font.bold: true }
                        Row {
                            spacing: 2
                            Text { visible: childCard.modelData.healthStatus !== ""; text: DU.healthDot(childCard.modelData.healthStatus); color: DU.healthDotColor(childCard.modelData.healthStatus); font.pixelSize: 10 }
                            Text { text: childCard.modelData.status || childCard.modelData.state || ""; color: childCard.modelData.isRunning ? "#5eead4" : (childCard.modelData.isPaused ? "#fcd34d" : "#cbd5e1"); font.pixelSize: 10 }
                        }
                    }
                }
            }
        }
    }
}
