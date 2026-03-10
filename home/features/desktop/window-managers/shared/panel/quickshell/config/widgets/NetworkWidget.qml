import QtQuick
import Quickshell.Io
import "../services"

Row {
  spacing: 6

  property string networkIcon: "󰤨"
  property string networkName: "Net"

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