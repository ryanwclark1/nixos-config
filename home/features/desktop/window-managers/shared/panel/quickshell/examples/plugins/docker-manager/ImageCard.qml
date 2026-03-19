pragma ComponentBehavior: Bound
import QtQuick
import "DockerUtils.js" as DU

Rectangle {
    id: root

    required property var modelData
    required property int index
    property var daemon: null
    property bool selectionMode: false
    property var selectedMap: ({})
    property bool isFocused: false
    readonly property bool expanded: _expandedMap[modelData.id] === true
    property var _expandedMap: ({})

    signal toggleExpanded(string key)
    signal selectionToggled(string key)
    signal ensureVisibleRequested(real itemY, real itemHeight)
    signal runRequested(string imageName)

    width: parent ? parent.width : 400
    radius: 14
    color: "#111827"
    border.width: isFocused ? 2 : 1
    border.color: isFocused ? "#93c5fd" : (expanded ? "#38bdf8" : "#334155")
    implicitHeight: bodyColumn.implicitHeight + 18

    Column {
        id: bodyColumn
        anchors.fill: parent
        anchors.margins: 9
        spacing: 6

        Row {
            width: parent.width; spacing: 8

            Rectangle {
                visible: root.selectionMode
                width: 20; height: 20; radius: 4
                color: root.selectedMap[root.modelData.id] ? "#1d4ed8" : "#1e293b"
                border.width: 1; border.color: root.selectedMap[root.modelData.id] ? "#93c5fd" : "#475569"
                anchors.verticalCenter: parent.verticalCenter
                Text { visible: root.selectedMap[root.modelData.id] === true; anchors.centerIn: parent; text: "\u2713"; color: "#f8fafc"; font.pixelSize: 12; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.selectionToggled(root.modelData.id) }
            }

            Column {
                width: Math.max(120, parent.width - 76 - (root.selectionMode ? 28 : 0))
                spacing: 2

                Text {
                    text: root.modelData.repo + (root.modelData.tag && root.modelData.tag !== "<none>" ? ":" + root.modelData.tag : "")
                    color: "#f8fafc"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; width: parent.width
                }
                Row {
                    spacing: 8
                    Text { text: root.modelData.size ? DU.formatBytes(root.modelData.size) : ""; color: "#94a3b8"; font.pixelSize: 11; visible: text !== "" }
                    Text { text: root.modelData.created || ""; color: "#94a3b8"; font.pixelSize: 11; visible: text !== "" }
                }
                Rectangle {
                    height: 20; radius: 10; width: inUseLabel.implicitWidth + 14
                    color: root.modelData.inUse ? "#0f2238" : "#1c1917"; border.width: 1
                    border.color: root.modelData.inUse ? "#1d4ed8" : "#78716c"
                    Text { id: inUseLabel; anchors.centerIn: parent; text: root.modelData.inUse ? "In use" : "Unused"; color: root.modelData.inUse ? "#93c5fd" : "#a8a29e"; font.pixelSize: 9 }
                }
            }

            Rectangle {
                width: 58; height: 28; radius: 10
                color: root.expanded ? "#0f172a" : "#1e293b"; border.width: 1; border.color: "#475569"
                Text { anchors.centerIn: parent; text: root.expanded ? "Hide" : "Show"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.toggleExpanded(root.modelData.id);
                        if (!root.expanded) root.ensureVisibleRequested(root.y, root.height + 80);
                    }
                }
            }
        }

        Column {
            visible: root.expanded; width: parent.width; spacing: 6

            Text { text: "ID: " + (root.modelData.id || "").slice(0, 20); color: "#64748b"; font.pixelSize: 10 }

            Row {
                width: parent.width; spacing: 6
                Rectangle {
                    width: Math.floor((parent.width - 6) / 2); height: 30; radius: 10
                    color: "#1e293b"; border.width: 1; border.color: "#475569"
                    Text { anchors.centerIn: parent; text: "Run"; color: "#f8fafc"; font.pixelSize: 10; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var ref = root.modelData.repo;
                            if (root.modelData.tag && root.modelData.tag !== "<none>") ref += ":" + root.modelData.tag;
                            root.runRequested(ref);
                        }
                    }
                }
                Rectangle {
                    width: Math.floor((parent.width - 6) / 2); height: 30; radius: 10
                    color: root.modelData.inUse ? "#111827" : "#3f1d24"; opacity: root.modelData.inUse ? 0.45 : 1
                    border.width: 1; border.color: root.modelData.inUse ? "#475569" : "#f87171"
                    Text { anchors.centerIn: parent; text: "Remove"; color: root.modelData.inUse ? "#94a3b8" : "#fca5a5"; font.pixelSize: 10; font.bold: true }
                    MouseArea { anchors.fill: parent; enabled: !root.modelData.inUse; onClicked: { if (root.daemon) root.daemon.removeImage(root.modelData.id); } }
                }
            }
        }
    }
}
