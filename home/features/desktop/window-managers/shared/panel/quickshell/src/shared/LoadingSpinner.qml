import QtQuick
import "../services"

Item {
    id: root
    property int size: Appearance.iconSizeSmall
    property color color: Colors.primary

    width: size
    height: size

    SvgIcon {
        anchors.centerIn: parent
        source: "arrow-clockwise.svg"
        color: root.color
        size: root.size

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: Appearance.durationAmbientShort
            loops: Animation.Infinite
        }
    }
}
