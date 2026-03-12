import QtQuick
import Quickshell
import "../services"

PopupWindow {
  id: root

  property Item anchorItem: null
  property var anchorWindow: null
  property bool hovered: false
  property string text: ""
  property int delay: 250
  property real yOffset: 8
  property real maxWidth: 280

  readonly property string tooltipText: String(text || "").trim()
  readonly property bool hasText: tooltipText.length > 0
  property bool ready: false

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
    return _windowX(anchorItem) + (anchorItem.width - implicitWidth) / 2;
  }
  anchor.rect.y: {
    if (!anchorItem || !anchorItem.height) return 0;
    return _windowY(anchorItem) + anchorItem.height + yOffset;
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
    width: Math.min(textItem.implicitWidth + 20, root.maxWidth)
    height: textItem.implicitHeight + 14
    radius: Colors.radiusXS
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1

    Text {
      id: textItem
      anchors.centerIn: parent
      width: Math.min(implicitWidth, root.maxWidth - 20)
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
