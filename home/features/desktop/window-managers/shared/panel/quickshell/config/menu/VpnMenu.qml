import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
    id: root
    popupMinWidth: 340
    popupMaxWidth: 396
    compactThreshold: 420
    implicitHeight: compactMode ? 620 : 560
    title: "VPN Hub"
    subtitle: NetworkService.vpnPrimaryLabel + " • " + NetworkService.vpnStatusLabel(NetworkService.vpnPrimaryStatus)
    toggleMethod: "toggleVpnMenu"

    function statusColor(statusKey) {
        if (statusKey === "connected")
            return Colors.success;
        if (statusKey === "stopped")
            return Colors.warning;
        if (statusKey === "disconnected")
            return Colors.textSecondary;
        return Colors.textDisabled;
    }

    function openNetworkMenu() {
        root.closeRequested();
        Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleNetworkMenu"]);
    }

    function otherVpnChipText() {
        if (NetworkService.vpnOtherCount <= 0)
            return "";
        return NetworkService.vpnOtherCount === 1 ? "1 active profile" : NetworkService.vpnOtherCount + " active profiles";
    }

    function savedVpnChipText() {
        if (!NetworkService.vpnHasSavedProfiles)
            return "";
        return NetworkService.vpnProfileCount === 1 ? "1 saved profile" : NetworkService.vpnProfileCount + " saved profiles";
    }

    SharedWidgets.Ref {
        service: NetworkService
        active: root.visible
    }

    onVisibleChanged: {
        if (visible)
            NetworkService.refreshData();
    }

    headerExtras: [
        SharedWidgets.IconButton {
            icon: "󰑐"
            onClicked: NetworkService.refreshData()
        },
        SharedWidgets.IconButton {
            icon: "󰖩"
            onClicked: root.openNetworkMenu()
        }
    ]

    SharedWidgets.ScrollableContent {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: Colors.spacingM

        Rectangle {
            Layout.fillWidth: true
            radius: Colors.radiusLarge
            color: Colors.withAlpha(Colors.surface, 0.38)
            border.color: Colors.withAlpha(root.statusColor(NetworkService.vpnPrimaryStatus), 0.45)
            border.width: 1
            implicitHeight: root.compactMode ? 136 : 118

            gradient: SharedWidgets.SurfaceGradient {}
            SharedWidgets.InnerHighlight {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    Text {
                        text: "󰖂"
                        color: root.statusColor(NetworkService.vpnPrimaryStatus)
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeHuge
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: NetworkService.vpnPrimaryLabel
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeLarge
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: NetworkService.vpnPrimaryDetail
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        radius: Colors.radiusPill
                        color: Colors.withAlpha(root.statusColor(NetworkService.vpnPrimaryStatus), 0.14)
                        border.color: Colors.withAlpha(root.statusColor(NetworkService.vpnPrimaryStatus), 0.38)
                        border.width: 1
                        implicitHeight: 26
                        implicitWidth: statusChipLabel.implicitWidth + 18

                        Text {
                            id: statusChipLabel
                            anchors.centerIn: parent
                            text: NetworkService.vpnStatusLabel(NetworkService.vpnPrimaryStatus)
                            color: root.statusColor(NetworkService.vpnPrimaryStatus)
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    Rectangle {
                        visible: NetworkService.tailscaleIp !== ""
                        radius: Colors.radiusPill
                        color: Colors.chipSurface
                        border.color: Colors.border
                        border.width: 1
                        implicitHeight: 24
                        implicitWidth: tsIpLabel.implicitWidth + 18

                        Text {
                            id: tsIpLabel
                            anchors.centerIn: parent
                            text: NetworkService.tailscaleIp
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        visible: NetworkService.vpnOtherCount > 0
                        radius: Colors.radiusPill
                        color: Colors.chipSurface
                        border.color: Colors.border
                        border.width: 1
                        implicitHeight: 24
                        implicitWidth: otherCountLabel.implicitWidth + 18

                        Text {
                            id: otherCountLabel
                            anchors.centerIn: parent
                            text: root.otherVpnChipText()
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        visible: NetworkService.vpnHasSavedProfiles
                        radius: Colors.radiusPill
                        color: Colors.chipSurface
                        border.color: Colors.border
                        border.width: 1
                        implicitHeight: 24
                        implicitWidth: savedCountLabel.implicitWidth + 18

                        Text {
                            id: savedCountLabel
                            anchors.centerIn: parent
                            text: root.savedVpnChipText()
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        visible: NetworkService.routeDevice !== ""
                        radius: Colors.radiusPill
                        color: Colors.chipSurface
                        border.color: Colors.border
                        border.width: 1
                        implicitHeight: 24
                        implicitWidth: routeLabel.implicitWidth + 18

                        Text {
                            id: routeLabel
                            anchors.centerIn: parent
                            text: "Route " + NetworkService.routeDevice
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.Medium
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Colors.radiusMedium
                    color: NetworkService.vpnPrimaryStatus === "connected"
                        ? Colors.withAlpha(Colors.error, 0.14)
                        : Colors.withAlpha(Colors.primary, 0.16)
                    border.color: NetworkService.vpnPrimaryStatus === "connected" ? Colors.error : Colors.primary
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: NetworkService.vpnPrimaryStatus === "connected" ? "Disconnect Tailscale" : "Connect Tailscale"
                        color: NetworkService.vpnPrimaryStatus === "connected" ? Colors.error : Colors.primary
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: NetworkService.tailscaleInstalled
                        onClicked: {
                            if (NetworkService.vpnPrimaryStatus === "connected")
                                NetworkService.tailscaleDown();
                            else
                                NetworkService.tailscaleUp();
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS
            visible: NetworkService.vpnOtherCount > 0

            SharedWidgets.SectionLabel { label: "Active VPN Profiles" }

            Repeater {
                model: NetworkService.vpnActiveProfiles

                delegate: Rectangle {
                    Layout.fillWidth: true
                    required property var modelData
                    readonly property bool actionPending: NetworkService.pendingVpnProfileUuid === String(modelData.uuid || "")
                    implicitHeight: 60
                    radius: Colors.radiusMedium
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Colors.spacingM
                        spacing: Colors.spacingS

                        Text {
                            text: "󰖂"
                            color: Colors.accent
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeLarge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: modelData.name || "VPN"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.device !== "" ? (modelData.type + " • " + modelData.device) : modelData.type
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            radius: Colors.radiusPill
                            color: actionPending
                                ? Colors.withAlpha(Colors.textSecondary, 0.12)
                                : Colors.withAlpha(Colors.error, 0.12)
                            border.color: actionPending ? Colors.border : Colors.error
                            border.width: 1
                            implicitHeight: 24
                            implicitWidth: otherStateLabel.implicitWidth + 18

                            Text {
                                id: otherStateLabel
                                anchors.centerIn: parent
                                text: actionPending ? "Disconnecting" : "Disconnect"
                                color: actionPending ? Colors.textSecondary : Colors.error
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !actionPending && NetworkService.pendingVpnProfileUuid === ""
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.BusyCursor
                                onClicked: NetworkService.disconnectVpnProfile(modelData.uuid)
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS
            visible: NetworkService.vpnInactiveCount > 0

            SharedWidgets.SectionLabel { label: "Available VPN Profiles" }

            Repeater {
                model: NetworkService.vpnInactiveProfiles

                delegate: Rectangle {
                    Layout.fillWidth: true
                    required property var modelData
                    readonly property bool actionPending: NetworkService.pendingVpnProfileUuid === String(modelData.uuid || "")
                    implicitHeight: 60
                    radius: Colors.radiusMedium
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Colors.spacingM
                        spacing: Colors.spacingS

                        Text {
                            text: "󰖂"
                            color: Colors.textSecondary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeLarge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: modelData.name || "VPN"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.type || "vpn"
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            radius: Colors.radiusPill
                            color: actionPending
                                ? Colors.withAlpha(Colors.textSecondary, 0.12)
                                : Colors.withAlpha(Colors.primary, 0.14)
                            border.color: actionPending ? Colors.border : Colors.primary
                            border.width: 1
                            implicitHeight: 24
                            implicitWidth: availableActionLabel.implicitWidth + 18

                            Text {
                                id: availableActionLabel
                                anchors.centerIn: parent
                                text: actionPending ? "Connecting" : "Connect"
                                color: actionPending ? Colors.textSecondary : Colors.primary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !actionPending && NetworkService.pendingVpnProfileUuid === ""
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.BusyCursor
                                onClicked: NetworkService.connectVpnProfile(modelData.uuid)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: !NetworkService.vpnHasSavedProfiles
            implicitHeight: 72
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: Colors.spacingXS

                Text {
                    text: "󰖂"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "No saved NetworkManager VPN profiles"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingS

                Text {
                    text: "󰖩"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Open Networking"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "Wi-Fi, routes, and connectivity details"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openNetworkMenu()
            }
        }
    }
}
