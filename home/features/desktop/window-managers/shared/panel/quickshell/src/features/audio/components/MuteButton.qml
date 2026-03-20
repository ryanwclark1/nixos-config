import QtQuick
import "../../../services"
import "../../../shared"
import "../../../widgets"

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

  Loader {
    anchors.centerIn: parent
    property string _ic: root.muted ? root.mutedIcon : root.icon
    property color _col: root.muted ? Colors.error : Colors.textSecondary
    sourceComponent: String(_ic).endsWith(".svg") ? _mbSvg : _mbNerd
  }
  Component {
    id: _mbSvg
    SvgIcon {
      source: root.muted ? root.mutedIcon : root.icon
      color: parent ? parent._col : Colors.textSecondary
      size: Math.round(root.size * 0.5)
    }
  }
  Component {
    id: _mbNerd
    Text {
      text: root.muted ? root.mutedIcon : root.icon
      color: parent ? parent._col : Colors.textSecondary
      font.family: Appearance.fontMono
      font.pixelSize: Math.round(root.size * 0.5)
    }
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

  Tooltip {
    text: root.muted ? "Unmute" : "Mute"
    shown: hover.containsMouse
  }
}
