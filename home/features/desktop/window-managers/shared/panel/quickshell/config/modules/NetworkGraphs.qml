import QtQuick
import QtQuick.Layouts
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

  property var downHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  property var upHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  
  property real lastRx: 0
  property real lastTx: 0
  property string currentDown: "0 KB/s"
  property string currentUp: "0 KB/s"

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: updateStats()
  }

  Process {
    id: netProc
    command: ["sh", "-c", "cat /proc/net/dev"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").split("\n");
        var rx = 0, tx = 0;
        for (var i = 2; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line === "" || line.startsWith("lo:")) continue;
          var parts = line.split(/[:\\s]+/);
          rx += parseInt(parts[1]);
          tx += parseInt(parts[9]);
        }

        if (root.lastRx > 0) {
          var diffRx = rx - root.lastRx;
          var diffTx = tx - root.lastTx;

          root.currentDown = formatSpeed(diffRx);
          root.currentUp = formatSpeed(diffTx);

          // Normalize for graph (cap at 10MB/s for scale)
          var dHist = root.downHistory;
          dHist.shift();
          dHist.push(Math.min(1.0, diffRx / 10485760));
          root.downHistory = dHist;

          var uHist = root.upHistory;
          uHist.shift();
          uHist.push(Math.min(1.0, diffTx / 10485760));
          root.upHistory = uHist;

          downCanvas.requestPaint();
          upCanvas.requestPaint();
        }

        root.lastRx = rx;
        root.lastTx = tx;
      }
    }
  }

  function formatSpeed(bytes) {
    if (bytes < 1024) return bytes + " B/s";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB/s";
    return (bytes / 1048576).toFixed(1) + " MB/s";
  }

  function updateStats() {
    if (!netProc.running) netProc.running = true;
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 15
    spacing: 20

    ColumnLayout {
      Layout.fillWidth: true
      RowLayout {
        Text { text: "DOWNLOAD"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
        Item { Layout.fillWidth: true }
        Text { text: root.currentDown; color: Colors.primary; font.pixelSize: 9; font.weight: Font.Bold }
      }
      Canvas {
        id: downCanvas; Layout.fillWidth: true; Layout.fillHeight: true
        onPaint: {
          var ctx = getContext("2d"); ctx.reset(); ctx.strokeStyle = Colors.primary; ctx.lineWidth = 2; ctx.beginPath();
          var w = width / (root.downHistory.length - 1);
          for (var i = 0; i < root.downHistory.length; i++) {
            var x = i * w; var y = height - (root.downHistory[i] * height);
            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
          }
          ctx.stroke();
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      RowLayout {
        Text { text: "UPLOAD"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
        Item { Layout.fillWidth: true }
        Text { text: root.currentUp; color: Colors.accent; font.pixelSize: 9; font.weight: Font.Bold }
      }
      Canvas {
        id: upCanvas; Layout.fillWidth: true; Layout.fillHeight: true
        onPaint: {
          var ctx = getContext("2d"); ctx.reset(); ctx.strokeStyle = Colors.accent; ctx.lineWidth = 2; ctx.beginPath();
          var w = width / (root.upHistory.length - 1);
          for (var i = 0; i < root.upHistory.length; i++) {
            var x = i * w; var y = height - (root.upHistory[i] * height);
            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
          }
          ctx.stroke();
        }
      }
    }
  }
}
