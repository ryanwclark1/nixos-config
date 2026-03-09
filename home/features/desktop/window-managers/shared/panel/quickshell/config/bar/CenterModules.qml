import QtQuick
import Quickshell.Io

Row {
  spacing: 12
  anchors.verticalCenter: parent.verticalCenter

  // Updates properties
  property string updatesIcon: "󰚰"
  property string updatesCount: "0"

  Process {
    id: updatorProc
    command: ["/home/administrator/nixos-config/home/features/desktop/window-managers/shared/panel/quickshell/scripts/updator.sh"]
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

  // Updates
  Row {
    spacing: 4
    visible: updatesCount !== "0" && updatesCount !== ""
    Text { text: updatesIcon; color: "#e6e6e6"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
    Text { text: updatesCount; color: "#e6e6e6"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
  }

  // Cava
  Process {
    id: cavaProc
    command: ["/home/administrator/nixos-config/home/features/desktop/window-managers/shared/panel/quickshell/scripts/cava.sh"]
    running: true
    stdout: SplitParser {
      onRead: function(data) {
        if (data) {
          cavaText.text = data.toString().trim()
        }
      }
    }
  }

  Text { id: cavaText; text: "▁▂▃▄▅▆▇█"; color: "#e6e6e6"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }

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

  // Idle Inhibitor
  Rectangle {
    width: 20
    height: 20
    color: "transparent"
    radius: 4
    anchors.verticalCenter: parent.verticalCenter

    Text {
      anchors.centerIn: parent
      text: "󰒲"
      color: inhibitorActive ? "#4caf50" : "#e6e6e6"
      font.pixelSize: 14
      font.family: "JetBrainsMono Nerd Font"
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        var p = Qt.createQmlObject('import Quickshell.Io; Process { running: true; command: ["/home/administrator/nixos-config/home/features/desktop/window-managers/shared/panel/quickshell/scripts/inhibitor.py"] }', parent);
        p.startDetached();
        // Force check update slightly later
        inhibitorCheckTimer.restart()
      }
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
