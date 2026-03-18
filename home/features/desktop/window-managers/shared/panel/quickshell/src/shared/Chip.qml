import QtQuick
import "../services"

Rectangle {
  id: root

  property string icon: ""
  property string text: ""
  property color iconColor: Colors.accent
  property color textColor: Colors.text
  property color bgColor: Colors.withAlpha(root.iconColor, 0.16)
  property color borderColor: Colors.withAlpha(Colors.textDisabled, 0.06)

  radius: Colors.radiusPill
  color: root.bgColor
  border.color: root.borderColor
  border.width: 1
  implicitWidth: row.implicitWidth + 14
  implicitHeight: 22

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Colors.spacingXS

    Text {
      text: root.icon
      color: root.iconColor
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Black
      visible: root.icon !== ""
    }

    Text {
      text: root.text
      color: root.textColor
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Bold
    }
  }
}
