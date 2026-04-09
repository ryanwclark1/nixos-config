import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../shared" as Shared
import "../../../widgets" as SharedWidgets

Shared.ThemedContainer {
  id: root
  variant: "card"
  Layout.fillWidth: true
  Layout.preferredHeight: userContent.implicitHeight + Appearance.paddingMedium * 2
  clip: true

  property string username: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "User"
  property string uptime: "0h 0m"

  readonly property int _uptimePollMs: 60000  // 1 min

  CommandPoll {
    id: uptimePoll
    interval: root._uptimePollMs
    running: root.visible
    command: ["sh", "-c", "cat /proc/uptime 2>/dev/null | cut -d' ' -f1"]
    parse: function(out) {
        var uptimeSecs = parseFloat(String(out || "").trim() || "0");
        if (isNaN(uptimeSecs) || uptimeSecs === 0) return "just started";
        var d = Math.floor(uptimeSecs / 86400);
        var h = Math.floor((uptimeSecs % 86400) / 3600);
        var m = Math.floor((uptimeSecs % 3600) / 60);
        var text = "";
        if (d > 0) text += d + "d ";
        if (h > 0) text += h + "h ";
        text += m + "m";
        return text;
    }
    onUpdated: root.uptime = uptimePoll.value
  }

  RowLayout {
    id: userContent
    anchors.fill: parent
    anchors.margins: Appearance.paddingMedium
    spacing: Appearance.paddingMedium

    // User Avatar placeholder
    Rectangle {
      width: 42; height: 42
      radius: Appearance.radiusPill
      color: Colors.primary
      Layout.alignment: Qt.AlignTop
      Text {
        anchors.centerIn: parent
        text: root.username.charAt(0).toUpperCase()
        color: Colors.text
        font.pixelSize: Appearance.fontSizeXL
        font.weight: Font.Bold
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingXXS
      Text {
        text: "Welcome back, " + root.username
        color: Colors.text
        font.pixelSize: Appearance.fontSizeLarge
        font.weight: Font.Bold
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
      }
      Text {
        text: "System Uptime: " + root.uptime
        color: Colors.textSecondary
        font.pixelSize: Appearance.fontSizeXS
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
      }
    }
  }
}
