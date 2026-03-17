import QtQuick
import "../services"

Rectangle {
  id: root

  property string icon: ""
  property int size: 30
  property int iconSize: Colors.fontSizeLarge
  property color iconColor: Colors.textSecondary
  property color normalColor: "transparent"
  property color hoverColor: "transparent"
  property color activeColor: hoverColor
  property color stateColor: Colors.text

  signal clicked(real x, real y)

  width: size
  height: size
  radius: height / 2
  color: hoverArea.pressed ? root.activeColor : (hoverArea.containsMouse ? root.hoverColor : root.normalColor)

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: root.iconColor
    font.family: Colors.fontMono
    font.pixelSize: root.iconSize
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
}
