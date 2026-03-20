import QtQuick
import QtQuick.Layouts
import "../../../services"

RowLayout {
    id: root

    property alias text: labelText.text

    Layout.fillWidth: true
    Layout.topMargin: Appearance.spacingL
    Layout.bottomMargin: Appearance.spacingS
    spacing: Appearance.spacingS

    Rectangle {
        implicitHeight: 24
        implicitWidth: labelText.implicitWidth + Appearance.spacingM * 2
        radius: Appearance.radiusPill
        color: Colors.primarySubtle
        border.color: Colors.primaryRing
        border.width: 1

        Text {
            id: labelText
            anchors.centerIn: parent
            color: Colors.primary
            font.pixelSize: Appearance.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Appearance.letterSpacingExtraWide
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        radius: 1
        color: Colors.withAlpha(Colors.border, 0.65)
    }
}
