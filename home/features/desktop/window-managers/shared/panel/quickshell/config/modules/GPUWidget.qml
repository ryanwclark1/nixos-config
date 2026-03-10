import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 90
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  property string vramUsage: "0 / 0 MB"
  property real vramPercent: 0.0

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: fetchVRAM.running = true
  }

  Process {
    id: fetchVRAM
    command: ["sh", "-c", "cat /sys/class/drm/card0/device/mem_info_vram_used /sys/class/drm/card0/device/mem_info_vram_total 2>/dev/null | awk '{print $1}'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = this.text.trim().split("\n");
        if (lines.length >= 2) {
          var used = parseInt(lines[0]) / 1024 / 1024;
          var total = parseInt(lines[1]) / 1024 / 1024;
          root.vramUsage = Math.round(used) + " / " + Math.round(total) + " MB";
          root.vramPercent = total > 0 ? (used / total) : 0;
        }
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: 10

    Text { 
      text: "GPU STATS"
      color: Colors.textDisabled
      font.pixelSize: 8
      font.weight: Font.Bold
      font.capitalization: Font.AllUppercase
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 20

      // GPU Load
      ColumnLayout {
        Layout.fillWidth: true; spacing: 4
        RowLayout {
          Text { 
            text: "󰢮 Load"
            color: Colors.fgMain
            font.pixelSize: 11
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text { text: SystemStatus.gpuUsage; color: Colors.fgSecondary; font.pixelSize: 10 }
        }
        Rectangle {
          Layout.fillWidth: true; height: 4; color: Colors.surface; radius: 2
          Rectangle {
            width: parent.width * SystemStatus.gpuPercent
            height: parent.height; color: Colors.accent; radius: 2
          }
        }
      }

      // VRAM
      ColumnLayout {
        Layout.fillWidth: true; spacing: 4
        RowLayout {
          Text { 
            text: "󰍛 VRAM"
            color: Colors.fgMain
            font.pixelSize: 11
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text { text: root.vramUsage; color: Colors.fgSecondary; font.pixelSize: 10 }
        }
        Rectangle {
          Layout.fillWidth: true; height: 4; color: Colors.surface; radius: 2
          Rectangle {
            width: parent.width * root.vramPercent
            height: parent.height; color: Colors.primary; radius: 2
          }
        }
      }
    }
  }
}
