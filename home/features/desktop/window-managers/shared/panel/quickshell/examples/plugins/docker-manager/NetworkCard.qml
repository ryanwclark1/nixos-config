pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root

    required property var modelData
    required property int index
    property var daemon: null
    property bool selectionMode: false
    property var selectedMap: ({})
    property bool isFocused: false
    readonly property var usedBy: daemon && daemon.networkUsageMap[modelData.name] ? daemon.networkUsageMap[modelData.name] : []
    readonly property bool isProtected: modelData.isDefault || usedBy.length > 0

    signal selectionToggled(string key)

    width: parent ? parent.width : 400
    radius: 14
    color: "#111827"
    border.width: isFocused ? 2 : 1
    border.color: isFocused ? "#93c5fd" : "#334155"
    implicitHeight: bodyColumn.implicitHeight + 18

    Column {
        id: bodyColumn
        anchors.fill: parent
        anchors.margins: 9
        spacing: 4

        Row {
            width: parent.width; spacing: 8

            Rectangle {
                visible: root.selectionMode
                width: 20; height: 20; radius: 4
                color: root.selectedMap[root.modelData.name] ? "#1d4ed8" : "#1e293b"
                border.width: 1; border.color: root.selectedMap[root.modelData.name] ? "#93c5fd" : "#475569"
                anchors.verticalCenter: parent.verticalCenter
                Text { visible: root.selectedMap[root.modelData.name] === true; anchors.centerIn: parent; text: "\u2713"; color: "#f8fafc"; font.pixelSize: 12; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.selectionToggled(root.modelData.name) }
            }

            Column {
                width: Math.max(120, parent.width - 76 - (root.selectionMode ? 28 : 0))
                spacing: 2

                Text { text: root.modelData.name; color: "#f8fafc"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; width: parent.width }
                Row {
                    spacing: 8
                    Text { text: "Driver: " + root.modelData.driver; color: "#94a3b8"; font.pixelSize: 11 }
                    Text { visible: root.modelData.scope !== ""; text: "Scope: " + root.modelData.scope; color: "#94a3b8"; font.pixelSize: 11 }
                }
                Rectangle {
                    visible: root.modelData.isDefault; height: 20; radius: 10
                    width: defaultLabel.implicitWidth + 14; color: "#1c1917"; border.width: 1; border.color: "#78716c"
                    Text { id: defaultLabel; anchors.centerIn: parent; text: "Default"; color: "#a8a29e"; font.pixelSize: 9 }
                }
                Text { visible: root.usedBy.length > 0; text: "Used by: " + root.usedBy.join(", "); color: "#93c5fd"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
            }

            Rectangle {
                width: 58; height: 28; radius: 10
                color: root.isProtected ? "#111827" : "#3f1d24"
                opacity: root.isProtected ? 0.45 : 1
                border.width: 1; border.color: root.isProtected ? "#475569" : "#f87171"
                Text { anchors.centerIn: parent; text: "Del"; color: root.isProtected ? "#94a3b8" : "#fca5a5"; font.pixelSize: 10; font.bold: true }
                MouseArea { anchors.fill: parent; enabled: !root.isProtected; onClicked: { if (root.daemon) root.daemon.removeNetwork(root.modelData.name); } }
            }
        }
    }
}
