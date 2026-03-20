import QtQuick
import "."
import "../services"

Rectangle {
  id: root

  property string icon: ""
  property int size: 30
  property int iconSize: Appearance.fontSizeLarge
  property color iconColor: Colors.textSecondary
  property color normalColor: "transparent"
  property color hoverColor: "transparent"
  property color activeColor: hoverColor
  property color stateColor: Colors.text

  property string tooltipText: ""
  property string tooltipShortcut: ""

  signal clicked(real x, real y)

  Accessible.role: Accessible.Button
  Accessible.name: root.tooltipText || root.icon
  Accessible.description: root.tooltipText
  Accessible.onPressAction: root.clicked(width / 2, height / 2)

  width: size
  height: size
  radius: height / 2
  color: hoverArea.pressed ? root.activeColor : (hoverArea.containsMouse ? root.hoverColor : root.normalColor)

  Loader {
    anchors.centerIn: parent
    sourceComponent: String(root.icon).endsWith(".svg") ? _svgIcon : _nerdIcon
  }
  Component {
    id: _svgIcon
    SvgIcon { source: root.icon; color: root.iconColor; size: root.iconSize }
  }
  Component {
    id: _nerdIcon
    Text {
      text: root.icon
      color: root.iconColor
      font.family: Appearance.fontMono
      font.pixelSize: root.iconSize
    }
  }

  StateLayer {
    id: stateLayer
    hovered: hoverArea.containsMouse
    pressed: hoverArea.pressed
    stateColor: root.stateColor
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => { stateLayer.burst(mouse.x, mouse.y); root.clicked(mouse.x, mouse.y); }
  }

  Tooltip {
    text: root.tooltipText
    shortcut: root.tooltipShortcut
    shown: hoverArea.containsMouse && root.tooltipText !== ""
  }
}
