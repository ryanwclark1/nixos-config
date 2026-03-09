import QtQuick
import Quickshell.Io

Row {
  spacing: 12
  anchors.verticalCenter: parent.verticalCenter

  Process {
    id: cpuProc
    command: ["sh", "-c", "top -bn1 | awk '/Cpu\\(s\\):/ {printf \"%d\", 100 - $8}'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        cpuText.text = "CPU " + this.text.trim() + "%"
      }
    }
  }

  Process {
    id: ramProc
    command: ["sh", "-c", "free -h | awk '/^Mem:/ {print $3}' | sed 's/Gi/GB/'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        ramText.text = "RAM " + this.text.trim()
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      ramProc.running = true
    }
  }

  // CPU
  Row {
    spacing: 4
    Text {
      text: ""
      color: "#e6e6e6"
      font.pixelSize: 14
      font.family: "JetBrainsMono Nerd Font"
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      id: cpuText
      text: "CPU"
      color: "#e6e6e6"
      font.pixelSize: 12
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  // Memory
  Row {
    spacing: 4
    Text {
      text: ""
      color: "#e6e6e6"
      font.pixelSize: 14
      font.family: "JetBrainsMono Nerd Font"
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      id: ramText
      text: "RAM"
      color: "#e6e6e6"
      font.pixelSize: 12
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
