import QtQuick
import "../services"

Rectangle {
  id: root

  property string target: "@DEFAULT_AUDIO_SINK@"
  property bool muted: false
  property string icon: "󰕾"
  property string mutedIcon: "󰝟"
  property int size: 28
  property bool showBorder: false
  property var action: null

  width: size; height: size; radius: size / 2
  color: showBorder ? Colors.bgWidget : "transparent"
  border.color: showBorder ? Colors.border : "transparent"
  border.width: showBorder ? 1 : 0

  Text {
    anchors.centerIn: parent
    text: root.muted ? root.mutedIcon : root.icon
    color: root.muted ? Colors.error : Colors.textSecondary
    font.family: Colors.fontMono
    font.pixelSize: Math.round(root.size * 0.5)
  }

  opacity: enabled ? 1.0 : 0.4

  StateLayer {
    id: stateLayer
    hovered: hover.containsMouse
    pressed: hover.pressed
    disabled: !root.enabled
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: root.enabled
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: (mouse) => {
      if (!root.enabled) return;
      stateLayer.burst(mouse.x, mouse.y);
      if (root.action) root.action();
      else AudioService.toggleMute(root.target, root.muted);
    }
  }
}
