import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared" as Shared

Rectangle {
    id: root
    property string icon: ""
    property bool active: false

    visible: root.icon !== ""
    width: Appearance.controlRowHeight
    height: Appearance.controlRowHeight
    radius: Appearance.radiusSmall
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
        Shared.SvgIcon { source: root.icon; color: root.active ? Colors.primary : Colors.textSecondary; size: Appearance.fontSizeXL }
    }
    Component {
        id: _nerdIcon
        Text {
            text: root.icon
            color: root.active ? Colors.primary : Colors.textSecondary
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeXL
        }
    }
}
