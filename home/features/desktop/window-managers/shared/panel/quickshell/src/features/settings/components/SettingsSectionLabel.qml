import QtQuick
import QtQuick.Layouts
import "../../../services"

ColumnLayout {
  id: root
  property alias text: labelText.text
  Layout.fillWidth: true
  Layout.topMargin: Colors.spacingL
  Layout.bottomMargin: Colors.spacingS
  spacing: Colors.spacingS

  Rectangle {
    Layout.fillWidth: true
    height: 1
    color: Colors.border
    opacity: 0.35
  }

  Text {
    id: labelText
    color: Colors.textDisabled
    font.pixelSize: Colors.fontSizeXS
    font.weight: Font.Black
    font.letterSpacing: Colors.letterSpacingExtraWide
    Layout.leftMargin: Colors.spacingS
  }
}
