import QtQuick
import Quickshell
import "../services"

Rectangle {
  id: root

  property var state: null

  radius: Colors.radiusXXS
  height: 20
  width: Math.max(40, label.implicitWidth + 12)
  color: root.state && root.state.specialWorkspaceActive ? Colors.highlight : Colors.surface
  visible: CompositorAdapter.supportsScratchpad && root.state && root.state.specialWorkspace !== ""

  Text {
    id: label
    anchors.centerIn: parent
    color: Colors.text
    font.pixelSize: Colors.fontSizeXS
    text: "Scratch"
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: CompositorAdapter.toggleScratchpadWorkspace("scratchpad")
  }
}
