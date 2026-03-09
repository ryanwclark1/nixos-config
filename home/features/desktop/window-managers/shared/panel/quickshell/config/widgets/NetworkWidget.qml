import QtQuick
import Quickshell.Io

Row {
  spacing: 6
  anchors.verticalCenter: parent.verticalCenter

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
    color: "#e6e6e6"
    font.pixelSize: 16
    font.family: "JetBrainsMono Nerd Font"
    anchors.verticalCenter: parent.verticalCenter
  }

  Text {
    text: networkName
    color: "#e6e6e6"
    font.pixelSize: 12
    anchors.verticalCenter: parent.verticalCenter
  }
}