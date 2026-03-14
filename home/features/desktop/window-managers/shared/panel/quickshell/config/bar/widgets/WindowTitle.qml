import QtQuick
import "../../services"

Text {
  id: root

  property var widgetInstance: null
  property int maxWidth: 360

  readonly property string activeTitle: {
    if (CompositorAdapter.isNiri && CompositorAdapter.niriActiveWindow)
      return CompositorAdapter.niriActiveWindow.title || "";
    return "";
  }

  width: Math.min(maxWidth, implicitWidth)
  color: Colors.fgSecondary
  font.pixelSize: Colors.fontSizeSmall
  font.letterSpacing: Colors.letterSpacingTight
  elide: Text.ElideRight
  text: activeTitle || "Desktop"
  visible: CompositorAdapter.isNiri && activeTitle !== ""
}
