import QtQuick
import Quickshell
import Quickshell.Io
import "../widgets" as SharedWidgets
import "../services"

Item {
  id: root
  implicitWidth: mainRow.width
  implicitHeight: mainRow.height
  property var anchorWindow: null
  
  property string fullCavaData: ""
  property bool cavaPopupVisible: false

  Row {
    id: mainRow
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    SharedWidgets.MediaBar {
      anchorWindow: root.anchorWindow
    }

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
            if (parsed.icon) parent.updatesIcon = parsed.icon
            if (parsed.count !== undefined) parent.updatesCount = parsed.count.toString()
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
      id: updatesPill
      width: updatesRow.width + 16
      height: 28
      radius: height / 2
      color: updatesMouse.containsMouse ? Colors.highlightLight : Colors.bgWidget
      anchors.verticalCenter: parent.verticalCenter
      visible: mainRow.updatesCount !== "0" && mainRow.updatesCount !== ""
      scale: updatesMouse.containsMouse ? 1.04 : 1.0

      Behavior on color { ColorAnimation { duration: 160 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Row {
        id: updatesRow
        spacing: 6
        anchors.centerIn: parent
        Text { text: mainRow.updatesIcon; color: Colors.accent; font.pixelSize: 16; font.family: Colors.fontMono; anchors.verticalCenter: parent.verticalCenter }
        Text { text: mainRow.updatesCount; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
      }

      MouseArea {
        id: updatesMouse
        anchors.fill: parent
        hoverEnabled: true
      }

      SharedWidgets.BarTooltip {
        anchorItem: updatesPill
        anchorWindow: root.anchorWindow
        hovered: updatesMouse.containsMouse
        text: "System updates"
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
            root.fullCavaData = data.toString().trim()
            cavaText.text = root.fullCavaData.substring(0, 8)
          }
        }
      }
    }

    Rectangle {
      id: cavaPill
      width: Math.min(cavaText.width + 16, 100)
      height: 28
      radius: height / 2
      color: cavaMouse.containsMouse ? Colors.highlightLight : "transparent"
      anchors.verticalCenter: parent.verticalCenter
      clip: true
      scale: cavaMouse.containsMouse ? 1.04 : 1.0

      Behavior on color { ColorAnimation { duration: 160 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Text {
        id: cavaText
        text: "▁▂▃▄▅▆▇█"
        color: Colors.primary
        font.pixelSize: 13
        anchors.centerIn: parent
      }

      MouseArea {
        id: cavaMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.cavaPopupVisible = !root.cavaPopupVisible
      }

      SharedWidgets.BarTooltip {
        anchorItem: cavaPill
        anchorWindow: root.anchorWindow
        hovered: cavaMouse.containsMouse
        text: "Audio visualizer"
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
          mainRow.inhibitorActive = (this.text.trim() === "true")
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
      id: inhibitorPill
      width: 32
      height: 28
      color: inhibitorMouse.containsMouse ? Colors.highlightLight : (mainRow.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.2) : Colors.bgWidget)
      radius: height / 2
      anchors.verticalCenter: parent.verticalCenter
      border.color: mainRow.inhibitorActive ? Colors.primary : "transparent"
      border.width: 1
      scale: inhibitorMouse.containsMouse ? 1.06 : 1.0

      Behavior on color { ColorAnimation { duration: 160 } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Text {
        anchors.centerIn: parent
        text: "󰒲"
        color: mainRow.inhibitorActive ? Colors.primary : Colors.fgMain
        font.pixelSize: 16
        font.family: Colors.fontMono
      }

      MouseArea {
        id: inhibitorMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          Quickshell.execDetached(["qs-inhibitor"]);
          // Force check update slightly later
          inhibitorCheckTimer.restart()
        }
      }

      SharedWidgets.BarTooltip {
        anchorItem: inhibitorPill
        anchorWindow: root.anchorWindow
        hovered: inhibitorMouse.containsMouse
        text: mainRow.inhibitorActive ? "Idle inhibitor enabled" : "Idle inhibitor"
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
}
