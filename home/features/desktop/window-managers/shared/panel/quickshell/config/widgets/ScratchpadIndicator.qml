import Quickshell
import QtQuick
import "../services"

Rectangle {
  id: root

  property var state: null

  radius: 6
  height: 20
  width: Math.max(40, label.implicitWidth + 12)
  color: root.state && root.state.specialWorkspaceActive ? Colors.highlight : Colors.surface
  visible: CompositorAdapter.isHyprland && root.state && root.state.specialWorkspace !== ""

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
    onClicked: {
      if (!CompositorAdapter.isHyprland) return;
      Quickshell.execDetached([ "hyprctl", "dispatch", "togglespecialworkspace", "scratchpad" ]);
    }
  }
}
