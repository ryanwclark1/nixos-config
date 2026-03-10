import QtQuick
import "../../services"

Text {
  id: root

  property var state: null
  property int maxWidth: 360

  width: maxWidth
  color: Colors.fgSecondary
  font.pixelSize: 12
  elide: Text.ElideRight
  text: root.state && root.state.windowTitle !== "" ? root.state.windowTitle : "Desktop"
}
