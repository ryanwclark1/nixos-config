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

    anchors.fill: useInlineTooltip ? parent : undefined
    visible: false
    // Render above siblings
    z: 1000

    Timer {
        id: showTimer
        interval: root.showDelay
        onTriggered: {
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
            switch (root.preferredSide) {
                case Qt.LeftEdge:  return -width - _gap;
                case Qt.RightEdge: return parent.width + _gap;
                default:           return (parent.width - width) / 2;
            }
        }
        y: {
            switch (root.preferredSide) {
                case Qt.TopEdge:   return -height - _gap;
                case Qt.LeftEdge:  // fall-through
                case Qt.RightEdge: return (parent.height - height) / 2;
                default:           return parent.height + _gap;  // Bottom
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
        anchor.item: root.effectiveAnchorItem
        anchor.edges: {
            switch (root.preferredSide) {
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
        anchor.margins {
            top: root.preferredSide === Qt.TopEdge ? root.popupGap : root.popupSideMargin
            bottom: root.preferredSide === Qt.BottomEdge ? root.popupGap : root.popupSideMargin
            left: root.preferredSide === Qt.LeftEdge ? root.popupGap : root.popupSideMargin
            right: root.preferredSide === Qt.RightEdge ? root.popupGap : root.popupSideMargin
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
