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
  property real maxDown: 1048576  // 1 MB/s floor
  property real maxUp: 1048576    // 1 MB/s floor
  property string activeInterface: "offline"
  property string currentDown: "0 KB/s"
  property string currentUp: "0 KB/s"

  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    onTriggered: updateStats()
  }

  Process {
    id: netProc
    command: [
      "sh",
      "-c",
      "iface=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}'); "
      + "if [ -z \"$iface\" ]; then iface=$(ip -o link show up 2>/dev/null | awk -F': ' '$2 != \"lo\" {print $2; exit}'); fi; "
      + "if [ -n \"$iface\" ] && [ -r \"/sys/class/net/$iface/statistics/rx_bytes\" ] && [ -r \"/sys/class/net/$iface/statistics/tx_bytes\" ]; then "
      + "printf '%s\\n%s\\n%s\\n' \"$iface\" \"$(cat /sys/class/net/$iface/statistics/rx_bytes)\" \"$(cat /sys/class/net/$iface/statistics/tx_bytes)\"; "
      + "fi"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        if (lines.length < 3) return;
        root.activeInterface = lines[0] || "offline";
        var rx = parseInt(lines[1]) || 0;
        var tx = parseInt(lines[2]) || 0;

        if (root.lastRx > 0) {
          var diffRx = Math.max(0, rx - root.lastRx);
          var diffTx = Math.max(0, tx - root.lastTx);

          root.currentDown = formatSpeed(diffRx);
          root.currentUp = formatSpeed(diffTx);

          // Adaptive scaling: grow instantly, decay slowly
          if (diffRx > root.maxDown) root.maxDown = diffRx;
          else root.maxDown = Math.max(1048576, root.maxDown * 0.995);

          if (diffTx > root.maxUp) root.maxUp = diffTx;
          else root.maxUp = Math.max(1048576, root.maxUp * 0.995);

          var dHist = root.downHistory;
          dHist.shift();
          dHist.push(Math.min(1.0, diffRx / root.maxDown));
          root.downHistory = dHist;

          var uHist = root.upHistory;
          uHist.shift();
          uHist.push(Math.min(1.0, diffTx / root.maxUp));
          root.upHistory = uHist;

          downCanvas.requestPaint();
          upCanvas.requestPaint();
        }

        root.lastRx = rx;
        root.lastTx = tx;
      }
    }
  }

  function paintGraph(canvas, data, strokeColor) {
    var ctx = canvas.getContext("2d");
    ctx.reset();
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = 2;
    ctx.beginPath();
    var w = canvas.width / (data.length - 1);
    for (var i = 0; i < data.length; i++) {
      var x = i * w;
      var y = canvas.height - (data[i] * canvas.height);
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.stroke();
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
    anchors.margins: Colors.paddingMedium
    spacing: 20

    ColumnLayout {
      Layout.fillWidth: true
      RowLayout {
        Text { 
          text: "DOWNLOAD"
          color: Colors.textDisabled
          font.pixelSize: 8
          font.weight: Font.Bold
          font.capitalization: Font.AllUppercase
        }
        Item { Layout.fillWidth: true }
        Text { text: root.activeInterface.toUpperCase(); color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
        Text { text: "•"; color: Colors.textDisabled; font.pixelSize: 8; visible: root.activeInterface !== "" }
        Text { text: root.currentDown; color: Colors.primary; font.pixelSize: 9; font.weight: Font.Bold }
      }
      Canvas {
        id: downCanvas; Layout.fillWidth: true; Layout.fillHeight: true
        onPaint: root.paintGraph(downCanvas, root.downHistory, Colors.primary)
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      RowLayout {
        Text { 
          text: "UPLOAD"
          color: Colors.textDisabled
          font.pixelSize: 8
          font.weight: Font.Bold
          font.capitalization: Font.AllUppercase
        }
        Item { Layout.fillWidth: true }
        Text { text: root.activeInterface.toUpperCase(); color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
        Text { text: "•"; color: Colors.textDisabled; font.pixelSize: 8; visible: root.activeInterface !== "" }
        Text { text: root.currentUp; color: Colors.accent; font.pixelSize: 9; font.weight: Font.Bold }
      }
      Canvas {
        id: upCanvas; Layout.fillWidth: true; Layout.fillHeight: true
        onPaint: root.paintGraph(upCanvas, root.upHistory, Colors.accent)
      }
    }
  }
}
