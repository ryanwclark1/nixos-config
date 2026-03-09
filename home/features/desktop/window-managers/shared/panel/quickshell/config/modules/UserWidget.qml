import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 80
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

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

  Process {
    id: fetchUptime
    command: ["sh", "-c", "uptime -p | sed 's/up //;s/ hours/h/;s/ minutes/m/;s/ hour/h/;s/ minute/m/'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.uptime = this.text.trim()
    }
  }

  // Refresh uptime every minute
  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: fetchUptime.running = true
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 15
    spacing: 15

    // User Avatar placeholder
    Rectangle {
      width: 50; height: 50
      radius: 25
      color: Colors.primary
      Text {
        anchors.centerIn: parent
        text: root.username.charAt(0).toUpperCase()
        color: "#ffffff"
        font.pixelSize: 24
        font.weight: Font.Bold
      }
    }

    ColumnLayout {
      spacing: 2
      Text {
        text: "Welcome back, " + root.username
        color: Colors.fgMain
        font.pixelSize: 16
        font.weight: Font.Bold
      }
      Text {
        text: "System Uptime: " + root.uptime
        color: Colors.fgSecondary
        font.pixelSize: 11
      }
    }
  }
}
