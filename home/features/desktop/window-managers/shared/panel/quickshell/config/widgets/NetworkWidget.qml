import QtQuick
import Quickshell.Io
import "../services"

Row {
  id: root
  spacing: 8

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

  Process {
    id: networkProc
    command: ["qs-network"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(this.text.trim())
          if (parsed.icon) networkIcon = parsed.icon
          if (parsed.name) networkName = parsed.name
          if (parsed.status) networkStatus = parsed.status
          networkType = parsed.type || ""
          deviceName = parsed.device || ""
          signalStrength = parsed.signal || ""
          linkSpeed = parsed.linkSpeed || ""
          connectivity = parsed.connectivity || "unknown"
          security = parsed.security || ""
          vpnCount = parsed.vpnCount || 0
          tailscaleStatus = parsed.tailscaleStatus || "Offline"
          secondaryText = parsed.secondaryText || ""
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 5000 // 5 seconds
    running: true
    repeat: true
    onTriggered: networkProc.running = true
  }

  Text {
    text: networkIcon
    color: Colors.primary
    font.pixelSize: 16
    font.family: Colors.fontMono
    anchors.verticalCenter: parent.verticalCenter
  }

  Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    Text {
      text: networkName
      color: Colors.fgMain
      font.pixelSize: 12
      font.weight: Font.DemiBold
      elide: Text.ElideRight
      width: Math.min(contentWidth, 120)
      anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
      visible: secondaryLabel.text.length > 0
      radius: 8
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
        font.pixelSize: 10
        font.weight: Font.Medium
      }
    }

    Rectangle {
      visible: root.hasVpn
      radius: 8
      color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
      border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.35)
      border.width: 1
      implicitHeight: 18
      implicitWidth: vpnLabel.implicitWidth + 10
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: vpnLabel
        anchors.centerIn: parent
        text: root.vpnCount > 1 ? root.vpnCount + " VPN" : "VPN"
        color: Colors.accent
        font.pixelSize: 10
        font.weight: Font.DemiBold
      }
    }

    Rectangle {
      visible: root.tailscaleActive
      radius: 8
      color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14)
      border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.35)
      border.width: 1
      implicitHeight: 18
      implicitWidth: tsLabel.implicitWidth + 10
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: tsLabel
        anchors.centerIn: parent
        text: "TS"
        color: Colors.primary
        font.pixelSize: 10
        font.weight: Font.DemiBold
      }
    }
  }
}
