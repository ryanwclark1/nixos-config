import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../modules"

ColumnLayout {
  id: root

  required property real currentValue
  required property real maxValue
  required property color osdColor
  required property string osdIcon
  required property string osdLabel
  required property string osdType

  anchors.fill: parent
  anchors.margins: 18
  spacing: Colors.paddingSmall

  CircularGauge {
    Layout.alignment: Qt.AlignHCenter
    width: 78
    height: 78
    thickness: 6
    value: Math.min(root.currentValue / root.maxValue, 1.0)
    color: root.osdColor
    icon: root.osdIcon
  }

  Text {
    Layout.alignment: Qt.AlignHCenter
    text: root.osdLabel
    color: Colors.text
    font.pixelSize: Colors.fontSizeXL
    font.weight: Font.Black
    font.family: Colors.fontMono
  }

  Text {
    Layout.alignment: Qt.AlignHCenter
    text: root.osdType === "kbdbrightness" ? "KBD BRIGHTNESS" : root.osdType.toUpperCase()
    color: root.osdColor
    font.pixelSize: Colors.fontSizeXS
    font.weight: Font.Black
    font.letterSpacing: Colors.letterSpacingExtraWide
  }
}
