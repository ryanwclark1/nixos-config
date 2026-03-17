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
    implicitHeight: compactMode ? 520 : 488
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
                            text: NetworkService.vpnOtherCount === 1 ? "1 other VPN" : NetworkService.vpnOtherCount + " other VPNs"
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

            SharedWidgets.SectionLabel { label: "Other Active VPN Sessions" }

            Repeater {
                model: NetworkService.vpnOtherSessions

                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
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
                            color: Colors.withAlpha(Colors.accent, 0.12)
                            border.color: Colors.withAlpha(Colors.accent, 0.28)
                            border.width: 1
                            implicitHeight: 24
                            implicitWidth: otherStateLabel.implicitWidth + 16

                            Text {
                                id: otherStateLabel
                                anchors.centerIn: parent
                                text: modelData.state || "active"
                                color: Colors.accent
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: NetworkService.vpnOtherCount === 0
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
                    text: "No other VPN sessions are active"
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
