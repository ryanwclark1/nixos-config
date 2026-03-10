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

  property var cpuHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  property var memHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      var h = root.cpuHistory; h.shift(); h.push(SystemStatus.cpuPercent); root.cpuHistory = h;
      cpuCanvas.requestPaint();
      var m = root.memHistory; m.shift(); m.push(SystemStatus.ramPercent); root.memHistory = m;
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
          grad.addColorStop(0, Colors.withAlpha(Colors.primary, 0.3));
          grad.addColorStop(1, Colors.withAlpha(Colors.primary, 0));

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
          grad.addColorStop(0, Colors.withAlpha(Colors.accent, 0.3));
          grad.addColorStop(1, Colors.withAlpha(Colors.accent, 0));

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
