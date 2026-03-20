import QtQuick
import QtQuick.Layouts
import "../services"

RowLayout {
  id: root

  property string label: ""
  property string value: ""
  property color valueColor: Colors.text

  spacing: Appearance.spacingS

  Text {
    text: root.label
    color: Colors.textDisabled
    font.pixelSize: Appearance.fontSizeXS
    font.weight: Font.Medium
  }

  Item {
    Layout.fillWidth: true
  }

  Text {
    text: root.value
    color: root.valueColor
    font.pixelSize: Appearance.fontSizeSmall
    font.weight: Font.DemiBold
    elide: Text.ElideRight
    Layout.alignment: Qt.AlignRight
  }
}
