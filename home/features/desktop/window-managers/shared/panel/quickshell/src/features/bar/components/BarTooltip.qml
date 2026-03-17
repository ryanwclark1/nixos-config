import QtQuick
import Quickshell
import "../../../services"
import "../../../widgets"

PopupWindow {
  id: root

  property Item anchorItem: null
  property var anchorWindow: null
  property string preferredEdge: ""
  property bool hovered: false
  property string text: ""
  property int delay: 250
  property real gap: 12
  property real maxWidth: 280

  readonly property string tooltipText: String(text || "").trim()
  readonly property bool hasText: tooltipText.length > 0
  property bool ready: false
  readonly property real inset: 8
  readonly property string anchorEdge: {
    if (preferredEdge !== "") return preferredEdge;
    if (anchorWindow && anchorWindow.tooltipEdge !== undefined && anchorWindow.tooltipEdge !== "")
      return String(anchorWindow.tooltipEdge);
    if (anchorWindow && anchorWindow.barConfig && anchorWindow.barConfig.position)
      return String(anchorWindow.barConfig.position);
    return "top";
  }

  anchor.window: anchorWindow
  // Compute window-relative coordinates by walking the parent chain.
  // Unlike mapToItem(), direct property access IS reactive — QML tracks
  // each ancestor's x/y as binding dependencies and re-evaluates on change.
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
    if (!anchorItem || !anchorItem.width) return 0;
    var x = 0;
    if (anchorEdge === "left")
      x = _windowX(anchorItem) + anchorItem.width + gap;
    else if (anchorEdge === "right")
      x = _windowX(anchorItem) - implicitWidth - gap;
    else
      x = _windowX(anchorItem) + (anchorItem.width - implicitWidth) / 2;
    
    // Clamp to screen width if possible, otherwise bar window width.
    var fullWidth = (anchorWindow && anchorWindow.screen) ? anchorWindow.screen.width : (anchorWindow ? anchorWindow.width : 1920);
    var maxX = Math.max(inset, fullWidth - implicitWidth - inset);
    return Math.min(Math.max(inset, x), maxX);
  }
  anchor.rect.y: {
    if (!anchorItem || !anchorItem.height) return 0;
    var y = 0;
    if (anchorEdge === "bottom")
      y = _windowY(anchorItem) - implicitHeight - gap;
    else if (anchorEdge === "left" || anchorEdge === "right")
      y = _windowY(anchorItem) + (anchorItem.height - implicitHeight) / 2;
    else
      y = _windowY(anchorItem) + anchorItem.height + gap;

    // We don't clamp Y against the bar window height because tooltips usually 
    // need to appear OUTSIDE the bar (e.g. below it). 
    // Quickshell's PopupWindow will handle the actual screen placement.
    return y;
  }

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
    width: Math.min(textItem.implicitWidth + 24, root.maxWidth)
    height: textItem.implicitHeight + 16
    radius: Colors.radiusSmall
    color: Colors.withAlpha(Colors.surface, 0.95)
    border.color: Colors.border
    border.width: 1

    opacity: root.ready ? 1.0 : 0.0
    scale: root.ready ? 1.0 : 0.92
    Behavior on opacity { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutBack } }

    // Subtly lighter inner border
    InnerHighlight { }

    Text {
      id: textItem
      anchors.centerIn: parent
      width: Math.min(implicitWidth, root.maxWidth - 24)
      text: root.tooltipText
      color: Colors.text
      font.pixelSize: Colors.fontSizeSmall
      font.weight: Font.Medium
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.NoWrap
      elide: Text.ElideRight
    }
  }
}
