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
  readonly property bool usePopup: !!anchorWindow && !!effectiveAnchorItem
  readonly property bool useInlineTooltip: !usePopup && !!effectiveAnchorItem
  readonly property string anchorEdge: {
    if (anchorWindow && anchorWindow.tooltipEdge !== undefined && anchorWindow.tooltipEdge !== "")
      return String(anchorWindow.tooltipEdge);
    if (anchorWindow && anchorWindow.barConfig && anchorWindow.barConfig.position)
      return String(anchorWindow.barConfig.position);
    return "bottom";
  }
  readonly property int popupEdge: {
    switch (anchorEdge) {
      case "top":
        return Edges.Bottom;
      case "bottom":
        return Edges.Top;
      case "left":
        return Edges.Right;
      case "right":
        return Edges.Left;
      default:
        return Edges.Top;
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
    text: root.text
    shortcut: root.shortcut
    shown: root.useInlineTooltip && root._shown
    preferredSide: root.preferredSide
  }

  PopupWindow {
    id: popupTooltip
    anchor.window: root.anchorWindow
    anchor.item: root.effectiveAnchorItem
    anchor.edges: root.popupEdge
    anchor.gravity: root.popupEdge
    anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY
    anchor.margins {
      top: Appearance.spacingS
      bottom: Appearance.spacingS
      left: Appearance.spacingS
      right: Appearance.spacingS
    }

    visible: root.usePopup && root._shown && root.text !== ""
    color: "transparent"
    implicitWidth: bubble.implicitWidth
    implicitHeight: bubble.implicitHeight

    Rectangle {
      id: bubble

      readonly property int paddingH: Appearance.spacingM
      readonly property int paddingV: Appearance.spacingXS

      implicitWidth: Math.min(280, tooltipRow.implicitWidth + paddingH * 2)
      implicitHeight: tooltipRow.implicitHeight + paddingV * 2
      width: implicitWidth
      height: implicitHeight
      radius: Appearance.radiusXS
      color: Colors.withAlpha(Colors.surface, 0.95)
      border.color: Colors.border
      border.width: 1

      Row {
        id: tooltipRow
        anchors.centerIn: parent
        spacing: Appearance.spacingXS

        Text {
          width: Math.min(200, implicitWidth)
          text: root.text
          color: Colors.text
          font.pixelSize: Appearance.fontSizeSmall
          wrapMode: Text.WordWrap
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          visible: root.shortcut !== ""
          anchors.verticalCenter: parent.verticalCenter
          radius: Appearance.radiusMicro
          color: Colors.withAlpha(Colors.text, 0.12)
          width: shortcutLabel.implicitWidth + Appearance.spacingXS * 2
          height: shortcutLabel.implicitHeight + 4

          Text {
            id: shortcutLabel
            anchors.centerIn: parent
            text: root.shortcut
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            font.family: Appearance.fontMono
          }
        }
      }
    }
  }
}
