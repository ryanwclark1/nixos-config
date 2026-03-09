import QtQuick
import Quickshell.Io
import "../services"

Row {
  spacing: 8
  anchors.verticalCenter: parent.verticalCenter

  // Updates properties
  property string updatesIcon: "󰚰"
  property string updatesCount: "0"

  Process {
    id: updatorProc
    command: ["qs-updator"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(this.text.trim())
          if (parsed.icon) updatesIcon = parsed.icon
          if (parsed.count !== undefined) updatesCount = parsed.count.toString()
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 600000 // 10 minutes
    running: true
    repeat: true
    onTriggered: updatorProc.running = true
  }

  // Updates Pill
  Rectangle {
    width: updatesRow.width + 16
    height: 24
    radius: height / 2
    color: Colors.bgWidget
    anchors.verticalCenter: parent.verticalCenter
    visible: updatesCount !== "0" && updatesCount !== ""

    Row {
      id: updatesRow
      spacing: 6
      anchors.centerIn: parent
      Text { text: updatesIcon; color: Colors.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
      Text { text: updatesCount; color: Colors.fgMain; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }
  }

  // Cava
  Process {
    id: cavaProc
    command: ["qs-cava"]
    running: true
    stdout: SplitParser {
      onRead: function(data) {
        if (data) {
          cavaText.text = data.toString().trim()
        }
      }
    }
  }

  Rectangle {
    width: cavaText.width + 16
    height: 24
    radius: height / 2
    color: "transparent"
    anchors.verticalCenter: parent.verticalCenter

    Text {
      id: cavaText
      text: "▁▂▃▄▅▆▇█"
      color: Colors.primary
      font.pixelSize: 12
      anchors.centerIn: parent
    }
  }

  // Idle Inhibitor properties
  property bool inhibitorActive: false

  Process {
    id: inhibitorCheck
    command: ["sh", "-c", "[ -f /tmp/wayland_idle_inhibitor.pid ] && echo true || echo false"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        inhibitorActive = (this.text.trim() === "true")
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: inhibitorCheck.running = true
  }

  // Idle Inhibitor Pill
  Rectangle {
    width: 28
    height: 24
    color: inhibitorActive ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : Colors.bgWidget
    radius: height / 2
    anchors.verticalCenter: parent.verticalCenter
    border.color: inhibitorActive ? Colors.primary : "transparent"
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: "󰒲"
      color: inhibitorActive ? Colors.primary : Colors.fgMain
      font.pixelSize: 14
      font.family: "JetBrainsMono Nerd Font"
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        var p = Qt.createQmlObject('import Quickshell.Io; Process { running: true; command: ["qs-inhibitor"] }', parent);
        p.startDetached();
        // Force check update slightly later
        inhibitorCheckTimer.restart()
      }
      onEntered: parent.color = Qt.rgba(255, 255, 255, 0.15)
      onExited: parent.color = inhibitorActive ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : Colors.bgWidget
    }

    Timer {
      id: inhibitorCheckTimer
      interval: 500
      running: false
      repeat: false
      onTriggered: inhibitorCheck.running = true
    }
  }
}
