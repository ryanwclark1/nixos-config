import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
    id: root
    property string icon: ""
    property bool active: false

    visible: root.icon !== ""
    width: 38
    height: 38
    radius: Colors.radiusSmall
    color: root.active
        ? Colors.withAlpha(Colors.primary, 0.14)
        : Colors.withAlpha(Colors.text, 0.06)
    border.color: root.active
        ? Colors.withAlpha(Colors.primary, 0.6)
        : Colors.border
    border.width: 1
    Layout.alignment: Qt.AlignTop

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? Colors.primary : Colors.textSecondary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeXL
    }
}
