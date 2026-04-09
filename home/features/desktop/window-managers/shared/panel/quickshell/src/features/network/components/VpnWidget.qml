import QtQuick
import "../../../shared"
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../VpnHelpers.js" as VH

Row {
    id: root
    spacing: Appearance.spacingS

    property bool iconOnly: false
    property string labelMode: "status"
    property bool showOtherVpnCount: true

    readonly property string statusKey: NetworkService.vpnPrimaryStatus
    readonly property string statusLabel: NetworkService.vpnStatusLabel(statusKey)
    readonly property string detailLabel: labelMode === "ip" && statusKey === "connected" && NetworkService.tailscaleIp !== ""
        ? NetworkService.tailscaleIp
        : statusLabel
    readonly property bool showOtherCount: showOtherVpnCount && NetworkService.vpnOtherCount > 0
    readonly property string tooltipText: {
        var parts = ["Tailscale", statusLabel];
        if (statusKey === "connected" && NetworkService.tailscaleIp !== "")
            parts.push(NetworkService.tailscaleIp);
        if (NetworkService.tailscaleCurrentExitNodeLabel)
            parts.push("Exit " + NetworkService.tailscaleCurrentExitNodeLabel);
        if (NetworkService.tailscaleHealthSummary)
            parts.push(NetworkService.tailscaleHealthSummary);
        if (showOtherCount)
            parts.push(NetworkService.vpnOtherCount === 1 ? "1 other VPN" : NetworkService.vpnOtherCount + " other VPNs");
        if (!NetworkService.tailscaleInstalled)
            parts.push("CLI unavailable");
        return parts.join(" • ");
    }

    function statusColor() { return VH.statusColor(root.statusKey, Colors); }

    Ref {
        service: NetworkService
        active: root.visible
    }

    SharedWidgets.SvgIcon {
        source: "shield-lock.svg"
        color: root.statusColor()
        size: Appearance.fontSizeLarge
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        visible: !root.iconOnly
        spacing: Appearance.spacingSM
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "Tailscale"
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            radius: Appearance.radiusXS
            color: Colors.withAlpha(root.statusColor(), 0.14)
            border.color: Colors.withAlpha(root.statusColor(), 0.35)
            border.width: 1
            implicitHeight: 18
            implicitWidth: detailText.implicitWidth + 10
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: detailText
                anchors.centerIn: parent
                text: root.detailLabel
                color: root.statusColor()
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            visible: root.showOtherCount
            radius: Appearance.radiusXS
            color: Colors.withAlpha(Colors.accent, 0.14)
            border.color: Colors.withAlpha(Colors.accent, 0.35)
            border.width: 1
            implicitHeight: 18
            implicitWidth: otherVpnText.implicitWidth + 10
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: otherVpnText
                anchors.centerIn: parent
                text: NetworkService.vpnOtherCount > 1 ? NetworkService.vpnOtherCount + " VPN" : "VPN"
                color: Colors.accent
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.DemiBold
            }
        }
    }
}
