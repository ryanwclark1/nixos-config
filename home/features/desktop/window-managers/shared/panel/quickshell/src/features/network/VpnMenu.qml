import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../shared" as Shared
import "../../services"
import "../../services/ShellUtils.js" as SU
import "../../widgets" as SharedWidgets
import "VpnHelpers.js" as VH

BasePopupMenu {
    id: root
    popupMinWidth: 360
    popupMaxWidth: 420
    compactThreshold: 430
    implicitHeight: compactMode ? 760 : 820
    title: "VPN Hub"
    subtitle: NetworkService.vpnPrimaryLabel + " • " + NetworkService.vpnStatusLabel(NetworkService.vpnPrimaryStatus)

    property bool confirmingPrimaryAction: false
    property bool confirmingLogout: false
    property string confirmingVpnUuid: ""

    function statusColor(statusKey) { return VH.statusColor(statusKey, Colors); }

    function openNetworkMenu() {
        root.closeRequested();
        Quickshell.execDetached(SU.ipcCall("Shell", "toggleSurface", "networkMenu", ""));
    }

    function openAdminConsole() {
        Quickshell.execDetached(["xdg-open", "https://login.tailscale.com/admin/machines"]);
    }

    function tailscaleStatusLine() {
        if (!NetworkService.tailscaleInstalled)
            return "Tailscale CLI unavailable";
        if (NetworkService.tailscaleHealthSummary !== "")
            return NetworkService.tailscaleHealthSummary;
        return NetworkService.vpnPrimaryDetail;
    }

    function primaryActionLabel() {
        if (!NetworkService.tailscaleInstalled)
            return "CLI unavailable";
        if (NetworkService.pendingTailscaleAction !== "")
            return "Working...";
        if (NetworkService.tailscaleNeedsLogin)
            return NetworkService.tailscaleAuthUrl !== "" ? "Open Login" : "Start Login";
        if (NetworkService.tailscaleConnected)
            return root.confirmingPrimaryAction ? "Confirm?" : "Disconnect";
        return "Connect";
    }

    function primaryAction() {
        if (!NetworkService.tailscaleInstalled || NetworkService.pendingTailscaleAction !== "")
            return;
        if (NetworkService.tailscaleNeedsLogin) {
            NetworkService.tailscaleConnect();
            return;
        }
        if (NetworkService.tailscaleConnected) {
            if (root.confirmingPrimaryAction) {
                NetworkService.tailscaleDisconnect();
                root.confirmingPrimaryAction = false;
                root.confirmingLogout = false;
                confirmTimer.stop();
            } else {
                root.confirmingPrimaryAction = true;
                root.confirmingLogout = false;
                confirmTimer.restart();
            }
            return;
        }
        NetworkService.tailscaleConnect();
    }

    function logoutAction() {
        if (NetworkService.pendingTailscaleAction !== "" || NetworkService.tailscaleLoggedOut)
            return;
        if (root.confirmingLogout) {
            NetworkService.tailscaleLogout();
            root.confirmingLogout = false;
            root.confirmingPrimaryAction = false;
            confirmTimer.stop();
        } else {
            root.confirmingLogout = true;
            root.confirmingPrimaryAction = false;
            confirmTimer.restart();
        }
    }

    function peerChipText(peer) {
        var parts = [];
        if (peer.primaryIp)
            parts.push(peer.primaryIp);
        if (peer.os)
            parts.push(peer.os);
        return parts.join(" • ");
    }

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: {
            root.confirmingPrimaryAction = false;
            root.confirmingLogout = false;
            root.confirmingVpnUuid = "";
        }
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
            icon: "globe.svg"
            tooltipText: "Tailscale admin console"
            onClicked: root.openAdminConsole()
        },
        SharedWidgets.IconButton {
            icon: "wifi-4.svg"
            tooltipText: "Open Networking"
            onClicked: root.openNetworkMenu()
        }
    ]

    SharedWidgets.ScrollableContent {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: Appearance.spacingM

        Rectangle {
            id: summaryCard
            readonly property color statusClr: root.statusColor(NetworkService.vpnPrimaryStatus)
            Layout.fillWidth: true
            radius: Appearance.radiusLarge
            color: Colors.popupSurface
            border.color: Colors.withAlpha(statusClr, 0.45)
            border.width: 1
            implicitHeight: summaryLayout.implicitHeight + (Appearance.spacingM * 2)

            gradient: SharedWidgets.SurfaceGradient {}
            SharedWidgets.InnerHighlight {}

            ColumnLayout {
                id: summaryLayout
                anchors.fill: parent
                anchors.margins: Appearance.spacingM
                spacing: Appearance.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingM

                    SharedWidgets.SvgIcon {
                        source: NetworkService.tailscaleNeedsLogin ? "shield-lock.svg" : "wifi-4.svg"
                        color: summaryCard.statusClr
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
                            text: root.tailscaleStatusLine()
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        radius: Appearance.radiusPill
                        color: Colors.withAlpha(summaryCard.statusClr, 0.14)
                        border.color: Colors.withAlpha(summaryCard.statusClr, 0.38)
                        border.width: 1
                        implicitHeight: 28
                        implicitWidth: statusChipLabel.implicitWidth + 20

                        Text {
                            id: statusChipLabel
                            anchors.centerIn: parent
                            text: NetworkService.vpnStatusLabel(NetworkService.vpnPrimaryStatus)
                            color: summaryCard.statusClr
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
                        visible: NetworkService.tailscaleTailnet.name !== ""
                        text: NetworkService.tailscaleTailnet.name
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }

                    SharedWidgets.Chip {
                        visible: NetworkService.tailscaleCurrentExitNodeLabel !== ""
                        text: "Exit " + NetworkService.tailscaleCurrentExitNodeLabel
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }

                    SharedWidgets.Chip {
                        visible: NetworkService.tailscalePeerCount > 0
                        text: NetworkService.tailscalePeerCount === 1 ? "1 peer" : NetworkService.tailscalePeerCount + " peers"
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Appearance.radiusMedium
                        color: NetworkService.tailscaleConnected
                            ? (root.confirmingPrimaryAction ? Colors.error : Colors.withAlpha(Colors.error, 0.12))
                            : Colors.primaryStrong
                        border.color: NetworkService.tailscaleConnected ? Colors.error : Colors.primary
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.primaryActionLabel()
                            color: NetworkService.tailscaleConnected
                                ? (root.confirmingPrimaryAction ? Colors.background : Colors.error)
                                : Colors.primary
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: NetworkService.tailscaleInstalled
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.primaryAction()
                        }
                    }

                    Rectangle {
                        visible: !NetworkService.tailscaleLoggedOut
                        implicitWidth: 108
                        implicitHeight: 40
                        radius: Appearance.radiusMedium
                        color: root.confirmingLogout ? Colors.error : Colors.cardSurface
                        border.color: root.confirmingLogout ? Colors.error : Colors.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: NetworkService.pendingTailscaleAction !== ""
                                ? "Working..."
                                : (root.confirmingLogout ? "Confirm?" : "Logout")
                            color: root.confirmingLogout ? Colors.background : Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: NetworkService.pendingTailscaleAction === ""
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.BusyCursor
                            onClicked: root.logoutAction()
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Appearance.spacingM
                    rowSpacing: Appearance.spacingXS

                    SharedWidgets.InfoRow {
                        Layout.fillWidth: true
                        label: "Backend"
                        value: NetworkService.tailscaleBackendState !== "" ? NetworkService.tailscaleBackendState : "Unavailable"
                    }

                    SharedWidgets.InfoRow {
                        Layout.fillWidth: true
                        label: "Version"
                        value: NetworkService.tailscaleVersion !== "" ? NetworkService.tailscaleVersion : "Unknown"
                    }

                    SharedWidgets.InfoRow {
                        Layout.fillWidth: true
                        label: "Account"
                        value: NetworkService.tailscaleCurrentProfileLabel !== "" ? NetworkService.tailscaleCurrentProfileLabel : "Not selected"
                    }

                    SharedWidgets.InfoRow {
                        Layout.fillWidth: true
                        label: "Online"
                        value: NetworkService.tailscaleOnlinePeerCount.toString()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            visible: NetworkService.tailscaleProfileCount > 0

            SharedWidgets.SectionLabel { label: "Tailnet Accounts" }

            Repeater {
                model: NetworkService.tailscaleProfiles

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 56
                    radius: Appearance.radiusMedium
                    color: modelData.selected ? Colors.primaryGhost : Colors.cardSurface
                    border.color: modelData.selected ? Colors.primarySubtle : Colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacingM
                        anchors.rightMargin: Appearance.spacingM
                        spacing: Appearance.spacingS

                        SharedWidgets.SvgIcon {
                            source: modelData.selected ? "checkmark.svg" : "people.svg"
                            color: modelData.selected ? Colors.primary : Colors.textSecondary
                            size: Appearance.fontSizeLarge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: modelData.nickname || modelData.account || "Tailscale account"
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeSmall
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.tailnet || modelData.account || ""
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        SharedWidgets.Chip {
                            visible: modelData.selected
                            text: "Selected"
                            textColor: Colors.primary
                            bgColor: Colors.primaryGhost
                            borderColor: Colors.primarySubtle
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !modelData.selected && NetworkService.pendingTailscaleAction === ""
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: NetworkService.tailscaleSwitchProfile(modelData.id)
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            visible: NetworkService.tailscaleInstalled

            SharedWidgets.SectionLabel { label: "Exit Nodes" }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: exitNodeSummary.implicitHeight + (Appearance.spacingM * 2)
                radius: Appearance.radiusMedium
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                    id: exitNodeSummary
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingM
                    spacing: Appearance.spacingS

                    SharedWidgets.InfoRow {
                        Layout.fillWidth: true
                        label: "Current"
                        value: NetworkService.tailscaleCurrentExitNodeLabel !== "" ? NetworkService.tailscaleCurrentExitNodeLabel : "Direct routing"
                    }

                    SharedWidgets.InfoRow {
                        Layout.fillWidth: true
                        label: "LAN Access"
                        value: NetworkService.tailscaleExitNodeAllowLanAccess ? "Allowed" : "Disabled"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingS

                        SharedWidgets.ToggleSwitch {
                            checked: NetworkService.tailscaleExitNodeAllowLanAccess
                            onToggled: NetworkService.tailscaleSetExitNodeLanAccess(!NetworkService.tailscaleExitNodeAllowLanAccess)
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Allow local LAN access while using an exit node"
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeSmall
                            wrapMode: Text.Wrap
                        }

                        Rectangle {
                            visible: NetworkService.tailscaleCurrentExitNodeLabel !== ""
                            implicitWidth: 92
                            implicitHeight: 30
                            radius: Appearance.radiusPill
                            color: Colors.withAlpha(Colors.error, 0.12)
                            border.color: Colors.error
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Clear"
                                color: Colors.error
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: NetworkService.pendingTailscaleAction === ""
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.BusyCursor
                                onClicked: NetworkService.tailscaleClearExitNode()
                            }
                        }
                    }
                }
            }

            Repeater {
                model: NetworkService.tailscaleExitNodes

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isCurrent: String(modelData.primaryIp || "") !== "" && String(modelData.primaryIp || "") === String(NetworkService.tailscaleExitNode.ip || "")
                    Layout.fillWidth: true
                    implicitHeight: 56
                    radius: Appearance.radiusMedium
                    color: isCurrent ? Colors.primaryGhost : Colors.cardSurface
                    border.color: isCurrent ? Colors.primarySubtle : Colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacingM
                        anchors.rightMargin: Appearance.spacingM
                        spacing: Appearance.spacingS

                        SharedWidgets.SvgIcon {
                            source: "shield-lock.svg"
                            color: isCurrent ? Colors.primary : Colors.textSecondary
                            size: Appearance.fontSizeLarge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: NetworkService.tailscalePeerLabel(modelData)
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeSmall
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.peerChipText(modelData)
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        SharedWidgets.Chip {
                            visible: isCurrent
                            text: "Current"
                            textColor: Colors.primary
                            bgColor: Colors.primaryGhost
                            borderColor: Colors.primarySubtle
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !isCurrent && NetworkService.pendingTailscaleAction === ""
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: NetworkService.tailscaleSelectExitNode(modelData.primaryIp || modelData.id)
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            visible: NetworkService.tailscaleInstalled

            SharedWidgets.SectionLabel { label: "Runtime Preferences" }

            Repeater {
                model: [
                    {
                        label: "Accept DNS",
                        detail: "Use Tailscale DNS and MagicDNS settings",
                        checked: NetworkService.tailscaleAcceptDns,
                        action: function() { NetworkService.tailscaleSetAcceptDns(!NetworkService.tailscaleAcceptDns); }
                    },
                    {
                        label: "Accept Routes",
                        detail: "Use routes advertised by other tailnet nodes",
                        checked: NetworkService.tailscaleAcceptRoutes,
                        action: function() { NetworkService.tailscaleSetAcceptRoutes(!NetworkService.tailscaleAcceptRoutes); }
                    },
                    {
                        label: "Shields Up",
                        detail: "Block incoming tailnet connections",
                        checked: NetworkService.tailscaleShieldsUp,
                        action: function() { NetworkService.tailscaleSetShieldsUp(!NetworkService.tailscaleShieldsUp); }
                    },
                    {
                        label: "Tailscale SSH",
                        detail: "Enable Tailscale-managed SSH access",
                        checked: NetworkService.tailscaleRunSsh,
                        action: function() { NetworkService.tailscaleSetSsh(!NetworkService.tailscaleRunSsh); }
                    },
                    {
                        label: "Advertise Exit Node",
                        detail: "Offer this machine as an exit node",
                        checked: NetworkService.tailscaleAdvertiseExitNode,
                        action: function() { NetworkService.tailscaleSetAdvertiseExitNode(!NetworkService.tailscaleAdvertiseExitNode); }
                    },
                    {
                        label: "Stateful Filtering",
                        detail: "Apply stateful filtering for forwarded traffic",
                        checked: NetworkService.tailscaleStatefulFiltering,
                        action: function() { NetworkService.tailscaleSetStatefulFiltering(!NetworkService.tailscaleStatefulFiltering); }
                    }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 58
                    radius: Appearance.radiusMedium
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacingM
                        anchors.rightMargin: Appearance.spacingM
                        spacing: Appearance.spacingM

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: modelData.label
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeSmall
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.detail
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                        }

                        SharedWidgets.ToggleSwitch {
                            checked: !!modelData.checked
                            onToggled: modelData.action()
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            visible: NetworkService.tailscalePeerCount > 0

            SharedWidgets.SectionLabel { label: "Peers" }

            Repeater {
                model: NetworkService.tailscalePeers

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 60
                    radius: Appearance.radiusMedium
                    color: Colors.cardSurface
                    border.color: Colors.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingM
                        spacing: Appearance.spacingXS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingS

                            Text {
                                text: NetworkService.tailscalePeerLabel(modelData)
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeSmall
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            SharedWidgets.Chip {
                                visible: modelData.exitNodeOption
                                text: "Exit"
                                textColor: Colors.primary
                                bgColor: Colors.primaryGhost
                                borderColor: Colors.primarySubtle
                            }

                            SharedWidgets.Chip {
                                visible: modelData.active
                                text: "Active"
                                textColor: Colors.success
                                bgColor: Colors.withAlpha(Colors.success, 0.12)
                                borderColor: Colors.withAlpha(Colors.success, 0.28)
                            }
                        }

                        Text {
                            text: root.peerChipText(modelData) + (modelData.currentAddress !== "" ? " • " + modelData.currentAddress : "")
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            Layout.fillWidth: true
                            elide: Text.ElideRight
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
                    isConfirming: root.confirmingVpnUuid === String(modelData.uuid || "")
                    onActionClicked: {
                        if (root.confirmingVpnUuid === String(modelData.uuid || "")) {
                            NetworkService.disconnectVpnProfile(modelData.uuid);
                            root.confirmingVpnUuid = "";
                            confirmTimer.stop();
                        } else {
                            root.confirmingVpnUuid = String(modelData.uuid || "");
                            confirmTimer.restart();
                        }
                    }
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
                    source: "globe.svg"
                    color: Colors.primary
                    size: Appearance.fontSizeLarge
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Open Tailscale Admin Console"
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "Manage machines, routes, and tailnet policy"
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXS
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openAdminConsole()
            }
        }
    }
}
