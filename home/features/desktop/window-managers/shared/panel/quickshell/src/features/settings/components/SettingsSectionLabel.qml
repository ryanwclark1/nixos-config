import QtQuick
import QtQuick.Layouts
import "../../../services"

RowLayout {
    id: root

    property alias text: labelText.text

    Layout.fillWidth: true
    Layout.topMargin: Colors.spacingL
    Layout.bottomMargin: Colors.spacingS
    spacing: Colors.spacingS

    Rectangle {
        implicitHeight: 24
        implicitWidth: labelText.implicitWidth + Colors.spacingM * 2
        radius: Colors.radiusPill
        color: Colors.primarySubtle
        border.color: Colors.primaryRing
        border.width: 1

        Text {
            id: labelText
            anchors.centerIn: parent
            color: Colors.primary
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Colors.letterSpacingExtraWide
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        radius: 1
        color: Colors.withAlpha(Colors.border, 0.65)
    }
}
