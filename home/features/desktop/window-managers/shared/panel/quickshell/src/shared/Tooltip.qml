import QtQuick
import Quickshell
import "../services"

Item {
    id: root

    property string text: ""
    property string shortcut: ""
    property bool shown: false
    property int preferredSide: Qt.BottomEdge
    property int showDelay: 500
    property Item anchorItem: null
    property var anchorWindow: null
    property bool cursorAware: true
    property point hoverPoint: Qt.point(-1, -1)
    property int cursorClearance: Appearance.spacingM
    property int popupGap: Appearance.spacingS
    property int popupSideMargin: Appearance.spacingXS
    property int popupMaxWidth: 280
    property int popupLabelMaxWidth: 200
    property int popupAdjustment: PopupAdjustment.Flip | PopupAdjustment.Slide

    readonly property Item effectiveAnchorItem: anchorItem ? anchorItem : parent
    readonly property var resolvedAnchorWindow: {
        if (anchorWindow)
            return anchorWindow;
        if (effectiveAnchorItem && effectiveAnchorItem.Window && effectiveAnchorItem.Window.window)
            return effectiveAnchorItem.Window.window;
        if (root.Window && root.Window.window)
            return root.Window.window;
        return null;
    }
    readonly property bool usePopup: !!resolvedAnchorWindow && !!effectiveAnchorItem
    readonly property bool useInlineTooltip: !usePopup
    readonly property bool bubbleVisible: text !== "" && (usePopup ? popupTooltip.visible : root.visible)
    property int effectiveSide: preferredSide
    property point effectiveHoverPoint: Qt.point(-1, -1)

    anchors.fill: useInlineTooltip ? parent : undefined
    visible: false
    // Render above siblings
    z: 1000

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value));
    }

    function itemSize() {
        return Qt.size(
            effectiveAnchorItem ? Math.max(1, effectiveAnchorItem.width || 0) : 1,
            effectiveAnchorItem ? Math.max(1, effectiveAnchorItem.height || 0) : 1
        );
    }

    function hasHoverPoint(pointValue) {
        return !!pointValue && pointValue.x !== undefined && pointValue.y !== undefined
            && pointValue.x >= 0 && pointValue.y >= 0;
    }

    function sanitizedHoverPoint(pointValue) {
        var size = itemSize();
        if (!hasHoverPoint(pointValue))
            return Qt.point(size.width / 2, size.height / 2);
        return Qt.point(
            clamp(pointValue.x, 0, size.width),
            clamp(pointValue.y, 0, size.height)
        );
    }

    function sideSpace(side) {
        if (!resolvedAnchorWindow || !effectiveAnchorItem || !resolvedAnchorWindow.itemRect)
            return 0;
        var rect = resolvedAnchorWindow.itemRect(effectiveAnchorItem);
        if (!rect)
            return 0;
        switch (side) {
            case Qt.LeftEdge:
                return rect.x;
            case Qt.RightEdge:
                return Math.max(0, resolvedAnchorWindow.width - (rect.x + rect.width));
            case Qt.TopEdge:
                return rect.y;
            default:
                return Math.max(0, resolvedAnchorWindow.height - (rect.y + rect.height));
        }
    }

    function popupExtentForSide(side) {
        return (side === Qt.LeftEdge || side === Qt.RightEdge)
            ? popupTooltip.implicitWidth + popupGap
            : popupTooltip.implicitHeight + popupGap;
    }

    function sideOrder(initialSide) {
        var horizontalFirst = sideSpace(Qt.LeftEdge) >= sideSpace(Qt.RightEdge)
            ? [Qt.LeftEdge, Qt.RightEdge]
            : [Qt.RightEdge, Qt.LeftEdge];
        var verticalFirst = sideSpace(Qt.TopEdge) >= sideSpace(Qt.BottomEdge)
            ? [Qt.TopEdge, Qt.BottomEdge]
            : [Qt.BottomEdge, Qt.TopEdge];
        var ordered = [initialSide];
        var fallbacks = [];

        switch (initialSide) {
            case Qt.LeftEdge:
            case Qt.RightEdge:
                fallbacks = [initialSide === Qt.LeftEdge ? Qt.RightEdge : Qt.LeftEdge].concat(verticalFirst);
                break;
            case Qt.TopEdge:
            case Qt.BottomEdge:
                fallbacks = [initialSide === Qt.TopEdge ? Qt.BottomEdge : Qt.TopEdge].concat(horizontalFirst);
                break;
            default:
                fallbacks = verticalFirst.concat(horizontalFirst);
                break;
        }

        for (var i = 0; i < fallbacks.length; ++i) {
            if (ordered.indexOf(fallbacks[i]) === -1)
                ordered.push(fallbacks[i]);
        }
        return ordered;
    }

    function cursorSuggestedSide(pointValue) {
        if (!cursorAware || !hasHoverPoint(pointValue))
            return preferredSide;
        var size = itemSize();
        var dx = pointValue.x - size.width / 2;
        var dy = pointValue.y - size.height / 2;
        if (Math.abs(dx) > Math.abs(dy))
            return dx >= 0 ? Qt.LeftEdge : Qt.RightEdge;
        return dy >= 0 ? Qt.TopEdge : Qt.BottomEdge;
    }

    function chooseBestSide(pointValue) {
        var ordered = sideOrder(cursorSuggestedSide(pointValue));
        for (var i = 0; i < ordered.length; ++i) {
            if (sideSpace(ordered[i]) >= popupExtentForSide(ordered[i]))
                return ordered[i];
        }

        var bestSide = ordered[0];
        var bestSpace = sideSpace(bestSide);
        for (var j = 1; j < ordered.length; ++j) {
            var candidate = ordered[j];
            var candidateSpace = sideSpace(candidate);
            if (candidateSpace > bestSpace) {
                bestSide = candidate;
                bestSpace = candidateSpace;
            }
        }
        return bestSide;
    }

    function freezePlacement() {
        effectiveHoverPoint = sanitizedHoverPoint(hoverPoint);
        effectiveSide = chooseBestSide(effectiveHoverPoint);
    }

    function anchorRectPoint() {
        var pointValue = effectiveHoverPoint;
        if (!hasHoverPoint(pointValue))
            pointValue = sanitizedHoverPoint(hoverPoint);
        var size = itemSize();
        var x = clamp(pointValue.x, 0, size.width);
        var y = clamp(pointValue.y, 0, size.height);

        switch (effectiveSide) {
            case Qt.LeftEdge:
                x = clamp(x - cursorClearance, 0, size.width);
                break;
            case Qt.RightEdge:
                x = clamp(x + cursorClearance, 0, size.width);
                break;
            case Qt.TopEdge:
                y = clamp(y - cursorClearance, 0, size.height);
                break;
            case Qt.BottomEdge:
                y = clamp(y + cursorClearance, 0, size.height);
                break;
        }

        return Qt.point(x, y);
    }

    function anchorRectX() {
        if (!resolvedAnchorWindow || !effectiveAnchorItem || !resolvedAnchorWindow.itemRect)
            return 0;
        var rect = resolvedAnchorWindow.itemRect(effectiveAnchorItem);
        var pointValue = anchorRectPoint();
        return rect.x + pointValue.x;
    }

    function anchorRectY() {
        if (!resolvedAnchorWindow || !effectiveAnchorItem || !resolvedAnchorWindow.itemRect)
            return 0;
        var rect = resolvedAnchorWindow.itemRect(effectiveAnchorItem);
        var pointValue = anchorRectPoint();
        return rect.y + pointValue.y;
    }

    Timer {
        id: showTimer
        interval: root.showDelay
        onTriggered: {
            root.freezePlacement();
            if (root.usePopup) {
                root.updatePopupAnchor();
                popupTooltip.visible = true;
            } else {
                root.visible = true;
            }
        }
    }

    function updatePopupAnchor() {
        if (!usePopup || !popupTooltip.visible || !popupTooltip.anchor || !popupTooltip.anchor.updateAnchor)
            return;
        popupTooltip.anchor.updateAnchor();
    }

    onShownChanged: {
        if (shown && text !== "") {
            showTimer.restart();
        } else {
            showTimer.stop();
            root.visible = false;
            popupTooltip.visible = false;
        }
    }

    onResolvedAnchorWindowChanged: Qt.callLater(updatePopupAnchor)
    onEffectiveAnchorItemChanged: Qt.callLater(updatePopupAnchor)
    onHoverPointChanged: {
        if (shown && !popupTooltip.visible)
            freezePlacement();
    }
    onPreferredSideChanged: {
        if (!shown)
            effectiveSide = preferredSide;
    }

    Connections {
        target: root.effectiveAnchorItem
        ignoreUnknownSignals: true
        function onXChanged() { root.updatePopupAnchor(); }
        function onYChanged() { root.updatePopupAnchor(); }
        function onWidthChanged() { root.updatePopupAnchor(); }
        function onHeightChanged() { root.updatePopupAnchor(); }
        function onVisibleChanged() { root.updatePopupAnchor(); }
    }

    Rectangle {
        id: bubble
        visible: root.useInlineTooltip

        readonly property int _paddingH: Appearance.spacingM
        readonly property int _paddingV: Appearance.spacingXS
        readonly property int _gap: Appearance.spacingS

        width: Math.min(root.popupMaxWidth, tooltipRow.implicitWidth + _paddingH * 2)
        height: tooltipRow.implicitHeight + _paddingV * 2

        // Center horizontally (or vertically for left/right sides), offset past parent edge
        x: {
            switch (root.effectiveSide) {
                case Qt.LeftEdge:  return -width - _gap;
                case Qt.RightEdge: return parent.width + _gap;
                default: {
                    var pointValue = root.anchorRectPoint();
                    return root.clamp(pointValue.x - width / 2, 0, parent.width - width);
                }
            }
        }
        y: {
            switch (root.effectiveSide) {
                case Qt.TopEdge:   return -height - _gap;
                case Qt.LeftEdge:
                case Qt.RightEdge: {
                    var pointValue = root.anchorRectPoint();
                    return root.clamp(pointValue.y - height / 2, 0, parent.height - height);
                }
                default:
                    return parent.height + _gap;  // Bottom
            }
        }

        radius: Appearance.radiusXS
        color: Colors.withAlpha(Colors.surface, 0.95)
        border.color: Colors.border
        border.width: 1

        opacity: root.bubbleVisible ? 1 : 0
        scale: root.bubbleVisible ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutCubic } }

        Row {
            id: tooltipRow
            anchors.centerIn: parent
            spacing: Appearance.spacingXS

            Text {
                id: tooltipLabel
                width: Math.min(root.popupLabelMaxWidth, implicitWidth)
                text: root.text
                color: Colors.text
                font.pixelSize: Appearance.fontSizeSmall
                wrapMode: Text.WordWrap
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                visible: root.shortcut !== ""
                anchors.verticalCenter: parent.verticalCenter
                radius: Appearance.radiusMicro
                color: Colors.withAlpha(Colors.text, 0.12)
                width: shortcutLabel.implicitWidth + Appearance.spacingXS * 2
                height: shortcutLabel.implicitHeight + 4

                Text {
                    id: shortcutLabel
                    anchors.centerIn: parent
                    text: root.shortcut
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    font.family: Appearance.fontMono
                }
            }
        }
    }

    PopupWindow {
        id: popupTooltip
        anchor.window: root.resolvedAnchorWindow
        anchor.edges: {
            switch (root.effectiveSide) {
                case Qt.LeftEdge:
                    return Edges.Left;
                case Qt.RightEdge:
                    return Edges.Right;
                case Qt.TopEdge:
                    return Edges.Top;
                default:
                    return Edges.Bottom;
            }
        }
        anchor.gravity: anchor.edges
        anchor.adjustment: root.popupAdjustment
        anchor.rect.x: root.anchorRectX()
        anchor.rect.y: root.anchorRectY()
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.margins {
            top: root.effectiveSide === Qt.TopEdge ? root.popupGap : root.popupSideMargin
            bottom: root.effectiveSide === Qt.BottomEdge ? root.popupGap : root.popupSideMargin
            left: root.effectiveSide === Qt.LeftEdge ? root.popupGap : root.popupSideMargin
            right: root.effectiveSide === Qt.RightEdge ? root.popupGap : root.popupSideMargin
        }

        visible: false
        color: "transparent"
        implicitWidth: popupBubble.implicitWidth
        implicitHeight: popupBubble.implicitHeight
        onVisibleChanged: {
            if (visible)
                Qt.callLater(root.updatePopupAnchor);
        }

        Rectangle {
            id: popupBubble

            readonly property int paddingH: Appearance.spacingM
            readonly property int paddingV: Appearance.spacingXS

            implicitWidth: Math.min(root.popupMaxWidth, popupRow.implicitWidth + paddingH * 2)
            implicitHeight: popupRow.implicitHeight + paddingV * 2
            width: implicitWidth
            height: implicitHeight
            radius: Appearance.radiusXS
            color: Colors.withAlpha(Colors.surface, 0.95)
            border.color: Colors.border
            border.width: 1

            opacity: root.bubbleVisible ? 1 : 0
            scale: root.bubbleVisible ? 1 : 0.92

            Behavior on opacity { NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutCubic } }

            Row {
                id: popupRow
                anchors.centerIn: parent
                spacing: Appearance.spacingXS

                Text {
                    width: Math.min(root.popupLabelMaxWidth, implicitWidth)
                    text: root.text
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeSmall
                    wrapMode: Text.WordWrap
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    visible: root.shortcut !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Appearance.radiusMicro
                    color: Colors.withAlpha(Colors.text, 0.12)
                    width: popupShortcutLabel.implicitWidth + Appearance.spacingXS * 2
                    height: popupShortcutLabel.implicitHeight + 4

                    Text {
                        id: popupShortcutLabel
                        anchors.centerIn: parent
                        text: root.shortcut
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXS
                        font.family: Appearance.fontMono
                    }
                }
            }
        }
    }
}
