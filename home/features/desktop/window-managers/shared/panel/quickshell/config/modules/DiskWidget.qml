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

  property var drives: []

  Process {
    id: fetchDisk
    command: ["sh", "-c", "df -h / /home | tail -n +2 | awk '{print $1 \":\" $5 \":\" $3 \":\" $2}'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        var items = [];
        for (var i = 0; i < lines.length; i++) {
          var p = lines[i].split(":");
          if (p.length >= 4) items.push({ mount: p[0], percent: p[1], used: p[2], total: p[3] });
        }
        root.drives = items;
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 15
    spacing: 10

    Text { text: "DISK USAGE"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }

    RowLayout {
      Layout.fillWidth: true
      spacing: 20
      
      Repeater {
        model: root.drives
        delegate: ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          RowLayout {
            Text { text: modelData.mount === "/" ? "󰋊 Root" : "󰋊 Home"; color: Colors.fgMain; font.pixelSize: 11; font.weight: Font.Medium }
            Item { Layout.fillWidth: true }
            Text { text: modelData.used + " / " + modelData.total; color: Colors.fgSecondary; font.pixelSize: 10 }
          }
          Rectangle {
            Layout.fillWidth: true; height: 4; color: Colors.surface; radius: 2
            Rectangle {
              width: parent.width * (parseInt(modelData.percent) / 100.0)
              height: parent.height; color: Colors.secondary; radius: 2
            }
          }
        }
      }
    }
  }
}
