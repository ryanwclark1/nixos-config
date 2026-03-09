import QtQuick

Text {
  id: root

  property var state: null

  color: "#cfd3d6"
  font.pixelSize: 11
  text: root.state && root.state.keyboardLayout !== "" ? root.state.keyboardLayout : "Layout"
}
