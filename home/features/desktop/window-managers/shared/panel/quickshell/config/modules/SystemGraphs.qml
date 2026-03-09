import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 140
  color: Colors.highlightLight
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  property var cpuHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  property var memHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: updateStats()
  }

  Process {
    id: cpuProc
    command: ["sh", "-c", "top -bn1 | awk '/Cpu\\(s\\):/ {printf \"%d\", 100 - $8}'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var val = parseFloat(this.text.trim()) / 100;
        if (isNaN(val)) return;
        var hist = cpuHistory; hist.shift(); hist.push(val); cpuHistory = hist;
        cpuCanvas.requestPaint();
      }
    }
  }

  Process {
    id: memProc
    command: ["sh", "-c", "free | awk '/^Mem:/ {print $3/$2}'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var val = parseFloat(this.text.trim());
        if (isNaN(val)) return;
        var hist = memHistory; hist.shift(); hist.push(val); memHistory = hist;
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

    // CPU Graph
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 5
      RowLayout {
        Text { text: "CPU"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
        Item { Layout.fillWidth: true }
        Text { text: Math.round(root.cpuHistory[root.cpuHistory.length-1] * 100) + "%"; color: Colors.primary; font.pixelSize: 10; font.weight: Font.Bold }
      }
      Canvas {
        id: cpuCanvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true
        onPaint: {
          var ctx = getContext("2d");
          ctx.reset();
          var w = width / (root.cpuHistory.length - 1);
          
          // Gradient fill
          var grad = ctx.createLinearGradient(0, 0, 0, height);
          grad.addColorStop(0, Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3));
          grad.addColorStop(1, Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0));
          
          ctx.beginPath();
          ctx.moveTo(0, height);
          for (var i = 0; i < root.cpuHistory.length; i++) {
            ctx.lineTo(i * w, height - (root.cpuHistory[i] * height * 0.8));
          }
          ctx.lineTo(width, height);
          ctx.fillStyle = grad;
          ctx.fill();

          // Line
          ctx.beginPath();
          for (var i = 0; i < root.cpuHistory.length; i++) {
            var x = i * w;
            var y = height - (root.cpuHistory[i] * height * 0.8);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.strokeStyle = Colors.primary;
          ctx.lineWidth = 2;
          ctx.stroke();
        }
      }
    }

    // Memory Graph
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 5
      RowLayout {
        Text { text: "MEM"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
        Item { Layout.fillWidth: true }
        Text { text: Math.round(root.memHistory[root.memHistory.length-1] * 100) + "%"; color: Colors.accent; font.pixelSize: 10; font.weight: Font.Bold }
      }
      Canvas {
        id: memCanvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true
        onPaint: {
          var ctx = getContext("2d");
          ctx.reset();
          var w = width / (root.memHistory.length - 1);
          
          var grad = ctx.createLinearGradient(0, 0, 0, height);
          grad.addColorStop(0, Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3));
          grad.addColorStop(1, Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0));
          
          ctx.beginPath();
          ctx.moveTo(0, height);
          for (var i = 0; i < root.memHistory.length; i++) {
            ctx.lineTo(i * w, height - (root.memHistory[i] * height * 0.8));
          }
          ctx.lineTo(width, height);
          ctx.fillStyle = grad;
          ctx.fill();

          ctx.beginPath();
          for (var i = 0; i < root.memHistory.length; i++) {
            var x = i * w;
            var y = height - (root.memHistory[i] * height * 0.8);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.strokeStyle = Colors.accent;
          ctx.lineWidth = 2;
          ctx.stroke();
        }
      }
    }
  }
}
