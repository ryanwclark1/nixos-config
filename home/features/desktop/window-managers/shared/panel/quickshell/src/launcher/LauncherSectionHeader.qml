import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root

    required property string section
    required property bool compactMode
    property color accentColor: Colors.primary

    width: ListView.view ? ListView.view.width : 0
    height: compactMode ? 30 : 36

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: root.compactMode ? Appearance.spacingXXS : Appearance.spacingXS
        spacing: root.compactMode ? Appearance.spacingXS : Appearance.spacingS

        Rectangle {
            width: compactMode ? 8 : 10
            height: width
            radius: Appearance.radiusPill
            color: root.accentColor
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.section
            color: Colors.withAlpha(root.accentColor, 0.94)
            font.pixelSize: root.compactMode ? Appearance.fontSizeXS : Appearance.fontSizeSmall
            font.weight: Font.Black
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Appearance.letterSpacingWide
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: 1
            radius: Appearance.radiusXXXS
            color: Colors.withAlpha(root.accentColor, 0.16)
        }
    }
}
