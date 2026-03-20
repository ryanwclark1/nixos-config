import QtQuick
import QtQuick.Layouts
import "."
import "../services"

ColumnLayout {
    id: root
    property string icon: "empty.svg"
    property string message: "Nothing here"
    property int iconSize: Appearance.iconSizeMedium

    spacing: Appearance.spacingS

    Loader {
        sourceComponent: String(root.icon).endsWith(".svg") ? _svgIcon : _nerdIcon
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
            font.family: Appearance.fontMono
            font.pixelSize: root.iconSize
        }
    }

    Text {
        text: root.message
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeSmall
        Layout.alignment: Qt.AlignHCenter
    }
}
