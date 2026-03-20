import QtQuick
import Quickshell
import "../services"
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

  signal clicked()

  implicitWidth: pill.width
  implicitHeight: pill.height

  Item {
    id: services
    SharedWidgets.Ref { service: SystemStatus }
    SharedWidgets.Ref { service: ProcessService }
  }

  SharedWidgets.BarPill {
    id: pill
    anchors.centerIn: parent
    anchorWindow: root.anchorWindow
    isActive: root.isActive || reaperPopup.isOpen
    tooltipText: root.tooltipText
    horizontalPadding: (root.compact || root.iconOnly) ? 5 : 8

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
      var gap = Config.popupGap;
      var tw = reaperPopup.implicitWidth;
      var th = reaperPopup.implicitHeight;
      var edge = anchorEdge;

      if (edge === "left" || edge === "right") {
        anchor.rect.y = r.y + r.height / 2 - th / 2;
        anchor.rect.x = edge === "left" ? r.x + r.width + gap : r.x - tw - gap;
      } else {
        anchor.rect.x = r.x + r.width / 2 - tw / 2;
        anchor.rect.y = edge === "bottom" ? r.y - th - gap : r.y + r.height + gap;
      }
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
      sourceComponent: root.icon.endsWith(".svg") ? _iconSvg : _iconNerd
    }
  }

  Component {
    id: compactContent
    Column {
      spacing: 1

      Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: root.icon.endsWith(".svg") ? _compactSvg : _compactNerd
      }

      SharedWidgets.NumericText {
        text: root.compactValueText
        font.pixelSize: Appearance.fontSizeXS
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }

  Component {
    id: wideContent
    Row {
      spacing: Appearance.spacingS

      Loader {
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.icon.endsWith(".svg") ? _wideSvg : _wideNerd
      }

      SharedWidgets.NumericText {
        text: root.label + " " + root.valueText
        font.pixelSize: Appearance.fontSizeMedium
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  Component { id: _iconSvg; SharedWidgets.SvgIcon { source: root.icon; color: root.iconColor; size: Appearance.fontSizeMedium } }
  Component { id: _iconNerd; Text { text: root.icon; color: root.iconColor; font.pixelSize: Appearance.fontSizeMedium; font.family: Appearance.fontMono } }
  Component { id: _compactSvg; SharedWidgets.SvgIcon { source: root.icon; color: root.iconColor; size: Appearance.fontSizeMedium } }
  Component { id: _compactNerd; Text { text: root.icon; color: root.iconColor; font.pixelSize: Appearance.fontSizeMedium; font.family: Appearance.fontMono } }
  Component { id: _wideSvg; SharedWidgets.SvgIcon { source: root.icon; color: root.iconColor; size: Appearance.fontSizeLarge } }
  Component { id: _wideNerd; Text { text: root.icon; color: root.iconColor; font.pixelSize: Appearance.fontSizeLarge; font.family: Appearance.fontMono } }
}
