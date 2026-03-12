import QtQuick
import Quickshell.Io
import "../services"


Row {
  id: root
  spacing: Colors.spacingS

  property string networkIcon: "󰤮"
  property string networkName: "Offline"
  property string networkStatus: "disconnected"
  property string networkType: ""
  property string deviceName: ""
  property string signalStrength: ""
  property string linkSpeed: ""
  property string connectivity: "unknown"
  property string security: ""
  property int vpnCount: 0
  property string tailscaleStatus: "Offline"
  property string secondaryText: "No connection"
  readonly property bool tailscaleActive: tailscaleStatus === "Connected"
  readonly property bool hasVpn: vpnCount > 0
  readonly property string tooltipText: {
    var parts = [];
    if (networkStatus === "wifi") {
      parts.push("Wi-Fi");
      parts.push(networkName);
      if (signalStrength) parts.push(signalStrength + "%");
      if (security) parts.push(security);
    } else if (networkStatus === "ethernet") {
      parts.push("Ethernet");
      if (deviceName) parts.push(deviceName);
      if (linkSpeed) parts.push(linkSpeed);
    } else if (networkStatus === "linked") {
      parts.push(networkName || "Connected");
      if (deviceName) parts.push(deviceName);
    } else if (networkStatus === "disabled") {
      parts.push("Networking disabled");
    } else {
      parts.push("No active network connection");
    }

    if (connectivity && connectivity !== "" && connectivity !== "unknown" && networkStatus !== "disabled" && networkStatus !== "disconnected") {
      parts.push(connectivity);
    }
    if (hasVpn) parts.push(vpnCount === 1 ? "VPN active" : vpnCount + " VPNs active");
    if (tailscaleActive) parts.push("Tailscale connected");
    return parts.join(" • ");
  }

  CommandPoll {
    id: networkPoll
    interval: 5000
    running: root.visible
    command: ["qs-network"]
    parse: function(out) { try { return JSON.parse(String(out || "").trim()) } catch(e) { return null } }
    onUpdated: {
      var p = networkPoll.value;
      if (!p) return;
      if (p.icon) networkIcon = p.icon;
      if (p.name) networkName = p.name;
      if (p.status) networkStatus = p.status;
      networkType = p.type || "";
      deviceName = p.device || "";
      signalStrength = p.signal || "";
      linkSpeed = p.linkSpeed || "";
      connectivity = p.connectivity || "unknown";
      security = p.security || "";
      vpnCount = p.vpnCount || 0;
      tailscaleStatus = p.tailscaleStatus || "Offline";
      secondaryText = p.secondaryText || "";
    }
  }

  Text {
    text: networkIcon
    color: Colors.primary
    font.pixelSize: Colors.fontSizeLarge
    font.family: Colors.fontMono
    anchors.verticalCenter: parent.verticalCenter
  }

  Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    Text {
      text: networkName
      color: Colors.text
      font.pixelSize: Colors.fontSizeSmall
      font.weight: Font.DemiBold
      elide: Text.ElideRight
      width: Math.min(contentWidth, 120)
      anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
      visible: secondaryLabel.text.length > 0
      radius: Colors.radiusXS
      color: Colors.highlightLight
      border.color: Colors.border
      border.width: 1
      implicitHeight: 18
      implicitWidth: secondaryLabel.implicitWidth + 10
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: secondaryLabel
        anchors.centerIn: parent
        text: root.secondaryText
        color: Colors.fgSecondary
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.Medium
      }
    }

    Rectangle {
      visible: root.hasVpn
      radius: Colors.radiusXS
      color: Colors.withAlpha(Colors.accent, 0.14)
      border.color: Colors.withAlpha(Colors.accent, 0.35)
      border.width: 1
      implicitHeight: 18
      implicitWidth: vpnLabel.implicitWidth + 10
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: vpnLabel
        anchors.centerIn: parent
        text: root.vpnCount > 1 ? root.vpnCount + " VPN" : "VPN"
        color: Colors.accent
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.DemiBold
      }
    }

    Rectangle {
      visible: root.tailscaleActive
      radius: Colors.radiusXS
      color: Colors.withAlpha(Colors.primary, 0.14)
      border.color: Colors.withAlpha(Colors.primary, 0.35)
      border.width: 1
      implicitHeight: 18
      implicitWidth: tsLabel.implicitWidth + 10
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: tsLabel
        anchors.centerIn: parent
        text: "TS"
        color: Colors.primary
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.DemiBold
      }
    }
  }
}
