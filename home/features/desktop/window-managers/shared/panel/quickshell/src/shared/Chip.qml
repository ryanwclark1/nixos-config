import QtQuick
import "."
import "../services"

Rectangle {
  id: root

  property string icon: ""
  property string text: ""
  property color iconColor: Colors.accent
  property color textColor: Colors.text
  property color bgColor: Colors.withAlpha(root.iconColor, 0.16)
  property color borderColor: Colors.withAlpha(Colors.textDisabled, 0.06)

  radius: Appearance.radiusPill
  color: root.bgColor
  border.color: root.borderColor
  border.width: 1
  implicitWidth: row.implicitWidth + 14
  implicitHeight: 22

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Appearance.spacingXS

    Loader {
      visible: root.icon !== ""
      sourceComponent: root.icon.endsWith(".svg") ? _chSvg : _chNerd
    }
    Component { id: _chSvg; SvgIcon { source: root.icon; color: root.iconColor; size: Appearance.fontSizeXS } }
    Component { id: _chNerd; Text { text: root.icon; color: root.iconColor; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Black } }

    Text {
      text: root.text
      color: root.textColor
      font.pixelSize: Appearance.fontSizeXS
      font.weight: Font.Bold
    }
  }
}
