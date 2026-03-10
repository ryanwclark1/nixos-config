import QtQuick
import "../services"

Text {
  id: root

  property var state: null

  color: Colors.fgSecondary
  font.pixelSize: 11
  text: root.state && root.state.keyboardLayout !== "" ? root.state.keyboardLayout : "Layout"
}
