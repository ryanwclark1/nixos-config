import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string source: ""
    property color color
    property bool colorize: color != undefined && color != "transparent" && color.toString() !== "#000000" || _forceColorize
    property bool _forceColorize: false
    property string folder: "fluent"
    property int size: 24

    width: size
    height: size

    IconImage {
        id: iconImage
        anchors.fill: parent
        source: root.source ? Qt.resolvedUrl("../assets/icons/" + root.folder + "/" + root.source) : ""
        implicitSize: root.size
    }

    Loader {
        active: root.colorize
        anchors.fill: iconImage
        sourceComponent: ColorOverlay {
            source: iconImage
            color: root.color
        }
    }
}
