import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

SharedWidgets.CardBase {
  id: root
  Layout.preferredHeight: 100

  property var drives: []

  CommandPoll {
    id: diskPoll
    interval: 30000
    running: root.visible
    command: ["sh", "-c", "df -h / /home 2>/dev/null | tail -n +2 | awk '{print $6 \":\" $5 \":\" $3 \":\" $2}' | sort -u"]
    parse: function(out) {
      var lines = String(out || "").trim().split("\n");
      var items = [];
      for (var i = 0; i < lines.length; i++) {
        var p = lines[i].split(":");
        if (p.length >= 4) items.push({ mount: p[0], percent: p[1], used: p[2], total: p[3] });
      }
      return items;
    }
    onUpdated: root.drives = diskPoll.value || []
  }

  ColumnLayout {
    id: diskLayout
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.spacingS

    Text {
      text: "DISK TELEMETRY"
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
      
      Repeater {
        model: root.drives
        delegate: ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingXS
          RowLayout {
            Layout.fillWidth: true
            Text { 
              text: "󰋊 " + (modelData.mount === "/" ? "ROOT" : modelData.mount.replace("/home/", "").toUpperCase())
              color: Colors.textSecondary
              font.pixelSize: Colors.fontSizeXXS
              font.weight: Font.Bold
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
            Text {
              text: modelData.percent
              color: Colors.secondary
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.Bold
              font.family: Colors.fontMono
              Layout.maximumWidth: Math.max(44, diskLayout.width * 0.24)
              horizontalAlignment: Text.AlignRight
              elide: Text.ElideLeft
            }
          }
          SharedWidgets.MiniProgressBar {
            value: Math.min(100, parseInt(modelData.percent, 10) || 0) / 100.0
            barColor: Colors.secondary
          }
        }
      }
    }
  }
}
