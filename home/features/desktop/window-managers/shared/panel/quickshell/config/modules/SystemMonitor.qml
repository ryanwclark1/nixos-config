import QtQuick
import Quickshell.Io
import "../services"

Row {
  spacing: 8
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

  // CPU Pill
  Rectangle {
    width: cpuRow.width + 16
    height: 24
    radius: height / 2
    color: Colors.bgWidget
    anchors.verticalCenter: parent.verticalCenter

    Row {
      id: cpuRow
      spacing: 6
      anchors.centerIn: parent
      Text {
        text: ""
        color: Colors.primary
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: cpuText
        text: "CPU"
        color: Colors.fgMain
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  // Memory Pill
  Rectangle {
    width: ramRow.width + 16
    height: 24
    radius: height / 2
    color: Colors.bgWidget
    anchors.verticalCenter: parent.verticalCenter

    Row {
      id: ramRow
      spacing: 6
      anchors.centerIn: parent
      Text {
        text: ""
        color: Colors.accent
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: ramText
        text: "RAM"
        color: Colors.fgMain
        font.pixelSize: 12
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
