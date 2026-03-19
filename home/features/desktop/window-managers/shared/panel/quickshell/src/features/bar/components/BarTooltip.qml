import QtQuick
import Quickshell
import "../../../services"
import "../../../shared"
import "../../../widgets"

PopupWindow {
  id: root

  property Item anchorItem: null
  property var anchorWindow: null
  property string preferredEdge: ""
  property bool hovered: false
  property string text: ""
  property string shortcut: ""
  property int delay: 250
  property real maxWidth: 280

  readonly property string tooltipText: String(text || "").trim()
  readonly property bool hasText: tooltipText.length > 0
  property bool ready: false
  readonly property string anchorEdge: {
    if (preferredEdge !== "") return preferredEdge;
    if (anchorWindow && anchorWindow.tooltipEdge !== undefined && anchorWindow.tooltipEdge !== "")
      return String(anchorWindow.tooltipEdge);
    if (anchorWindow && anchorWindow.barConfig && anchorWindow.barConfig.position)
      return String(anchorWindow.barConfig.position);
    return "top";
  }

  // Compute anchor rect from the item's position within the window,
  // offset by Config.popupGap on the appropriate edge.
  // This matches the pattern used by SurfaceService.popupAnchorX/Y
  // and BarContextPopup for consistent popup positioning.
  function _updateRect() {
    if (!anchorItem || !anchorWindow) return;
    var r = anchorWindow.itemRect(anchorItem);
    var gap = Config.popupGap;
    var tw = root.implicitWidth;
    var th = root.implicitHeight;
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
  onReadyChanged: if (ready) _updateRect()

  anchor.window: anchorWindow
  anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY

  implicitWidth: tooltipBody.width
  implicitHeight: tooltipBody.height
  visible: ready && hasText && !!anchorItem
  color: "transparent"

  // Empty input mask: all mouse events pass through the tooltip surface
  // to the underlying widgets, preventing hover/click interception
  mask: Region { width: 0; height: 0 }

  onHoveredChanged: {
    if (hovered && hasText) {
      ready = false;
      showTimer.restart();
    } else {
      showTimer.stop();
      ready = false;
    }
  }

  onTextChanged: {
    if (!hasText) {
      showTimer.stop();
      ready = false;
    } else if (hovered) {
      ready = false;
      showTimer.restart();
    }
  }

  Timer {
    id: showTimer
    interval: root.delay
    repeat: false
    onTriggered: root.ready = root.hovered && root.hasText
  }

  Rectangle {
    id: tooltipBody
    width: Math.min(tooltipRow.implicitWidth + 24, root.maxWidth)
    height: tooltipRow.implicitHeight + 16
    radius: Colors.radiusSmall
    color: Colors.withAlpha(Colors.surface, 0.95)
    border.color: Colors.border
    border.width: 1

    opacity: root.ready ? 1.0 : 0.0
    scale: root.ready ? 1.0 : 0.92
    Behavior on opacity { Anim { duration: Colors.durationFast } }
    Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutBack } }

    // Subtly lighter inner border
    InnerHighlight { }

    Row {
      id: tooltipRow
      anchors.centerIn: parent
      spacing: Colors.spacingXS

      Text {
        id: textItem
        width: Math.min(implicitWidth, root.maxWidth - 24)
        text: root.tooltipText
        color: Colors.text
        font.pixelSize: Colors.fontSizeSmall
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
      }

      Rectangle {
        visible: root.shortcut !== ""
        anchors.verticalCenter: parent.verticalCenter
        radius: Colors.radiusMicro
        color: Colors.withAlpha(Colors.text, 0.12)
        width: shortcutLabel.implicitWidth + Colors.spacingXS * 2
        height: shortcutLabel.implicitHeight + 4

        Text {
          id: shortcutLabel
          anchors.centerIn: parent
          text: root.shortcut
          color: Colors.textSecondary
          font.pixelSize: Colors.fontSizeXS
          font.family: Colors.fontMono
        }
      }
    }
  }
}
