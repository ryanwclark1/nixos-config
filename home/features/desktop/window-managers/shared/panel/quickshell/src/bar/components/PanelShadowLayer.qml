import QtQuick
import "../../services"

// Soft stacked shadows behind the bar (used when shadowEnabled is on).
Item {
    id: root

    property bool shadowEnabled: false
    property bool autoHidden: false
    property bool floatingBar: false
    property real shadowOpacity: 0.3

    anchors.fill: parent

    Repeater {
        model: root.shadowEnabled ? 3 : 0
        Rectangle {
            readonly property real spread: [2, 5, 8][index]
            readonly property real baseAlpha: [0.5, 0.25, 0.1][index]
            visible: !root.autoHidden
            anchors.fill: parent
            anchors.margins: -spread
            z: -1 - index
            radius: root.floatingBar ? Appearance.radiusMedium + spread : 0
            color: Qt.rgba(0, 0, 0, root.shadowOpacity * baseAlpha)
        }
    }
}
