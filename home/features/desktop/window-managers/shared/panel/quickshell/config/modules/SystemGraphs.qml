import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: graphsContent.implicitHeight + Colors.paddingMedium * 2
  color: Colors.highlightLight
  radius: Colors.radiusMedium
  border.color: sysCardHover.hovered ? Colors.primary : Colors.border
  clip: true
  scale: sysCardHover.hovered ? 1.01 : 1.0
  Behavior on scale { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutQuint } }
  Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

  HoverHandler { id: sysCardHover }

  property var cpuHistory: new Array(30).fill(0)
  property var memHistory: new Array(30).fill(0)

  SharedWidgets.Ref { service: SystemStatus }

  function paintGraph(canvas, data, strokeColor) {
    if (!data.length || canvas.width <= 0 || canvas.height <= 0) return;
    var ctx = canvas.getContext("2d");
    ctx.reset();
    var w = data.length > 1 ? canvas.width / (data.length - 1) : canvas.width;

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
      root.cpuHistory = root.cpuHistory.slice(1).concat(SystemStatus.cpuPercent);
      cpuCanvas.requestPaint();
      root.memHistory = root.memHistory.slice(1).concat(SystemStatus.ramPercent);
      memCanvas.requestPaint();
    }
  }

  ColumnLayout {
    id: graphsContent
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: Colors.spacingM

    GridLayout {
      id: graphsGrid
      Layout.fillWidth: true
      columns: width >= 420 ? 2 : 1
      columnSpacing: Colors.spacingLG
      rowSpacing: Colors.spacingM

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 5
        RowLayout {
          Layout.fillWidth: true
          Text { text: "CPU"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Colors.letterSpacingWide; Layout.fillWidth: true; elide: Text.ElideRight }
          Text { text: Math.round(root.cpuHistory[root.cpuHistory.length-1] * 100) + "%"; color: Colors.primary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
        }
        Canvas {
          id: cpuCanvas
          Layout.fillWidth: true
          Layout.preferredHeight: 78
          antialiasing: true
          renderTarget: Canvas.FramebufferObject
          renderStrategy: Canvas.Threaded
          onPaint: root.paintGraph(cpuCanvas, root.cpuHistory, Colors.primary)
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 5
        RowLayout {
          Layout.fillWidth: true
          Text { text: "MEM"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Colors.letterSpacingWide; Layout.fillWidth: true; elide: Text.ElideRight }
          Text { text: Math.round(root.memHistory[root.memHistory.length-1] * 100) + "%"; color: Colors.accent; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
        }
        Canvas {
          id: memCanvas
          Layout.fillWidth: true
          Layout.preferredHeight: 78
          antialiasing: true
          renderTarget: Canvas.FramebufferObject
          renderStrategy: Canvas.Threaded
          onPaint: root.paintGraph(memCanvas, root.memHistory, Colors.accent)
        }
      }
    }
  }
}
