import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

ColumnLayout {
  id: root

  required property string osdIcon
  required property color osdColor
  required property string osdLabel

  anchors.fill: parent
  anchors.margins: Appearance.spacingL
  spacing: Appearance.spacingM

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

    Loader {
      anchors.centerIn: parent
      sourceComponent: String(root.osdIcon).endsWith(".svg") ? _alertSvg : _alertNerd
    }
    Component { id: _alertSvg; SharedWidgets.SvgIcon { source: root.osdIcon; color: root.osdColor; size: Appearance.fontSizeDisplay } }
    Component { id: _alertNerd; Text { text: root.osdIcon; color: root.osdColor; font.pixelSize: Appearance.fontSizeDisplay; font.family: Appearance.fontMono } }
  }

  Text {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.NoWrap
    text: root.osdLabel
    color: Colors.text
    font.pixelSize: Appearance.fontSizeXL
    font.weight: Font.Black
    font.family: Appearance.fontMono
  }

  Text {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: "Check system load and temperature"
    color: Colors.textSecondary
    font.pixelSize: Appearance.fontSizeSmall
    font.weight: Font.Medium
    elide: Text.ElideRight
  }
}
