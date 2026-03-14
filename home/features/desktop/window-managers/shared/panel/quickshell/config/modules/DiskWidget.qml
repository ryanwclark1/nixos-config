import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
  id: root
  Layout.preferredHeight: 90

  property var drives: []

  SharedWidgets.CommandPoll {
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
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.paddingSmall

    Text {
      text: "DISK USAGE"
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Bold
      font.capitalization: Font.AllUppercase
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingLG
      
      Repeater {
        model: root.drives
        delegate: ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingXS
          RowLayout {
            Text { 
              text: "󰋊 " + (modelData.mount === "/" ? "Root" : modelData.mount.replace("/home/", ""))
              color: Colors.text
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.Medium
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
            Text { text: modelData.used + " / " + modelData.total; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS }
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
