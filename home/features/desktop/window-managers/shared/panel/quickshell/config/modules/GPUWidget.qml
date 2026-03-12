import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
  id: root
  Layout.preferredHeight: 90

  property string vramUsage: "0 / 0 MB"
  property real vramPercent: 0.0

  SharedWidgets.Ref { service: SystemStatus }

  SharedWidgets.CommandPoll {
    id: vramPoll
    interval: 5000
    running: root.visible
    command: ["sh", "-c",
      "gpu_card=$(for c in /sys/class/drm/card[0-9]*/device/mem_info_vram_total; do "
      + "echo \"$(cat \"$c\" 2>/dev/null || echo 0) $(dirname \"$(dirname \"$c\")\")\" ; done 2>/dev/null "
      + "| sort -rn | head -1 | awk '{print $2}'); "
      + "[ -n \"$gpu_card\" ] && cat \"$gpu_card/device/mem_info_vram_used\" \"$gpu_card/device/mem_info_vram_total\" 2>/dev/null | awk '{print $1}'"
    ]
    parse: function(out) {
      var lines = String(out || "").trim().split("\n");
      if (lines.length >= 2) {
        var used = (parseInt(lines[0], 10) || 0) / 1024 / 1024;
        var total = (parseInt(lines[1], 10) || 0) / 1024 / 1024;
        return { usage: Math.round(used) + " / " + Math.round(total) + " MB", percent: total > 0 ? (used / total) : 0 };
      }
      return { usage: root.vramUsage, percent: root.vramPercent };
    }
    onUpdated: {
      root.vramUsage = vramPoll.value.usage;
      root.vramPercent = vramPoll.value.percent;
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.paddingSmall

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
        Layout.fillWidth: true; spacing: Colors.spacingXS
        RowLayout {
          Text { 
            text: "󰢮 Load"
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text { text: SystemStatus.gpuUsage; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeXS }
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
        Layout.fillWidth: true; spacing: Colors.spacingXS
        RowLayout {
          Text { 
            text: "󰍛 VRAM"
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text { text: root.vramUsage; color: Colors.fgSecondary; font.pixelSize: Colors.fontSizeXS }
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
