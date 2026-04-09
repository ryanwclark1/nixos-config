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
    popupMinWidth: 420
    popupMaxWidth: 560
    compactThreshold: 460
    implicitHeight: compactMode ? 900 : 980
    title: "VPN Hub"
    subtitle: root.activeView === "tailscale"
        ? (NetworkService.vpnPrimaryLabel + " • " + NetworkService.vpnStatusLabel(NetworkService.vpnPrimaryStatus))
        : root.otherVpnSubtitle()

    property bool confirmingPrimaryAction: false
    property bool confirmingLogout: false
    property string confirmingVpnUuid: ""
    property string activeView: NetworkService.tailscaleInstalled ? "tailscale" : "vpnProfiles"

    function statusColor(statusKey) { return VH.statusColor(statusKey, Colors); }

    function defaultView() {
        return NetworkService.tailscaleInstalled ? "tailscale" : "vpnProfiles";
    }

    function ensureActiveView() {
        if (!NetworkService.tailscaleInstalled && root.activeView === "tailscale")
            root.activeView = "vpnProfiles";
        else if (root.activeView !== "tailscale" && root.activeView !== "vpnProfiles")
            root.activeView = root.defaultView();
    }

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

    function otherVpnSubtitle() {
        var activeCount = Number(NetworkService.vpnOtherCount || 0);
        var savedCount = Number(NetworkService.vpnProfileCount || 0);
        return activeCount + " active • " + savedCount + " saved";
    }

    function otherVpnSummaryLabel() {
        if (NetworkService.vpnProfileCount === 0)
            return "No saved NetworkManager VPN profiles found.";
        if (NetworkService.vpnOtherCount > 0)
            return NetworkService.vpnOtherCount === 1
                ? "1 active profile is connected."
                : NetworkService.vpnOtherCount + " active profiles are connected.";
        return "Saved VPN profiles are available to connect.";
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

    function peerOwnerText(peer) {
        var owner = VH.peerOwnerLabel(peer);
        return owner !== "" ? owner : "Unassigned";
    }

    function peerDnsText(peer) {
        var dnsName = VH.trimDnsName(peer && peer.dnsName);
        return dnsName !== "" ? dnsName : "No MagicDNS name";
    }

    function peerConnectionText(peer) {
        var detail = VH.peerStatusDetail(peer);
        return detail !== "" ? detail : (peer.online ? "Connected to tailnet" : "Offline");
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
        if (visible) {
            root.ensureActiveView();
            NetworkService.refreshData();
        }
    }

    Connections {
        target: NetworkService
        function onTailscaleInstalledChanged() { root.ensureActiveView(); }
    }

    headerExtras: [
        SharedWidgets.IconButton {
            icon: "arrow-clockwise.svg"
            tooltipText: "Refresh"
            onClicked: NetworkService.refreshData()
        },
        SharedWidgets.IconButton {
            icon: "globe-search.svg"
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
            Layout.fillWidth: true
            implicitHeight: tabRow.implicitHeight + (Appearance.spacingM * 2)
            radius: Appearance.radiusLarge
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            Flow {
                id: tabRow
                anchors.fill: parent
                anchors.margins: Appearance.spacingM
                spacing: Appearance.spacingS

                SharedWidgets.FilterChip {
                    label: "Tailscale"
                    icon: "wifi-4.svg"
                    selected: root.activeView === "tailscale"
                    enabled: NetworkService.tailscaleInstalled
                    onClicked: root.activeView = "tailscale"
                }

                SharedWidgets.FilterChip {
                    label: "Other VPNs"
                    icon: "shield-lock.svg"
                    selected: root.activeView === "vpnProfiles"
                    onClicked: root.activeView = "vpnProfiles"
                }
            }
        }

        Rectangle {
            id: summaryCard
            readonly property color statusClr: root.statusColor(NetworkService.vpnPrimaryStatus)
            Layout.fillWidth: true
            visible: root.activeView === "tailscale"
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
                    columns: compactMode ? 1 : 2
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
                        label: "Tailnet"
                        value: NetworkService.tailscaleTailnet.name !== "" ? NetworkService.tailscaleTailnet.name : "Unknown"
                    }

                    SharedWidgets.InfoRow {
                        Layout.fillWidth: true
                        label: "Online"
                        value: NetworkService.tailscaleOnlinePeerCount.toString()
                    }

                    SharedWidgets.InfoRow {
                        Layout.fillWidth: true
                        label: "MagicDNS"
                        value: NetworkService.tailscaleTailnet.magicDnsSuffix !== ""
                            ? VH.trimDnsName(NetworkService.tailscaleTailnet.magicDnsSuffix)
                            : "Unavailable"
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.activeView === "vpnProfiles"
            radius: Appearance.radiusLarge
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: otherSummaryLayout.implicitHeight + (Appearance.spacingM * 2)

            ColumnLayout {
                id: otherSummaryLayout
                anchors.fill: parent
                anchors.margins: Appearance.spacingM
                spacing: Appearance.spacingS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingM

                    SharedWidgets.SvgIcon {
                        source: "shield-lock.svg"
                        color: Colors.primary
                        size: Appearance.fontSizeHuge
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingXXS

                        Text {
                            text: "Other VPNs"
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeLarge
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: root.otherVpnSummaryLabel()
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Appearance.spacingS

                    SharedWidgets.Chip {
                        text: NetworkService.vpnOtherCount === 1 ? "1 active" : NetworkService.vpnOtherCount + " active"
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }

                    SharedWidgets.Chip {
                        text: NetworkService.vpnProfileCount === 1 ? "1 saved" : NetworkService.vpnProfileCount + " saved"
                        textColor: Colors.textSecondary
                        bgColor: Colors.chipSurface
                        borderColor: Colors.border
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            visible: root.activeView === "tailscale" && NetworkService.tailscaleProfileCount > 0

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
            visible: root.activeView === "tailscale" && NetworkService.tailscaleInstalled

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
            visible: root.activeView === "tailscale" && NetworkService.tailscaleInstalled

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
            visible: root.activeView === "tailscale" && NetworkService.tailscalePeerCount > 0

            SharedWidgets.SectionLabel { label: "Tailnet Machines" }

            Repeater {
                model: NetworkService.tailscalePeers

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: machineCardLayout.implicitHeight + (Appearance.spacingM * 2)
                    radius: Appearance.radiusMedium
                    color: Colors.cardSurface
                    border.color: modelData.online ? Colors.withAlpha(Colors.success, 0.22) : Colors.border
                    border.width: 1

                    ColumnLayout {
                        id: machineCardLayout
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingM
                        spacing: Appearance.spacingS

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
                                text: modelData.online ? "Online" : "Offline"
                                textColor: modelData.online ? Colors.success : Colors.textSecondary
                                bgColor: modelData.online
                                    ? Colors.withAlpha(Colors.success, 0.12)
                                    : Colors.chipSurface
                                borderColor: modelData.online
                                    ? Colors.withAlpha(Colors.success, 0.28)
                                    : Colors.border
                            }

                            SharedWidgets.Chip {
                                visible: modelData.active
                                text: "Active"
                                textColor: Colors.primary
                                bgColor: Colors.primaryGhost
                                borderColor: Colors.primarySubtle
                            }

                            SharedWidgets.Chip {
                                visible: modelData.exitNodeOption
                                text: "Exit Node"
                                textColor: Colors.warning
                                bgColor: Colors.withAlpha(Colors.warning, 0.14)
                                borderColor: Colors.withAlpha(Colors.warning, 0.3)
                            }

                            SharedWidgets.Chip {
                                visible: modelData.shareeNode
                                text: "Shared"
                                textColor: Colors.textSecondary
                                bgColor: Colors.chipSurface
                                borderColor: Colors.border
                            }
                        }

                        Text {
                            text: root.peerChipText(modelData) + " • " + root.peerOwnerText(modelData)
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }

                        Text {
                            text: root.peerDnsText(modelData) + " • " + root.peerConnectionText(modelData)
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            visible: root.activeView === "vpnProfiles" && NetworkService.vpnOtherCount > 0

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
            visible: root.activeView === "vpnProfiles" && NetworkService.vpnInactiveCount > 0

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
            visible: root.activeView === "vpnProfiles" && NetworkService.vpnProfileCount === 0
            implicitHeight: emptyOtherLayout.implicitHeight + (Appearance.spacingM * 2)
            radius: Appearance.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
                id: emptyOtherLayout
                anchors.fill: parent
                anchors.margins: Appearance.spacingM
                spacing: Appearance.spacingXS

                Text {
                    text: "No saved VPN profiles"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "WireGuard split tunnels and other NetworkManager VPNs will appear here when they are configured on this machine."
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.activeView === "tailscale"
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
                    source: "globe-search.svg"
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
