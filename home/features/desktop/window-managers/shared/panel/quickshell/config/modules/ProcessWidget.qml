import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

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

  SharedWidgets.CommandPoll {
    id: procPoll
    interval: 3000
    running: root.visible
    command: ["sh", "-c", "ps -eo comm,pcpu,pmem --sort=-pcpu | head -n 6 | tail -n 5 | awk '{print $1 \":\" $2 \":\" $3}'"]
    parse: function(out) {
      var lines = String(out || "").trim().split("\n");
      var result = [];
      for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split(":");
        if (parts.length >= 3) result.push({ name: parts[0], cpu: parts[1], mem: parts[2] });
      }
      return result;
    }
    onUpdated: root.topApps = procPoll.value || []
  }

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: Colors.paddingSmall

    Text { text: "TOP PROCESSES"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        id: processRepeater
        model: root.topApps
        
        delegate: Rectangle {
          Layout.fillWidth: true; height: 35; color: Colors.highlightLight; radius: 6
          
          RowLayout {
            anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: Colors.paddingSmall
            Text { text: "󰆍"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
            Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
            Text { text: modelData.cpu + "%"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono }
            
            // Kill button
            Rectangle {
              width: 20; height: 20; radius: 4; color: killHover.containsMouse ? Colors.error : "transparent"
              Behavior on color { ColorAnimation { duration: 160 } }
              Text { anchors.centerIn: parent; text: "󰅖"; color: killHover.containsMouse ? Colors.text : Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Behavior on color { ColorAnimation { duration: 160 } } }
              MouseArea {
                id: killHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["pkill", modelData.name])
              }
            }
          }
        }
      }
    }
  }
}
