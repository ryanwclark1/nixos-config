import QtQuick
import "../services"

Rectangle {
    id: root

    property string variant: "card"
    property bool showHighlight: true
    property bool showGradient: _variantGradient
    property real customHighlightOpacity: -1
    property bool hovered: false
    default property alias content: contentItem.data

    // Resolve variant properties via direct bindings so color changes propagate.
    color: _resolveColor()
    border.color: _resolveBorderColor()
    border.width: _resolveBorderWidth()
    radius: _resolveRadius()

    function _resolveColor() {
        switch (variant) {
        case "popup": return Colors.popupSurface;
        case "card": return Colors.cardSurface;
        case "elevated": return Colors.chipSurface;
        case "surface": return Qt.alpha(Colors.surface, Colors.opacitySurface);
        case "pill": return Qt.alpha(Colors.surface, Colors.opacityOverlay);
        default: return Colors.cardSurface;
        }
    }

    function _resolveBorderColor() {
        if (variant === "surface") return "transparent";
        return Colors.border;
    }

    function _resolveBorderWidth() {
        if (variant === "surface") return 0;
        return 1;
    }

    function _resolveRadius() {
        switch (variant) {
        case "popup": return Appearance.radiusLarge;
        case "card": return Appearance.radiusMedium;
        case "elevated": return Appearance.radiusCard;
        case "surface": return Appearance.radiusSmall;
        case "pill": return Appearance.radiusPill;
        default: return Appearance.radiusMedium;
        }
    }

    readonly property real _highlightOp: {
        switch (variant) {
        case "popup": return 0.15;
        case "card": return 0.1;
        case "elevated": return 0.08;
        case "surface": return 0;
        case "pill": return 0.08;
        default: return 0.1;
        }
    }

    readonly property bool _variantGradient: variant === "popup" || variant === "surface" || variant === "pill"

    gradient: showGradient ? _grad : null

    SurfaceGradient { id: _grad }

    InnerHighlight {
        visible: root.showHighlight && root._highlightOp > 0
        highlightOpacity: root.customHighlightOpacity >= 0
            ? root.customHighlightOpacity : root._highlightOp
        hovered: root.hovered
        hoveredOpacity: root.hovered ? root._highlightOp * 1.5 : 0
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
