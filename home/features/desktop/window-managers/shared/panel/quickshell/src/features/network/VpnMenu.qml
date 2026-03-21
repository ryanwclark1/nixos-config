import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/ShellUtils.js" as SU
import "../../widgets" as SharedWidgets
import "VpnHelpers.js" as VH

BasePopupMenu {
    id: root
    popupMinWidth: 340
    popupMaxWidth: 396
    compactThreshold: 420
    implicitHeight: compactMode ? 620 : 560
    title: "VPN Hub"
    subtitle: NetworkService.vpnPrimaryLabel + " • " + NetworkService.vpnStatusLabel(NetworkService.vpnPrimaryStatus)

    function statusColor(statusKey) { return VH.statusColor(statusKey, Colors); }

    function openNetworkMenu() {
        root.closeRequested();
        Quickshell.execDetached(SU.ipcCall("Shell", "toggleSurface", "networkMenu"));
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
            icon: "arrow-clockwise.svg"
            tooltipText: "Refresh"
            onClicked: NetworkService.refreshData()
        },
        SharedWidgets.IconButton {
            icon: "wifi-4.svg"
            tooltipText: "VPN settings"
            onClicked: root.openNetworkMenu()
        }
    ]

    SharedWidgets.ScrollableContent {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: Appearance.spacingM

        Rectangle {
            id: mainStatusCard
            readonly property color _statusClr: root.statusColor(NetworkService.vpnPrimaryStatus)
            Layout.fillWidth: true
            radius: Appearance.radiusLarge
            color: Colors.popupSurface
            border.color: Colors.withAlpha(_statusClr, 0.45)
            border.width: 1
            implicitHeight: mainStatusLayout.implicitHeight + (Appearance.spacingM * 2)

            gradient: SharedWidgets.SurfaceGradient {}
            SharedWidgets.InnerHighlight {}

            ColumnLayout {
                id: mainStatusLayout
                anchors.fill: parent
                anchors.margins: Appearance.spacingM
                spacing: Appearance.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingM

                    SharedWidgets.SvgIcon {
                        source: "wifi-4.svg"
                        color: mainStatusCard._statusClr
                        size: Appearance.fontSizeHuge
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingXXS

                        Text {
                            text: NetworkService.vpnPrimaryLabel
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeLarge
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: NetworkService.vpnPrimaryDetail
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        radius: Appearance.radiusPill
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
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Appearance.spacingS

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
                    radius: Appearance.radiusMedium
                    color: NetworkService.vpnPrimaryStatus === "connected"
                        ? Colors.withAlpha(Colors.error, 0.14)
                        : Colors.primaryStrong
                    border.color: NetworkService.vpnPrimaryStatus === "connected" ? Colors.error : Colors.primary
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: NetworkService.vpnPrimaryStatus === "connected" ? "Disconnect Tailscale" : "Connect Tailscale"
                        color: NetworkService.vpnPrimaryStatus === "connected" ? Colors.error : Colors.primary
                        font.pixelSize: Appearance.fontSizeSmall
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
            spacing: Appearance.spacingS
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
            spacing: Appearance.spacingS
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
            radius: Appearance.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacingXS

                SharedWidgets.SvgIcon {
                    source: "wifi-off.svg"
                    color: Colors.textDisabled
                    size: Appearance.fontSizeXL
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "No saved NetworkManager VPN profiles"
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: Appearance.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacingM
                anchors.rightMargin: Appearance.spacingM
                spacing: Appearance.spacingS

                SharedWidgets.SvgIcon {
                    source: "wifi-4.svg"
                    color: Colors.primary
                    size: Appearance.fontSizeLarge
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Open Networking"
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "Wi-Fi, routes, and connectivity details"
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXS
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
