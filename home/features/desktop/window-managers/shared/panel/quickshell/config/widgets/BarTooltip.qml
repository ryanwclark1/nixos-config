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
  anchor.rect.x: anchorItem ? anchorItem.mapToItem(null, 0, 0).x + (anchorItem.width - width) / 2 : 0
  anchor.rect.y: anchorItem ? anchorItem.mapToItem(null, 0, 0).y + anchorItem.height + yOffset : 0

  width: tooltipBody.width
  height: tooltipBody.height
  visible: ready && hasText && !!anchorItem
  color: "transparent"

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

  // Safety timer: ensures tooltip hides when hover ends,
  // even if the popup surface interferes with MouseArea events
  Timer {
    id: hideTimer
    interval: 150
    running: root.visible
    repeat: true
    onTriggered: {
      if (!root.hovered) {
        root.ready = false;
      }
    }
  }

  Rectangle {
    id: tooltipBody
    width: Math.min(textItem.implicitWidth + 20, root.maxWidth)
    height: textItem.implicitHeight + 14
    radius: 8
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1

    Text {
      id: textItem
      anchors.centerIn: parent
      width: Math.min(implicitWidth, root.maxWidth - 20)
      text: root.tooltipText
      color: Colors.text
      font.pixelSize: 12
      font.weight: Font.Medium
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.NoWrap
      elide: Text.ElideRight
    }
  }
}
