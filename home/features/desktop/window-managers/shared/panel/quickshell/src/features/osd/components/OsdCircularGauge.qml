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

  readonly property real scaleFactor: Math.max(0.1, (parent && parent.width > 0) ? parent.width / 180.0 : 1.0)

  anchors.fill: parent
  anchors.margins: Math.round(18 * scaleFactor)
  spacing: Math.round(Appearance.paddingSmall * scaleFactor)

  CircularGauge {
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: Math.round(78 * root.scaleFactor)
    Layout.preferredHeight: Math.round(78 * root.scaleFactor)
    width: Layout.preferredWidth
    height: Layout.preferredHeight
    thickness: Math.max(2, Math.round(6 * root.scaleFactor))
    value: Math.min(root.currentValue, 1.0)
    color: root.osdColor
    icon: root.osdIcon
  }

  Text {
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: root.osdLabel
    color: Colors.text
    font.pixelSize: Math.round(Appearance.fontSizeXL * root.scaleFactor)
    font.weight: Font.Black
    font.family: Appearance.fontMono
  }

  Text {
    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: root.osdType === "kbdbrightness" ? "KBD BRIGHTNESS" : root.osdType.toUpperCase()
    color: root.osdColor
    font.pixelSize: Math.round(Appearance.fontSizeXS * root.scaleFactor)
    font.weight: Font.Black
    font.letterSpacing: Appearance.letterSpacingExtraWide * root.scaleFactor
  }
}
