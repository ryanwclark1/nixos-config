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
    property real gap: 8
    property real inset: 8
    readonly property string anchorEdge: {
      if (anchorWindow && anchorWindow.barConfig && anchorWindow.barConfig.position)
        return String(anchorWindow.barConfig.position);
      return "top";
    }

    anchor.window: anchorWindow
    visible: false
    color: "transparent"
    implicitWidth: popupBody.implicitWidth
    implicitHeight: popupBody.implicitHeight

    function _windowX(item) {
      var x = 0;
      for (var it = item; it; it = it.parent) x += it.x;
      return x;
    }

    function _windowY(item) {
      var y = 0;
      for (var it = item; it; it = it.parent) y += it.y;
      return y;
    }

    anchor.rect.x: {
      if (!anchorItem) return 0;
      var x = 0;
      if (anchorEdge === "left")
        x = _windowX(anchorItem) + anchorItem.width + gap;
      else if (anchorEdge === "right")
        x = _windowX(anchorItem) - implicitWidth - gap;
      else
        x = _windowX(anchorItem) + (anchorItem.width - implicitWidth) / 2;
      if (anchorWindow && anchorWindow.screen) {
        var maxX = Math.max(inset, anchorWindow.screen.width - implicitWidth - inset);
        x = Math.min(Math.max(inset, x), maxX);
      }
      return x;
    }

    anchor.rect.y: {
      if (!anchorItem) return 0;
      if (anchorEdge === "bottom")
        return _windowY(anchorItem) - implicitHeight - gap;
      if (anchorEdge === "left" || anchorEdge === "right")
        return _windowY(anchorItem) + (anchorItem.height - implicitHeight) / 2;
      return _windowY(anchorItem) + anchorItem.height + gap;
    }

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
    Text {
      text: root.icon
      color: root.iconColor
      font.pixelSize: Colors.fontSizeMedium
      font.family: Colors.fontMono
    }
  }

  Component {
    id: compactContent
    Column {
      spacing: 1

      Text {
        text: root.icon
        color: root.iconColor
        font.pixelSize: Colors.fontSizeMedium
        font.family: Colors.fontMono
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
        text: root.compactValueText
        color: Colors.text
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.DemiBold
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }

  Component {
    id: wideContent
    Row {
      spacing: Colors.spacingS

      Text {
        text: root.icon
        color: root.iconColor
        font.pixelSize: Colors.fontSizeLarge
        font.family: Colors.fontMono
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: root.label + " " + root.valueText
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.DemiBold
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
