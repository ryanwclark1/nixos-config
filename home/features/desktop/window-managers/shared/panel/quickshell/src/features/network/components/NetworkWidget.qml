import QtQuick
import "../../../services"
import "../../../widgets"

Row {
    id: root
    spacing: Colors.spacingS

    property bool iconOnly: false
    readonly property bool wifiActive: NetworkService.activePrimaryType === "wifi" || NetworkService.activePrimaryType === "802-11-wireless"
    readonly property bool ethernetActive: NetworkService.activePrimaryType === "ethernet" || NetworkService.activePrimaryType === "802-3-ethernet"
    readonly property bool tailscaleActive: NetworkService.tailscaleConnected
    readonly property bool hasVpn: NetworkService.vpnOtherCount > 0
    readonly property string networkName: NetworkService.activePrimaryName
    readonly property string secondaryText: {
        if (networkName === "Offline")
            return tailscaleActive ? "Tailscale only" : "No connection";
        if (wifiActive)
            return NetworkService.connectivityStatus;
        if (ethernetActive)
            return NetworkService.primaryDevice !== "" ? NetworkService.primaryDevice : NetworkService.connectivityStatus;
        return NetworkService.networkSubtitle();
    }
    readonly property string tooltipText: {
        var parts = [];
        if (wifiActive) {
            parts.push("Wi-Fi");
            parts.push(networkName);
            if (NetworkService.primarySignal)
                parts.push(NetworkService.primarySignal + "%");
            if (NetworkService.primarySecurity)
                parts.push(NetworkService.primarySecurity);
        } else if (ethernetActive) {
            parts.push("Ethernet");
            if (NetworkService.primaryDevice)
                parts.push(NetworkService.primaryDevice);
            if (NetworkService.primaryLinkSpeed)
                parts.push(NetworkService.primaryLinkSpeed);
        } else if (networkName !== "Offline") {
            parts.push(networkName);
            if (NetworkService.primaryDevice)
                parts.push(NetworkService.primaryDevice);
        } else {
            parts.push("No active network connection");
        }

        if (NetworkService.connectivityStatus && NetworkService.connectivityStatus !== "unknown" && networkName !== "Offline")
            parts.push(NetworkService.connectivityStatus);
        if (hasVpn)
            parts.push(NetworkService.vpnOtherCount === 1 ? "VPN active" : NetworkService.vpnOtherCount + " VPNs active");
        if (tailscaleActive)
            parts.push("Tailscale connected");
        return parts.join(" • ");
    }

    Ref {
        service: NetworkService
        active: root.visible
    }

    Text {
        text: NetworkService.networkIcon()
        color: Colors.primary
        font.pixelSize: Colors.fontSizeLarge
        font.family: Colors.fontMono
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        visible: !root.iconOnly
        anchors.verticalCenter: parent.verticalCenter
        spacing: Colors.spacingSM

        Text {
            text: root.networkName
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: Math.min(contentWidth, 120)
            anchors.verticalCenter: parent.verticalCenter
        }

        NetworkBadge {
            visible: text.length > 0
            text: root.secondaryText
            badgeColor: Colors.highlightLight
            color: Colors.highlightLight
            borderColor: Colors.border
            textColor: Colors.textSecondary
            fontWeight: Font.Medium
        }

        NetworkBadge {
            visible: root.hasVpn
            text: NetworkService.vpnOtherCount > 1 ? NetworkService.vpnOtherCount + " VPN" : "VPN"
            badgeColor: Colors.accent
            textColor: Colors.accent
        }

        NetworkBadge {
            visible: root.tailscaleActive
            text: "TS"
            badgeColor: Colors.primary
            textColor: Colors.primary
        }
    }
}
