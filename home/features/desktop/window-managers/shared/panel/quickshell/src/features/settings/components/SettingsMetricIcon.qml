import QtQuick
import "../../../services"
import "../../../shared" as Shared

Loader {
    id: root
    property string icon: ""
    property color iconColor: Colors.primary
    property int iconSize: Appearance.fontSizeLarge

    sourceComponent: root.icon.endsWith(".svg") ? _svgComp : _nerdComp

    Component {
        id: _svgComp
        Shared.SvgIcon { source: root.icon; color: root.iconColor; size: root.iconSize }
    }
    Component {
        id: _nerdComp
        Text {
            text: root.icon
            color: root.iconColor
            font.family: Appearance.fontMono
            font.pixelSize: root.iconSize
        }
    }
}
