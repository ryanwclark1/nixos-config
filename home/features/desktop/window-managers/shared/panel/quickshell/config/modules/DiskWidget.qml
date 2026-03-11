import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 90
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

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
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: 10

    Text { 
      text: "DISK USAGE"
      color: Colors.textDisabled
      font.pixelSize: 8
      font.weight: Font.Bold
      font.capitalization: Font.AllUppercase
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 20
      
      Repeater {
        model: root.drives
        delegate: ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          RowLayout {
            Text { 
              text: "󰋊 " + (modelData.mount === "/" ? "Root" : modelData.mount.replace("/home/", ""))
              color: Colors.fgMain
              font.pixelSize: 11
              font.weight: Font.Medium
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
            Text { text: modelData.used + " / " + modelData.total; color: Colors.fgSecondary; font.pixelSize: 10 }
          }
          Rectangle {
            Layout.fillWidth: true; height: 4; color: Colors.surface; radius: 2
            Rectangle {
              width: parent.width * (Math.min(100, parseInt(modelData.percent)) / 100.0)
              height: parent.height; color: Colors.secondary; radius: 2
            }
          }
        }
      }
    }
  }
}
