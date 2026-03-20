import QtQuick
import "../services"

Loader {
    id: root
    property bool shown: true
    property int fadeDuration: Appearance.durationFast

    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.fadeDuration
            easing.type: Easing.OutCubic
        }
    }
}
