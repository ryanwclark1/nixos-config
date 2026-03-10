import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: processRepeater.count > 0 ? col.implicitHeight + 30 : 0
  visible: processRepeater.count > 0
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  property var topApps: []

  Process {
    id: fetchProcs
    command: ["sh", "-c", "ps -eo comm,pcpu,pmem --sort=-pcpu | head -n 6 | tail -n 5 | awk '{print $1 \":\" $2 \":\" $3}'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        var items = [];
        for (var i = 0; i < lines.length; i++) {
          var p = lines[i].split(":");
          if (p.length >= 3) items.push({ name: p[0], cpu: p[1], mem: p[2] });
        }
        root.topApps = items;
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: fetchProcs.running = true
  }

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: 10

    Text { text: "TOP PROCESSES"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        id: processRepeater
        model: root.topApps
        
        delegate: Rectangle {
          Layout.fillWidth: true; height: 35; color: Colors.highlightLight; radius: 6
          
          RowLayout {
            anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: 10
            Text { text: "󰆍"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 14 }
            Text { text: modelData.name; color: Colors.text; font.pixelSize: 11; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
            Text { text: modelData.cpu + "%"; color: Colors.textSecondary; font.pixelSize: 9; font.family: Colors.fontMono }
            
            // Kill button
            Rectangle {
              width: 20; height: 20; radius: 4; color: killHover.containsMouse ? Colors.error : "transparent"
              Text { anchors.centerIn: parent; text: "󰅖"; color: killHover.containsMouse ? Colors.text : Colors.textDisabled; font.pixelSize: 10 }
              MouseArea {
                id: killHover; anchors.fill: parent; hoverEnabled: true
                onClicked: Quickshell.execDetached(["pkill", "-9", modelData.name])
              }
            }
          }
        }
      }
    }
  }
}
