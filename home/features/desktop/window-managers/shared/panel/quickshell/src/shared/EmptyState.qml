import QtQuick
import QtQuick.Layouts
import "../services"

ColumnLayout {
    id: root
    property string icon: "󰟢"
    property string message: "Nothing here"
    property int iconSize: 32

    spacing: Colors.spacingS

    Loader {
        sourceComponent: root.icon.endsWith(".svg") ? _svgIcon : _nerdIcon
        Layout.alignment: Qt.AlignHCenter
    }
    Component {
        id: _svgIcon
        SvgIcon { source: root.icon; color: Colors.textDisabled; size: root.iconSize }
    }
    Component {
        id: _nerdIcon
        Text {
            text: root.icon
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: root.iconSize
        }
    }

    Text {
        text: root.message
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeSmall
        Layout.alignment: Qt.AlignHCenter
    }
}
