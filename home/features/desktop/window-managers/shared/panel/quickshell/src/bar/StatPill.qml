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
    readonly property string anchorEdge: {
      if (anchorWindow && anchorWindow.barConfig && anchorWindow.barConfig.position)
        return String(anchorWindow.barConfig.position);
      return "top";
    }

    // Map bar position to popup edge/gravity: popup appears on the opposite side
    readonly property int _edgeFlag: {
      switch (anchorEdge) {
        case "top": return Edges.Bottom;
        case "bottom": return Edges.Top;
        case "left": return Edges.Right;
        case "right": return Edges.Left;
        default: return Edges.Bottom;
      }
    }

    anchor.window: anchorWindow
    anchor.item: anchorItem
    anchor.edges: _edgeFlag
    anchor.gravity: _edgeFlag
    anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY
    anchor.margins { top: gap; bottom: gap; left: gap; right: gap }
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

      SharedWidgets.NumericText {
        text: root.compactValueText
        font.pixelSize: Colors.fontSizeXS
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

      SharedWidgets.NumericText {
        text: root.label + " " + root.valueText
        font.pixelSize: Colors.fontSizeMedium
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
