import QtQuick
import "../services"

Item {
    id: root
    property int size: Appearance.iconSizeSmall
    property color color: Colors.primary

    width: size
    height: size

    Text {
        anchors.centerIn: parent
        text: "󰑓"
        color: root.color
        font.family: Appearance.fontMono
        font.pixelSize: root.size

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: Appearance.durationAmbientShort
            loops: Animation.Infinite
        }
    }
}
