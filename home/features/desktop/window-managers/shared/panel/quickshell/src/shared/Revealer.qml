import QtQuick
import "../services"

Item {
    id: root
    property bool reveal: false
    property bool vertical: true
    property int animDuration: Colors.durationMedium
    clip: true

    default property alias content: root.data

    implicitWidth: vertical ? childrenRect.width : (reveal ? childrenRect.width : 0)
    implicitHeight: vertical ? (reveal ? childrenRect.height : 0) : childrenRect.height
    visible: reveal || (width > 0 && height > 0)

    Behavior on implicitWidth {
        enabled: !root.vertical
        NumberAnimation {
            duration: root.animDuration
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitHeight {
        enabled: root.vertical
        NumberAnimation {
            duration: root.animDuration
            easing.type: Easing.OutCubic
        }
    }
}
