import QtQuick
import "../services"

Text {
  id: root

  property var state: null

  color: Colors.textSecondary
  font.pixelSize: Colors.fontSizeSmall
  text: root.state && root.state.keyboardLayout !== "" ? root.state.keyboardLayout : "Layout"
}
