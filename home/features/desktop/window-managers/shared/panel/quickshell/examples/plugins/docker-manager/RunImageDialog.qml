import QtQuick

Rectangle {
    id: root

    property var daemon: null
    property string imageName: ""
    property string containerName: ""
    property string hostPort: ""
    property string containerPort: ""
    property string portStatus: ""

    signal closeRequested()

    visible: imageName !== ""
    width: parent ? parent.width : 400
    radius: 14
    color: "#1e293b"
    border.width: 1
    border.color: "#38bdf8"
    implicitHeight: dialogColumn.implicitHeight + 24

    Column {
        id: dialogColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text { text: "Run Image"; color: "#f8fafc"; font.pixelSize: 14; font.bold: true }
        Text { text: "Image: " + root.imageName; color: "#94a3b8"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }

        Text {
            visible: root.daemon && root.daemon.pullInProgress
            text: root.daemon ? root.daemon.pullStatus : ""; color: "#38bdf8"; font.pixelSize: 10
            wrapMode: Text.WrapAnywhere; width: parent.width
        }

        Row {
            width: parent.width; spacing: 6
            Text { text: "Name:"; color: "#e2e8f0"; font.pixelSize: 11; width: 50; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                width: parent.width - 56; height: 28; radius: 8; color: "#0f172a"; border.width: 1; border.color: "#475569"
                TextInput {
                    id: nameInput; anchors.fill: parent; anchors.margins: 6; color: "#f8fafc"; font.pixelSize: 11
                    text: root.containerName; onTextChanged: root.containerName = text
                    activeFocusOnTab: true; KeyNavigation.tab: hostPortInput
                }
            }
        }

        Row {
            width: parent.width; spacing: 6
            Text { text: "Host:"; color: "#e2e8f0"; font.pixelSize: 11; width: 50; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                width: 80; height: 28; radius: 8; color: "#0f172a"; border.width: 1; border.color: "#475569"
                TextInput {
                    id: hostPortInput; anchors.fill: parent; anchors.margins: 6; color: "#f8fafc"; font.pixelSize: 11
                    text: root.hostPort; onTextChanged: root.hostPort = text
                    activeFocusOnTab: true; KeyNavigation.tab: containerPortInput; KeyNavigation.backtab: nameInput
                }
            }
            Text { text: ":"; color: "#94a3b8"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
            Rectangle {
                width: 80; height: 28; radius: 8; color: "#0f172a"; border.width: 1; border.color: "#475569"
                TextInput {
                    id: containerPortInput; anchors.fill: parent; anchors.margins: 6; color: "#f8fafc"; font.pixelSize: 11
                    text: root.containerPort; onTextChanged: root.containerPort = text
                    activeFocusOnTab: true; KeyNavigation.backtab: hostPortInput
                }
            }
            Rectangle {
                width: 60; height: 28; radius: 8; color: "#0f172a"; border.width: 1; border.color: "#475569"
                Text { anchors.centerIn: parent; text: "Check"; color: "#93c5fd"; font.pixelSize: 10; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.daemon) {
                            root.portStatus = "...";
                            root.daemon.checkPortAvailable(Number(root.hostPort) || 0, function(available) {
                                root.portStatus = available ? "Free" : "In use";
                            });
                        }
                    }
                }
            }
        }

        Text {
            visible: root.portStatus !== ""
            text: "Port status: " + root.portStatus
            color: root.portStatus === "Free" ? "#5eead4" : (root.portStatus === "In use" ? "#f87171" : "#94a3b8")
            font.pixelSize: 10
        }

        Row {
            width: parent.width; spacing: 6
            Rectangle {
                width: Math.floor((parent.width - 6) / 2); height: 30; radius: 10
                color: (root.daemon && root.daemon.pullInProgress) ? "#334155" : "#1d4ed8"
                opacity: (root.daemon && root.daemon.pullInProgress) ? 0.6 : 1
                border.width: 1; border.color: "#93c5fd"
                Text { anchors.centerIn: parent; text: (root.daemon && root.daemon.pullInProgress) ? "Pulling..." : "Run"; color: "#f8fafc"; font.pixelSize: 11; font.bold: true }
                MouseArea {
                    anchors.fill: parent; enabled: !(root.daemon && root.daemon.pullInProgress)
                    onClicked: { if (root.daemon) root.daemon.runImage(root.imageName, root.containerName, root.hostPort, root.containerPort); }
                }
            }
            Rectangle {
                width: Math.floor((parent.width - 6) / 2); height: 30; radius: 10
                color: "#1e293b"; border.width: 1; border.color: "#475569"
                Text { anchors.centerIn: parent; text: "Cancel"; color: "#f8fafc"; font.pixelSize: 11; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.closeRequested() }
            }
        }
    }
}
