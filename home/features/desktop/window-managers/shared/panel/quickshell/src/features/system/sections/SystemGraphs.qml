import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets
import "../models/GraphUtils.js" as GU

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: graphsContent.implicitHeight + Colors.paddingMedium * 2
  color: Colors.highlightLight
  radius: Colors.radiusMedium
  border.color: sysCardHover.hovered ? Colors.primary : Colors.border
  clip: true
  scale: sysCardHover.hovered ? 1.01 : 1.0
  Behavior on scale { NumberAnimation { id: sysScaleAnim; duration: Colors.durationSlow; easing.type: Easing.OutQuint } }
  Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }
  layer.enabled: sysScaleAnim.running

  HoverHandler { id: sysCardHover }

  property var cpuHistory: []
  property var memHistory: []

  SharedWidgets.Ref { service: SystemStatus }

  Component.onCompleted: {
    cpuHistory = SystemStatus.cpuHistory.slice(-30);
    memHistory = SystemStatus.ramHistory.slice(-30);
  }

  Connections {
    target: SystemStatus
    function onCpuHistoryChanged() {
      root.cpuHistory = SystemStatus.cpuHistory.slice(-30);
      cpuCanvas.requestPaint();
    }
    function onRamHistoryChanged() {
      root.memHistory = SystemStatus.ramHistory.slice(-30);
      memCanvas.requestPaint();
    }
  }

  function paintGraph(canvas, data, strokeColor) {
    GU.paintLineGraph(canvas, data, strokeColor, Colors.withAlpha, { yScale: 0.8 });
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
        spacing: Colors.spacingSM
        RowLayout {
          Layout.fillWidth: true
          Text { text: "CPU"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Colors.letterSpacingWide; Layout.fillWidth: true; elide: Text.ElideRight }
          Text { text: root.cpuHistory.length > 0 ? Math.round(root.cpuHistory[root.cpuHistory.length-1] * 100) + "%" : "—"; color: Colors.primary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
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
        spacing: Colors.spacingSM
        RowLayout {
          Layout.fillWidth: true
          Text { text: "MEM"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Colors.letterSpacingWide; Layout.fillWidth: true; elide: Text.ElideRight }
          Text { text: root.memHistory.length > 0 ? Math.round(root.memHistory[root.memHistory.length-1] * 100) + "%" : "—"; color: Colors.accent; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
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
