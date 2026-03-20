import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: userContent.implicitHeight + Appearance.paddingMedium * 2
  color: Colors.cardSurface
  radius: Appearance.radiusMedium
  border.color: Colors.border
  clip: true


  // Inner highlight
  SharedWidgets.InnerHighlight { }

  property string username: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "User"
  property string uptime: "0h 0m"

  readonly property int _uptimePollMs: 60000  // 1 min

  CommandPoll {
    id: uptimePoll
    interval: root._uptimePollMs
    running: root.visible
    command: ["sh", "-c", "uptime -p | sed 's/up //;s/ hours/h/;s/ minutes/m/;s/ hour/h/;s/ minute/m/'"]
    parse: function(out) { return String(out || "").trim() || "just started" }
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
