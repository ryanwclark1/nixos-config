import QtQuick

Rectangle {
    id: root

    property string currentTab: "containers"
    property int selectedCount: 0

    signal bulkActionRequested(string action)

    visible: selectedCount > 0
    width: parent ? parent.width : 400
    height: 36
    radius: 10
    color: "#1e293b"
    border.width: 1
    border.color: "#475569"

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: root.selectedCount + " selected"
            color: "#94a3b8"; font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: {
                if (root.currentTab === "containers")
                    return [{ label: "Stop Selected", action: "stop" }, { label: "Restart Selected", action: "restart" }];
                if (root.currentTab === "images")
                    return [{ label: "Remove Selected", action: "remove" }];
                if (root.currentTab === "volumes")
                    return [{ label: "Remove Selected", action: "remove" }];
                if (root.currentTab === "networks")
                    return [{ label: "Remove Selected", action: "remove" }];
                return [];
            }
            delegate: Rectangle {
                id: bulkBtn; required property var modelData
                width: bulkLabel.implicitWidth + 16; height: 26; radius: 8
                color: "#3f1d24"; border.width: 1; border.color: "#f87171"
                Text { id: bulkLabel; anchors.centerIn: parent; text: bulkBtn.modelData.label; color: "#fca5a5"; font.pixelSize: 10; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.bulkActionRequested(bulkBtn.modelData.action) }
            }
        }
    }
}
