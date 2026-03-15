import QtQuick
import Quickshell.Wayland
import "../../services"

Text {
  id: root

  property var widgetInstance: null
  property int maxWidth: 360

  readonly property string activeTitle: {
    if (CompositorAdapter.isNiri && CompositorAdapter.niriActiveWindow)
      return CompositorAdapter.niriActiveWindow.title || "";
    if (CompositorAdapter.isHyprland && typeof ToplevelManager !== "undefined") {
      var active = ToplevelManager.activeToplevel;
      if (active) return active.title || "";
    }
    return "";
  }

  width: Math.min(maxWidth, implicitWidth)
  color: Colors.textSecondary
  font.pixelSize: Colors.fontSizeSmall
  font.letterSpacing: Colors.letterSpacingTight
  elide: Text.ElideRight
  text: activeTitle || "Desktop"
  visible: activeTitle !== ""
}
