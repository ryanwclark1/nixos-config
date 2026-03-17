import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

SharedWidgets.CardBase {
  id: root
  Layout.preferredHeight: 100

  property string vramUsage: "0 / 0 MB"
  property real vramPercent: 0.0

  SharedWidgets.Ref { service: SystemStatus }

  CommandPoll {
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
    id: gpuLayout
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.spacingS

    Text {
      text: "GPU TELEMETRY"
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Black
      font.letterSpacing: Colors.letterSpacingWide
      font.capitalization: Font.AllUppercase
    }

    GridLayout {
      Layout.fillWidth: true
      columns: width >= 220 ? 2 : 1
      columnSpacing: Colors.spacingXL
      rowSpacing: Colors.spacingS

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingXS
        RowLayout {
          Layout.fillWidth: true
          Text { 
            text: "󰢮  CORE LOAD"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Bold
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text {
            text: SystemStatus.gpuUsage
            color: Colors.accent
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Bold
            font.family: Colors.fontMono
            Layout.maximumWidth: Math.max(56, gpuLayout.width * 0.42)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
          }
        }
        SharedWidgets.MiniProgressBar { value: SystemStatus.gpuPercent; barColor: Colors.accent }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingXS
        RowLayout {
          Layout.fillWidth: true
          Text { 
            text: "󰍛  MEMORY"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Bold
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text {
            text: root.vramUsage
            color: Colors.primary
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Bold
            font.family: Colors.fontMono
            Layout.maximumWidth: Math.max(72, gpuLayout.width * 0.46)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
          }
        }
        SharedWidgets.MiniProgressBar { value: root.vramPercent; barColor: Colors.primary }
      }
    }
  }
}
