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

  width: size; height: size; radius: size / 2
  color: hover.containsMouse ? Colors.highlightLight : (showBorder ? Colors.bgWidget : "transparent")
  border.color: showBorder ? Colors.border : "transparent"
  border.width: showBorder ? 1 : 0

  Text {
    anchors.centerIn: parent
    text: root.muted ? root.mutedIcon : root.icon
    color: root.muted ? Colors.error : Colors.textSecondary
    font.family: Colors.fontMono
    font.pixelSize: Math.round(root.size * 0.5)
  }

  MouseArea {
    id: hover
    anchors.fill: parent
    hoverEnabled: true
    onClicked: AudioService.toggleMute(root.target, root.muted)
  }
}
