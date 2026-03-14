import QtQuick
import "../services"

Rectangle {
  id: root

  property string icon: ""
  property int size: 30
  property int iconSize: Colors.fontSizeLarge
  property color iconColor: Colors.textSecondary

  signal clicked(real x, real y)

  width: size
  height: size
  radius: height / 2
  color: "transparent"

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
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => { stateLayer.burst(mouse.x, mouse.y); root.clicked(mouse.x, mouse.y); }
  }
}
