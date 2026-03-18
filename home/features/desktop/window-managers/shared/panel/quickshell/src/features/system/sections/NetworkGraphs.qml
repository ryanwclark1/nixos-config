import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import "../models/ModuleUtils.js" as MU
import "../models/GraphUtils.js" as GU

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: networkContent.implicitHeight + Colors.paddingMedium * 2
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: netCardHover.hovered ? Colors.primary : Colors.border
  clip: true
  scale: netCardHover.hovered ? 1.01 : 1.0
  Behavior on scale { NumberAnimation { id: netScaleAnim; duration: Colors.durationSlow; easing.type: Easing.OutQuint } }
  Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }
  layer.enabled: netScaleAnim.running

  HoverHandler { id: netCardHover }

  property var downHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  property var upHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  
  readonly property real _minScaleFloor: 1048576  // 1 MB/s
  property real lastRx: 0
  property real lastTx: 0
  property real maxDown: _minScaleFloor
  property real maxUp: _minScaleFloor
  property string activeInterface: "offline"
  property string currentDown: "0 KB/s"
  property string currentUp: "0 KB/s"

  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    onTriggered: { if (!netProc.running) netProc.running = true; }
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
        var rx = parseInt(lines[1], 10) || 0;
        var tx = parseInt(lines[2], 10) || 0;

        if (root.lastRx > 0) {
          var diffRx = Math.max(0, rx - root.lastRx);
          var diffTx = Math.max(0, tx - root.lastTx);

          root.currentDown = MU.formatRate(diffRx);
          root.currentUp = MU.formatRate(diffTx);

          // Adaptive scaling: grow instantly, decay slowly
          if (diffRx > root.maxDown) root.maxDown = diffRx;
          else root.maxDown = Math.max(root._minScaleFloor, root.maxDown * 0.995);

          if (diffTx > root.maxUp) root.maxUp = diffTx;
          else root.maxUp = Math.max(root._minScaleFloor, root.maxUp * 0.995);

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
    GU.paintLineGraph(canvas, data, strokeColor, Colors.withAlpha, { fill: false });
  }

  readonly property real _valueWidth: Math.max(72, (graphGrid.width / Math.max(1, graphGrid.columns)) * 0.42)

  ColumnLayout {
    id: networkContent
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: Colors.spacingM

    GridLayout {
      id: graphGrid
      Layout.fillWidth: true
      columns: width >= 420 ? 2 : 1
      columnSpacing: Colors.spacingLG
      rowSpacing: Colors.spacingM

      ColumnLayout {
        id: downloadGraph
        Layout.fillWidth: true
        spacing: Colors.spacingXS

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "DOWNLOAD"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text {
            text: root.currentDown
            color: Colors.primary
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
            font.family: Colors.fontMono
            Layout.maximumWidth: root._valueWidth
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
          }
        }

        Text {
          Layout.fillWidth: true
          text: root.activeInterface.toUpperCase()
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Bold
          elide: Text.ElideRight
        }

        Canvas {
          id: downCanvas
          Layout.fillWidth: true
          Layout.preferredHeight: 52
          renderTarget: Canvas.FramebufferObject
          renderStrategy: Canvas.Threaded
          onPaint: root.paintGraph(downCanvas, root.downHistory, Colors.primary)
        }
      }

      ColumnLayout {
        id: uploadGraph
        Layout.fillWidth: true
        spacing: Colors.spacingXS

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "UPLOAD"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text {
            text: root.currentUp
            color: Colors.accent
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
            font.family: Colors.fontMono
            Layout.maximumWidth: root._valueWidth
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
          }
        }

        Text {
          Layout.fillWidth: true
          text: root.activeInterface.toUpperCase()
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Bold
          elide: Text.ElideRight
        }

        Canvas {
          id: upCanvas
          Layout.fillWidth: true
          Layout.preferredHeight: 52
          renderTarget: Canvas.FramebufferObject
          renderStrategy: Canvas.Threaded
          onPaint: root.paintGraph(upCanvas, root.upHistory, Colors.accent)
        }
      }
    }
  }
}
