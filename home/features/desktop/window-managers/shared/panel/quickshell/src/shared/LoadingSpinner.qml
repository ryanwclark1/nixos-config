import QtQuick
import "../services"

Item {
    id: root
    property int size: Colors.iconSizeSmall
    property color color: Colors.primary

    width: size
    height: size

    Text {
        anchors.centerIn: parent
        text: "󰑓"
        color: root.color
        font.family: Colors.fontMono
        font.pixelSize: root.size

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: Colors.durationAmbientShort
            loops: Animation.Infinite
        }
    }
}
