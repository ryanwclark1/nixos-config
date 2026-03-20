import QtQuick
import QtQuick.Layouts
import "../../../services"

Item {
    id: root

    Layout.preferredWidth: 72
    Layout.preferredHeight: 72

    property real value: 0
    property color color: Colors.primary
    property string icon: ""
    property string label: ""

    CircularGauge {
        anchors.fill: parent
        value: root.value
        color: root.color
        thickness: 4
        icon: root.icon
        width: 72
        height: 72
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        text: root.label
        color: root.color
        font.pixelSize: Appearance.fontSizeXS
        font.weight: Font.Bold
        font.family: Appearance.fontMono
    }
}
