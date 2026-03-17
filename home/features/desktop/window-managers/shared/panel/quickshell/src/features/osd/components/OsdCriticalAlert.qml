import QtQuick
import QtQuick.Layouts
import "../../../services"

ColumnLayout {
  id: root

  required property string osdIcon
  required property color osdColor
  required property string osdLabel

  anchors.fill: parent
  anchors.margins: Colors.spacingL
  spacing: Colors.spacingM

  Item {
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: 76
    Layout.preferredHeight: 76

    Rectangle {
      anchors.centerIn: parent
      width: 76
      height: 76
      radius: width / 2
      color: Colors.withAlpha(root.osdColor, 0.14)
      border.color: root.osdColor
      border.width: 2
    }

    Text {
      anchors.centerIn: parent
      text: root.osdIcon
      color: root.osdColor
      font.pixelSize: Colors.fontSizeDisplay
      font.family: Colors.fontMono
    }
  }

  Text {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.NoWrap
    text: root.osdLabel
    color: Colors.text
    font.pixelSize: Colors.fontSizeXL
    font.weight: Font.Black
    font.family: Colors.fontMono
  }

  Text {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: "Check system load and temperature"
    color: Colors.textSecondary
    font.pixelSize: Colors.fontSizeSmall
    font.weight: Font.Medium
    elide: Text.ElideRight
  }
}
