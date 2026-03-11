import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 140
  color: Colors.highlightLight
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  property var cpuHistory: new Array(30).fill(0)
  property var memHistory: new Array(30).fill(0)

  function paintGraph(canvas, data, strokeColor) {
    var ctx = canvas.getContext("2d");
    ctx.reset();
    var w = canvas.width / (data.length - 1);

    var grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
    grad.addColorStop(0, Colors.withAlpha(strokeColor, 0.3));
    grad.addColorStop(1, Colors.withAlpha(strokeColor, 0));

    ctx.beginPath();
    ctx.moveTo(0, canvas.height);
    for (var i = 0; i < data.length; i++) {
      ctx.lineTo(i * w, canvas.height - (data[i] * canvas.height * 0.8));
    }
    ctx.lineTo(canvas.width, canvas.height);
    ctx.fillStyle = grad;
    ctx.fill();

    ctx.beginPath();
    for (var j = 0; j < data.length; j++) {
      var x = j * w;
      var y = canvas.height - (data[j] * canvas.height * 0.8);
      if (j === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = 2;
    ctx.stroke();
  }

  Timer {
    interval: 2000
    running: root.visible
    repeat: true
    onTriggered: {
      root.cpuHistory.shift(); root.cpuHistory.push(SystemStatus.cpuPercent);
      root.cpuHistory = root.cpuHistory; // Trigger binding update
      cpuCanvas.requestPaint();
      root.memHistory.shift(); root.memHistory.push(SystemStatus.ramPercent);
      root.memHistory = root.memHistory;
      memCanvas.requestPaint();
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: 20

    // CPU Graph
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 5
      RowLayout {
        Layout.preferredHeight: 14
        Text { text: "CPU"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
        Item { Layout.fillWidth: true }
        Text { text: Math.round(root.cpuHistory[root.cpuHistory.length-1] * 100) + "%"; color: Colors.primary; font.pixelSize: 10; font.weight: Font.Bold }
      }
      Canvas {
        id: cpuCanvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true
        onPaint: root.paintGraph(cpuCanvas, root.cpuHistory, Colors.primary)
      }
    }

    // Memory Graph
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 5
      RowLayout {
        Layout.preferredHeight: 14
        Text { text: "MEM"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
        Item { Layout.fillWidth: true }
        Text { text: Math.round(root.memHistory[root.memHistory.length-1] * 100) + "%"; color: Colors.accent; font.pixelSize: 10; font.weight: Font.Bold }
      }
      Canvas {
        id: memCanvas
        Layout.fillWidth: true
        Layout.fillHeight: true
        antialiasing: true
        onPaint: root.paintGraph(memCanvas, root.memHistory, Colors.accent)
      }
    }
  }
}
