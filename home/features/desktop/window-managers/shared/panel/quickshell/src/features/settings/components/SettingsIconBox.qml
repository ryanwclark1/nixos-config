import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared" as Shared

Rectangle {
    id: root
    property string icon: ""
    property bool active: false

    visible: root.icon !== ""
    width: Colors.controlRowHeight
    height: Colors.controlRowHeight
    radius: Colors.radiusSmall
    color: root.active
        ? Colors.primaryAccent
        : Colors.textFaint
    border.color: root.active
        ? Colors.withAlpha(Colors.primary, 0.6)
        : Colors.border
    border.width: 1
    Layout.alignment: Qt.AlignTop

    Loader {
        anchors.centerIn: parent
        sourceComponent: root.icon.endsWith(".svg") ? _svgIcon : _nerdIcon
    }
    Component {
        id: _svgIcon
        Shared.SvgIcon { source: root.icon; color: root.active ? Colors.primary : Colors.textSecondary; size: Colors.fontSizeXL }
    }
    Component {
        id: _nerdIcon
        Text {
            text: root.icon
            color: root.active ? Colors.primary : Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeXL
        }
    }
}
