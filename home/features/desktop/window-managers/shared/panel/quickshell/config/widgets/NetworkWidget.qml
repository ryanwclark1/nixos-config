import QtQuick
import Quickshell.Io
import "../services"

Row {
  id: root
  spacing: 6

  property string networkIcon: "󰤨"
  property string networkName: "Net"
  property string networkStatus: "disconnected"
  readonly property string tooltipText: {
    if (networkStatus === "wifi") return "Wi-Fi connected to " + networkName;
    if (networkStatus === "ethernet") return "Ethernet connected";
    if (networkStatus === "linked") return "Network link detected";
    if (networkStatus === "disabled") return "Networking disabled";
    return "No active network connection";
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
    font.pixelSize: 15
    font.family: Colors.fontMono
    anchors.verticalCenter: parent.verticalCenter
  }

  Text {
    text: networkName
    color: Colors.fgMain
    font.pixelSize: 11
    font.weight: Font.DemiBold
    anchors.verticalCenter: parent.verticalCenter
    elide: Text.ElideRight
    width: Math.min(contentWidth, 80)
  }
}
