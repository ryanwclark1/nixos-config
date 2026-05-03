import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../modules"

ColumnLayout {
  id: root

  required property real currentValue
  required property color osdColor
  required property string osdIcon
  required property string osdLabel
  required property string osdType

  readonly property real scaleFactor: parent.width / 180.0

  anchors.fill: parent
  anchors.margins: 18 * scaleFactor
  spacing: Appearance.paddingSmall * scaleFactor

  CircularGauge {
    Layout.alignment: Qt.AlignHCenter
    width: 78 * root.scaleFactor
    height: 78 * root.scaleFactor
    thickness: 6 * root.scaleFactor
    value: Math.min(root.currentValue, 1.0)
    color: root.osdColor
    icon: root.osdIcon
  }

  Text {
    Layout.alignment: Qt.AlignHCenter
    text: root.osdLabel
    color: Colors.text
    font.pixelSize: Appearance.fontSizeXL * root.scaleFactor
    font.weight: Font.Black
    font.family: Appearance.fontMono
  }

  Text {
    Layout.alignment: Qt.AlignHCenter
    text: root.osdType === "kbdbrightness" ? "KBD BRIGHTNESS" : root.osdType.toUpperCase()
    color: root.osdColor
    font.pixelSize: Appearance.fontSizeXS * root.scaleFactor
    font.weight: Font.Black
    font.letterSpacing: Appearance.letterSpacingExtraWide * root.scaleFactor
  }
}
