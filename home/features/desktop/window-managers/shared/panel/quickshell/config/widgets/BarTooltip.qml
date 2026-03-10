import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

PopupWindow {
  id: root

  property Item anchorItem: null
  property var anchorWindow: null
  property bool hovered: false
  property string text: ""
  property int delay: 250
  property real yOffset: 8
  property real maxWidth: 220

  readonly property string tooltipText: String(text || "").trim()
  readonly property bool hasText: tooltipText.length > 0
  readonly property var targetWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property point anchorTopLeft: {
    if (!anchorItem || !targetWindow) return Qt.point(0, 0);
    try {
      return anchorItem.QsWindow.itemPosition(anchorItem);
    } catch (e) {
      return Qt.point(0, 0);
    }
  }
  readonly property real aboveY: anchorTopLeft.y - implicitHeight - yOffset
  readonly property real belowY: anchorTopLeft.y + (anchorItem ? anchorItem.height : 0) + yOffset
  readonly property bool placeBelow: aboveY < 0
  property bool ready: false

  visible: ready && hasText && !!anchorItem && !!targetWindow
  color: "transparent"
  implicitWidth: tooltipBody.width
  implicitHeight: tooltipBody.height

  anchor.window: targetWindow
  anchor.rect.x: {
    if (!anchorItem) return 0;
    return anchorTopLeft.x + ((anchorItem.width - implicitWidth) / 2);
  }
  anchor.rect.y: !anchorItem ? 0 : (placeBelow ? belowY : aboveY)

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
    width: Math.min(textItem.implicitWidth + 16, root.maxWidth)
    height: textItem.implicitHeight + 10
    radius: 7
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1

    Text {
      id: textItem
      anchors.centerIn: parent
      width: Math.min(implicitWidth, root.maxWidth - 16)
      text: root.tooltipText
      color: Colors.text
      font.pixelSize: 11
      font.weight: Font.Medium
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.NoWrap
      elide: Text.ElideRight
    }
  }
}
