import QtQuick
import QtQuick.Layouts
import "../services"

ColumnLayout {
    id: root
    property string icon: "󰟢"
    property string message: "Nothing here"
    property int iconSize: 32

    spacing: Colors.spacingS

    Text {
        text: root.icon
        color: Colors.textDisabled
        font.family: Colors.fontMono
        font.pixelSize: root.iconSize
        Layout.alignment: Qt.AlignHCenter
    }

    Text {
        text: root.message
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeSmall
        Layout.alignment: Qt.AlignHCenter
    }
}
