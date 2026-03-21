import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import "../services"

Item {
    id: root

    property string source: ""
    property color color
    property bool colorize: color.a > 0 || _forceColorize
    property bool _forceColorize: false
    property string folder: "fluent"
    property int size: Appearance.iconSizeSmall

    // Row/Column and BarPill use implicit sizes for measurement; explicit width/height alone stay 0 implicit.
    implicitWidth: size
    implicitHeight: size

    // Support "brands/icon-name.svg" in source — auto-splits folder
    readonly property string _resolvedFolder: {
        var idx = source.indexOf("/");
        return idx > 0 ? source.substring(0, idx) : folder;
    }
    readonly property string _resolvedSource: {
        var idx = source.indexOf("/");
        return idx > 0 ? source.substring(idx + 1) : source;
    }

    width: size
    height: size

    IconImage {
        id: iconImage
        anchors.fill: parent
        source: root._resolvedSource ? Qt.resolvedUrl("../assets/icons/" + root._resolvedFolder + "/" + root._resolvedSource) : ""
        implicitSize: root.size
        visible: true

        layer.enabled: root.colorize
        layer.effect: ColorOverlay {
            color: root.color
        }
    }
}
