import QtQuick
import "../../../services"

Text {
    id: root

    property string title: ""

    text: title
    color: Colors.textDisabled
    font.pixelSize: Appearance.fontSizeXS
    font.weight: Font.Black
    font.letterSpacing: Appearance.letterSpacingWide
}
