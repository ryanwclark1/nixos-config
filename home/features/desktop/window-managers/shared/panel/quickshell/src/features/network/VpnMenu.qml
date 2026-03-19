import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
    id: root
    popupMinWidth: 340
    popupMaxWidth: 396
    compactThreshold: 420
    implicitHeight: compactMode ? 620 : 560
    title: "VPN Hub"
    subtitle: NetworkService.vpnPrimaryLabel + " • " + NetworkService.vpnStatusLabel(NetworkService.vpnPrimaryStatus)

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
        Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleSurface", "networkMenu"]);
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
            id: mainStatusCard
            readonly property color _statusClr: root.statusColor(NetworkService.vpnPrimaryStatus)
            Layout.fillWidth: true
            radius: Colors.radiusLarge
            color: Colors.popupSurface
            border.color: Colors.withAlpha(_statusClr, 0.45)
            border.width: 1
            implicitHeight: mainStatusLayout.implicitHeight + (Colors.spacingM * 2)

            gradient: SharedWidgets.SurfaceGradient {}
            SharedWidgets.InnerHighlight {}

            ColumnLayout {
                id: mainStatusLayout
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    Text {
                        text: "󰖩"
                        color: mainStatusCard._statusClr
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeHuge
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

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
                        color: Colors.withAlpha(mainStatusCard._statusClr, 0.14)
                        border.color: Colors.withAlpha(mainStatusCard._statusClr, 0.38)
                        border.width: 1
                        implicitHeight: 28
                        implicitWidth: statusChipLabel.implicitWidth + 20

                        Text {
                            id: statusChipLabel
                            anchors.centerIn: parent
                            text: NetworkService.vpnStatusLabel(NetworkService.vpnPrimaryStatus)
                            color: mainStatusCard._statusClr
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    SharedWidgets.Chip {
                        visible: NetworkService.tailscaleIp !== ""
                        text: NetworkService.tailscaleIp
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }

                    SharedWidgets.Chip {
                        visible: NetworkService.vpnOtherCount > 0
                        text: root.otherVpnChipText()
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }

                    SharedWidgets.Chip {
                        visible: NetworkService.vpnHasSavedProfiles
                        text: root.savedVpnChipText()
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }

                    SharedWidgets.Chip {
                        visible: NetworkService.routeDevice !== ""
                        text: "Route " + NetworkService.routeDevice
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: Colors.radiusMedium
                    color: NetworkService.vpnPrimaryStatus === "connected"
                        ? Colors.withAlpha(Colors.error, 0.14)
                        : Colors.primaryStrong
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

                delegate: VpnProfileDelegate {
                    isActive: true
                    actionPending: NetworkService.pendingVpnProfileUuid === String(modelData.uuid || "")
                    onActionClicked: NetworkService.disconnectVpnProfile(modelData.uuid)
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

                delegate: VpnProfileDelegate {
                    isActive: false
                    actionPending: NetworkService.pendingVpnProfileUuid === String(modelData.uuid || "")
                    onActionClicked: NetworkService.connectVpnProfile(modelData.uuid)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: !NetworkService.vpnHasSavedProfiles
            implicitHeight: 76
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
            implicitHeight: 56
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
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
