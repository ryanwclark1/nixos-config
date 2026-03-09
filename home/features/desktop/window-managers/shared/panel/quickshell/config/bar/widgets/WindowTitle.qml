import QtQuick

Text {
  id: root

  property var state: null
  property int maxWidth: 360

  width: maxWidth
  color: "#cfd3d6"
  font.pixelSize: 12
  elide: Text.ElideRight
  text: root.state && root.state.windowTitle !== "" ? root.state.windowTitle : "Desktop"
}
