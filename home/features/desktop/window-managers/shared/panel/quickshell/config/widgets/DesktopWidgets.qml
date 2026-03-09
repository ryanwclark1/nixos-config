import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

Item {
  id: root
  implicitWidth: 400
  implicitHeight: 300

  ColumnLayout {
    anchors.fill: parent
    spacing: 10

    // Large Material You Clock
    ColumnLayout {
      Layout.alignment: Qt.AlignLeft
      spacing: -10

      Text {
        id: timeText
        text: Qt.formatDateTime(new Date(), "HH:mm")
        color: Colors.primary
        font.pixelSize: 96
        font.weight: Font.Bold
        font.letterSpacing: -4
        
        Timer {
          interval: 10000
          running: true
          repeat: true
          onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
        }
      }

      Text {
        id: dateText
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        color: Colors.text
        font.pixelSize: 24
        font.weight: Font.Medium
        Layout.leftMargin: 5
        
        Timer {
          interval: 60000
          running: true
          repeat: true
          onTriggered: dateText.text = Qt.formatDateTime(new Date(), "dddd, MMMM d")
        }
      }
    }

    Item { Layout.preferredHeight: 30 }

    // System Stats Row
    RowLayout {
      spacing: 30
      Layout.leftMargin: 5

      // CPU Stat
      ColumnLayout {
        spacing: 5
        Text { text: "CPU USAGE"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
        RowLayout {
          spacing: 8
          Text { text: ""; color: Colors.primary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
          Text { 
            id: cpuVal
            text: "0%"
            color: Colors.text
            font.pixelSize: 18
            font.weight: Font.Bold
          }
        }
        
        Process {
          id: cpuProc
          command: ["sh", "-c", "top -bn1 | awk '/Cpu\\(s\\):/ {printf \"%d\", 100 - $8}'"]
          running: true
          stdout: StdioCollector { onStreamFinished: cpuVal.text = this.text.trim() + "%" }
        }
      }

      // RAM Stat
      ColumnLayout {
        spacing: 5
        Text { text: "MEMORY"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
        RowLayout {
          spacing: 8
          Text { text: ""; color: Colors.secondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
          Text { 
            id: ramVal
            text: "0GB"
            color: Colors.text
            font.pixelSize: 18
            font.weight: Font.Bold
          }
        }
        
        Process {
          id: ramProc
          command: ["sh", "-c", "free -h | awk '/^Mem:/ {print $3}' | sed 's/Gi/GB/'"]
          running: true
          stdout: StdioCollector { onStreamFinished: ramVal.text = this.text.trim() }
        }
      }
    }

    Timer {
      interval: 5000
      running: true
      repeat: true
      onTriggered: { cpuProc.running = true; ramProc.running = true; }
    }

    Item { Layout.fillHeight: true }
  }
}
