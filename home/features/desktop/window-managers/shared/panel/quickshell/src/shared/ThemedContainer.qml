import QtQuick
import "../services"

Rectangle {
    id: root

    property string variant: "card"
    property bool showHighlight: true
    property bool showGradient: true
    property real customHighlightOpacity: -1
    property bool hovered: false
    default property alias content: contentItem.data

    readonly property var _v: Colors.containerVariant(variant)

    color: _v.color
    border.color: _v.borderColor
    border.width: _v.borderWidth
    radius: _v.radius

    gradient: (showGradient && _v.gradient) ? _grad : null

    SurfaceGradient { id: _grad }

    InnerHighlight {
        visible: root.showHighlight && root._v.highlightOpacity > 0
        highlightOpacity: root.customHighlightOpacity >= 0
            ? root.customHighlightOpacity : root._v.highlightOpacity
        hovered: root.hovered
        hoveredOpacity: root.hovered ? root._v.highlightOpacity * 1.5 : 0
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
