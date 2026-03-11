import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../services"

PopupWindow {
  id: root
  implicitWidth: 300
  implicitHeight: 220
  readonly property color panelSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.96)
  readonly property color cardSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.82)

  property bool isRecording: false
  property real recordingStartTime: 0
  property string elapsedText: "00:00"

  function checkRecording() {
    if (!recordingCheck.running) recordingCheck.running = true;
  }

  function startRecording(mode) {
    Quickshell.execDetached(["screenrecord", mode]);
    Qt.callLater(function() { checkRecording(); });
  }

  function stopRecording() {
    Quickshell.execDetached(["screenrecord-stop"]);
    root.isRecording = false;
    root.elapsedText = "00:00";
  }

  function formatElapsed(ms) {
    var totalSec = Math.floor(ms / 1000);
    var min = Math.floor(totalSec / 60);
    var sec = totalSec % 60;
    return (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec;
  }

  Process {
    id: recordingCheck
    command: ["sh", "-c", "pgrep -x wl-screenrec || pgrep -x wf-recorder || pgrep -f '^gpu-screen-recorder'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var wasRecording = root.isRecording;
        root.isRecording = (this.text || "").trim().length > 0;
        if (root.isRecording && !wasRecording && root.recordingStartTime === 0) {
          root.recordingStartTime = Date.now();
        }
        if (!root.isRecording) {
          root.elapsedText = "00:00";
          root.recordingStartTime = 0;
        }
      }
    }
  }

  Timer {
    interval: 1000
    running: root.visible || root.isRecording
    repeat: true
    onTriggered: {
      if (root.isRecording && root.recordingStartTime > 0) {
        root.elapsedText = root.formatElapsed(Date.now() - root.recordingStartTime);
      }
      recordingCheck.running = true;
    }
  }

  onVisibleChanged: if (visible) checkRecording()

  Rectangle {
    anchors.fill: parent
    color: root.panelSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 14

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Screen Recording"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Rectangle {
          width: 30; height: 30; radius: 15
          color: recCloseHover.containsMouse ? Colors.highlightLight : "transparent"
          Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: 16
          }
          MouseArea {
            id: recCloseHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleRecordingMenu"])
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

      // Status display
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 50
        radius: Colors.radiusMedium
        color: root.isRecording ? Colors.withAlpha(Colors.error, 0.15) : root.cardSurface
        border.color: root.isRecording ? Colors.error : Colors.border
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 10

          Rectangle {
            width: 12; height: 12; radius: 6
            color: root.isRecording ? Colors.error : Colors.textDisabled
            SequentialAnimation on opacity {
              running: root.isRecording
              loops: Animation.Infinite
              NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
              NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
            }
          }

          Text {
            text: root.isRecording ? "Recording" : "Idle"
            color: root.isRecording ? Colors.error : Colors.fgMain
            font.pixelSize: 14
            font.weight: Font.DemiBold
          }

          Item { Layout.fillWidth: true }

          Text {
            text: root.elapsedText
            color: root.isRecording ? Colors.error : Colors.textDisabled
            font.pixelSize: 16
            font.weight: Font.Bold
            font.family: Colors.fontMono
          }
        }
      }

      // Mode buttons (only when not recording)
      RowLayout {
        Layout.fillWidth: true
        spacing: 10
        visible: !root.isRecording

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: Colors.radiusMedium
          color: fullscreenHover.containsMouse ? Colors.highlightLight : root.cardSurface
          border.color: fullscreenHover.containsMouse ? Colors.primary : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 150 } }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text { text: "󰍹"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 20; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Fullscreen"; color: Colors.fgMain; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
          }

          MouseArea {
            id: fullscreenHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.startRecording("fullscreen")
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: Colors.radiusMedium
          color: regionHover.containsMouse ? Colors.highlightLight : root.cardSurface
          border.color: regionHover.containsMouse ? Colors.primary : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 150 } }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Text { text: "󰩬"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 20; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Region"; color: Colors.fgMain; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
          }

          MouseArea {
            id: regionHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.startRecording("region")
          }
        }
      }

      // Stop button (only when recording)
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 44
        radius: Colors.radiusMedium
        visible: root.isRecording
        color: stopHover.containsMouse ? Qt.darker(Colors.error, 1.1) : Colors.error

        Text {
          anchors.centerIn: parent
          text: "󰓛  Stop Recording"
          color: "#ffffff"
          font.pixelSize: 14
          font.weight: Font.DemiBold
          font.family: Colors.fontMono
        }

        MouseArea {
          id: stopHover
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.stopRecording()
        }
      }

      Item { Layout.fillHeight: true }
    }
  }
}
