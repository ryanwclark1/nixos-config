import QtQuick
import Quickshell
import "../../../services"
import "../../../shared"

Item {
  id: root

  property string text: ""
  property string shortcut: ""
  property bool hovered: false
  property Item anchorItem: null
  property var anchorWindow: null
  property int preferredSide: Qt.BottomEdge
  property int showDelay: 500

  readonly property var effectiveAnchorItem: anchorItem ? anchorItem : (parent || null)
  readonly property var resolvedAnchorWindow: {
    if (anchorWindow)
      return anchorWindow;
    if (effectiveAnchorItem && effectiveAnchorItem.Window && effectiveAnchorItem.Window.window)
      return effectiveAnchorItem.Window.window;
    if (root.Window && root.Window.window)
      return root.Window.window;
    return null;
  }
  readonly property bool useInlineTooltip: !resolvedAnchorWindow && !!effectiveAnchorItem
  readonly property int popupGap: Math.max(Appearance.spacingM, 14)
  readonly property int popupSideMargin: Appearance.spacingS
  readonly property string anchorEdge: {
    var tooltipHost = resolvedAnchorWindow;
    if (tooltipHost && tooltipHost.tooltipEdge !== undefined && tooltipHost.tooltipEdge !== "")
      return String(tooltipHost.tooltipEdge);
    if (tooltipHost && tooltipHost.barConfig && tooltipHost.barConfig.position)
      return String(tooltipHost.barConfig.position);
    return "bottom";
  }
  readonly property int tooltipSide: {
    switch (anchorEdge) {
      case "top":
        return Qt.BottomEdge;
      case "bottom":
        return Qt.TopEdge;
      case "left":
        return Qt.RightEdge;
      case "right":
        return Qt.LeftEdge;
      default:
        return Qt.TopEdge;
    }
  }

  property bool _shown: false

  visible: useInlineTooltip
  width: useInlineTooltip && effectiveAnchorItem ? effectiveAnchorItem.width : 0
  height: useInlineTooltip && effectiveAnchorItem ? effectiveAnchorItem.height : 0
  x: {
    if (!useInlineTooltip || !effectiveAnchorItem || !parent || !effectiveAnchorItem.mapToItem)
      return 0;
    return effectiveAnchorItem.mapToItem(parent, 0, 0).x;
  }
  y: {
    if (!useInlineTooltip || !effectiveAnchorItem || !parent || !effectiveAnchorItem.mapToItem)
      return 0;
    return effectiveAnchorItem.mapToItem(parent, 0, 0).y;
  }

  function syncShownState() {
    if (hovered && text !== "") {
      showTimer.restart();
    } else {
      showTimer.stop();
      _shown = false;
    }
  }

  onHoveredChanged: syncShownState()
  onTextChanged: syncShownState()
  Component.onCompleted: syncShownState()

  Timer {
    id: showTimer
    interval: root.showDelay
    onTriggered: root._shown = root.hovered && root.text !== ""
  }

  Tooltip {
    anchors.fill: parent
    anchorItem: root.effectiveAnchorItem
    anchorWindow: root.resolvedAnchorWindow
    text: root.text
    shortcut: root.shortcut
    shown: root._shown
    preferredSide: root.tooltipSide
    popupGap: root.popupGap
    popupSideMargin: root.popupSideMargin
  }
}
