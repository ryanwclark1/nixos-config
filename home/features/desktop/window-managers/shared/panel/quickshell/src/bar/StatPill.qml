import QtQuick
import Quickshell
import "../services"
import "../services/PopupAnchorUtils.js" as PopupAnchor
import "./widgets" as Widgets
import "../widgets" as SharedWidgets

// StatPill — parameterised bar pill for CPU / RAM / GPU stats.
// Accepts icon, color, label and stat key; renders icon-only, compact or wide.
Item {
  id: root

  property string statKey: ""
  property string icon: ""
  property color iconColor: Colors.primary
  property string label: ""
  property var widgetInstance: null
  property var anchorWindow: null

  // Bound by parent from Panel.qml helper functions:
  property bool compact: false
  property bool iconOnly: false
  property string valueText: ""
  property string compactValueText: ""
  property string tooltipText: ""
  property bool isActive: false
  property real fontScale: 1.0
  property real iconScale: 1.0

  signal clicked()

  implicitWidth: pill.width
  implicitHeight: pill.height

  Item {
    id: services
    SharedWidgets.Ref { service: SystemStatus }
    // Process list polling only while reaper popup is open (refresh on open in onSecondaryClicked).
    SharedWidgets.Ref { service: ProcessService; active: reaperPopup.isOpen }
  }

  SharedWidgets.BarPill {
    id: pill
    anchors.centerIn: parent
    anchorWindow: root.anchorWindow
    isActive: root.isActive || reaperPopup.isOpen
    tooltipText: root.tooltipText
    horizontalPadding: (root.compact || root.iconOnly) ? 5 * root.iconScale : 8 * root.iconScale
    fontScale: root.fontScale
    iconScale: root.iconScale

    readonly property bool showSparkline: (root.statKey === "cpuStatus" || root.statKey === "ramStatus" || root.statKey === "gpuStatus") && !root.iconOnly
    readonly property var historyData: {
      if (root.statKey === "cpuStatus") return SystemStatus.cpuHistory;
      if (root.statKey === "ramStatus") return SystemStatus.ramHistory;
      if (root.statKey === "gpuStatus") return SystemStatus.gpuHistory;
      return [];
    }

    Canvas {
      id: sparklineCanvas
      anchors.fill: parent
      anchors.topMargin: parent.height * 0.4
      anchors.bottomMargin: 4
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      visible: pill.showSparkline
      opacity: 0.4
      renderTarget: Canvas.FramebufferObject

      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        if (pill.historyData.length < 2) return;
        
        var w = width / (pill.historyData.length - 1);
        var h = height;

        ctx.beginPath();
        for (var i = 0; i < pill.historyData.length; i++) {
          var x = i * w;
          var y = h - (pill.historyData[i] * h * 0.8);
          if (i === 0) ctx.moveTo(x, y);
          else ctx.lineTo(x, y);
        }
        ctx.strokeStyle = root.iconColor;
        ctx.lineWidth = 1.5;
        ctx.stroke();
      }

      Connections {
        target: SystemStatus
        function onCpuHistoryChanged() { if (root.statKey === "cpuStatus") sparklineCanvas.requestPaint(); }
        function onRamHistoryChanged() { if (root.statKey === "ramStatus") sparklineCanvas.requestPaint(); }
        function onGpuHistoryChanged() { if (root.statKey === "gpuStatus") sparklineCanvas.requestPaint(); }
      }
    }

    onClicked: root.clicked()
    onSecondaryClicked: {
      if (root.statKey === "cpuStatus" || root.statKey === "ramStatus") {
        ProcessService.sortBy = (root.statKey === "cpuStatus" ? "cpu" : "mem");
        ProcessService.refresh();
        reaperPopup.toggle();
      }
    }

    Loader {
      active: true
      sourceComponent: root.iconOnly ? iconContent : (root.compact ? compactContent : wideContent)
    }
  }

  PopupWindow {
    id: reaperPopup
    property Item anchorItem: pill
    property var anchorWindow: root.anchorWindow
    property bool isOpen: visible
    readonly property string anchorEdge: {
      if (anchorWindow && anchorWindow.barConfig && anchorWindow.barConfig.position)
        return String(anchorWindow.barConfig.position);
      return "top";
    }

    function _updateRect() {
      if (!anchorItem || !anchorWindow) return;
      var r = anchorWindow.itemRect(anchorItem);
      PopupAnchor.assignPopupAnchor(reaperPopup.anchor.rect, r, anchorEdge, Config.popupGap,
          reaperPopup.implicitWidth, reaperPopup.implicitHeight);
    }

    onAnchorItemChanged: _updateRect()
    onAnchorEdgeChanged: _updateRect()
    onImplicitWidthChanged: _updateRect()
    onImplicitHeightChanged: _updateRect()
    onVisibleChanged: if (visible) _updateRect()

    anchor.window: anchorWindow
    anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY
    visible: false
    color: "transparent"
    implicitWidth: popupBody.implicitWidth
    implicitHeight: popupBody.implicitHeight

    function toggle() {
      if (!visible && (implicitWidth <= 0 || implicitHeight <= 0))
        return;
      visible = !visible;
    }

    function close() {
      visible = false;
    }

    Widgets.ProcessReaperPopup {
      id: popupBody
    }
  }

  Component {
    id: iconContent
    Loader {
      anchors.centerIn: parent
      sourceComponent: String(root.icon).endsWith(".svg") ? _iconSvg : _iconNerd
    }
  }

  Component {
    id: compactContent
    Column {
      spacing: 1

      Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: String(root.icon).endsWith(".svg") ? _compactSvg : _compactNerd
      }

      SharedWidgets.NumericText {
        text: root.compactValueText
        font.pixelSize: Appearance.fontSizeXXS * root.fontScale
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }

  Component {
    id: wideContent
    Row {
      spacing: Appearance.spacingS * root.iconScale

      Loader {
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: String(root.icon).endsWith(".svg") ? _wideSvg : _wideNerd
      }

      SharedWidgets.NumericText {
        text: root.label + " " + root.valueText
        font.pixelSize: Appearance.fontSizeSmall * root.fontScale
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  Component { id: _iconSvg; SharedWidgets.SvgIcon { source: root.icon; color: root.iconColor; size: Appearance.fontSizeLarge * root.iconScale } }
  Component { id: _iconNerd; Text { text: root.icon; color: root.iconColor; font.pixelSize: Appearance.fontSizeLarge * root.iconScale; font.family: Appearance.fontMono } }
  Component { id: _compactSvg; SharedWidgets.SvgIcon { source: root.icon; color: root.iconColor; size: Appearance.fontSizeLarge * root.iconScale } }
  Component { id: _compactNerd; Text { text: root.icon; color: root.iconColor; font.pixelSize: Appearance.fontSizeLarge * root.iconScale; font.family: Appearance.fontMono } }
  Component { id: _wideSvg; SharedWidgets.SvgIcon { source: root.icon; color: root.iconColor; size: Appearance.fontSizeIcon * root.iconScale } }
  Component { id: _wideNerd; Text { text: root.icon; color: root.iconColor; font.pixelSize: Appearance.fontSizeIcon * root.iconScale; font.family: Appearance.fontMono } }
}
