import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: userContent.implicitHeight + Colors.paddingMedium * 2
  color: Colors.cardSurface
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true


  // Inner highlight
  SharedWidgets.InnerHighlight { }

  property string username: "User"
  property string uptime: "0h 0m"

  Process {
    id: fetchUser
    command: ["whoami"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.username = this.text.trim()
    }
  }

  SharedWidgets.CommandPoll {
    id: uptimePoll
    interval: 60000
    running: root.visible
    command: ["sh", "-c", "uptime -p | sed 's/up //;s/ hours/h/;s/ minutes/m/;s/ hour/h/;s/ minute/m/'"]
    parse: function(out) { return String(out || "").trim() || "just started" }
    onUpdated: root.uptime = uptimePoll.value
  }

  RowLayout {
    id: userContent
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: Colors.paddingMedium

    // User Avatar placeholder
    Rectangle {
      width: 42; height: 42
      radius: Colors.radiusPill
      color: Colors.primary
      Layout.alignment: Qt.AlignTop
      Text {
        anchors.centerIn: parent
        text: root.username.charAt(0).toUpperCase()
        color: Colors.text
        font.pixelSize: Colors.fontSizeXL
        font.weight: Font.Bold
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingXXS
      Text {
        text: "Welcome back, " + root.username
        color: Colors.text
        font.pixelSize: Colors.fontSizeLarge
        font.weight: Font.Bold
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
      }
      Text {
        text: "System Uptime: " + root.uptime
        color: Colors.textSecondary
        font.pixelSize: Colors.fontSizeXS
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
      }
    }
  }
}
