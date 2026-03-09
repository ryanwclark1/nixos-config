import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 120
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  property var cpuHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  property var memHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      updateStats();
    }
  }

  Process {
    id: cpuProc
    command: ["sh", "-c", "cat /proc/loadavg"]
    stdout: StdioCollector {
      onStreamFinished: {
        var val = parseFloat((this.text || "").split(" ")[0]) / 8;
        if (isNaN(val)) return;
        var hist = root.cpuHistory;
        hist.shift();
        hist.push(Math.min(1.0, val));
        root.cpuHistory = hist;
        cpuCanvas.requestPaint();
      }
    }
  }

  Process {
    id: memProc
    command: ["sh", "-c", "free"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        if (lines.length < 2) return;
        var memLine = lines[1].trim().split(/\s+/);
        if (memLine.length < 3) return;
        var val = parseInt(memLine[2]) / parseInt(memLine[1]);
        var hist = root.memHistory;
        hist.shift();
        hist.push(val);
        root.memHistory = hist;
        memCanvas.requestPaint();
      }
    }
  }

  function updateStats() {
    if (!cpuProc.running) cpuProc.running = true;
    if (!memProc.running) memProc.running = true;
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 15
    spacing: 20

    ColumnLayout {
      Layout.fillWidth: true
      Text { 
        text: "CPU LOAD"
        color: Colors.textDisabled
        font.pixelSize: 8
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
      }
      Canvas {
        id: cpuCanvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        onPaint: {
          var ctx = getContext("2d");
          ctx.reset();
          ctx.strokeStyle = Colors.primary;
          ctx.lineWidth = 2;
          ctx.beginPath();
          var w = width / (root.cpuHistory.length - 1);
          for (var i = 0; i < root.cpuHistory.length; i++) {
            var x = i * w;
            var y = height - (root.cpuHistory[i] * height);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.stroke();
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Text { 
        text: "MEMORY"
        color: Colors.textDisabled
        font.pixelSize: 8
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
      }
      Canvas {
        id: memCanvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        onPaint: {
          var ctx = getContext("2d");
          ctx.reset();
          ctx.strokeStyle = Colors.accent;
          ctx.lineWidth = 2;
          ctx.beginPath();
          var w = width / (root.memHistory.length - 1);
          for (var i = 0; i < root.memHistory.length; i++) {
            var x = i * w;
            var y = height - (root.memHistory[i] * height);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.stroke();
        }
      }
    }
  }
}
