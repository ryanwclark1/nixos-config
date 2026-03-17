import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../widgets"

// Lightweight popup surface for bar pill right-click context menus.
// One instance is shared across all bars/screens; call show() with actions.
PopupWindow {
    id: root

    property var model: []
    property int focusedIndex: -1
    property string barPosition: "top"

    readonly property int itemHeight: 32
    readonly property int separatorHeight: 9
    readonly property int menuPadding: Colors.spacingXS
    readonly property int menuWidth: 200
    readonly property int maxLayerTextureSize: 4096

    color: "transparent"
    visible: false
    implicitWidth: menuWidth + 2
    implicitHeight: menuPadding * 2 + contentColumn.implicitHeight + 2

    function allowLayer(width, height) {
        return width > 0 && height > 0
            && width <= maxLayerTextureSize
            && height <= maxLayerTextureSize;
    }

    function show(actions, triggerRect, position, anchorWin) {
        if (!actions || actions.length === 0) return;
        if (!triggerRect) return;

        // Defensive defaults for triggerRect fields
        var tx = triggerRect.x || 0;
        var ty = triggerRect.y || 0;
        var tw = triggerRect.width || 0;
        var th = triggerRect.height || 0;

        root.model = actions;
        root.barPosition = position || "top";
        root.focusedIndex = -1;
        root.anchor.window = anchorWin;

        var pos = root.barPosition;
        var gap = Colors.spacingXS;

        if (pos === "left" || pos === "right") {
            // Side bars: popup beside the bar, vertically centered on trigger
            var anchorY = ty + th / 2 - root.height / 2;
            if (anchorWin && anchorWin.screen) {
                var screenH = anchorWin.screen.height;
                if (anchorY + root.height > screenH - 8) anchorY = screenH - root.height - 8;
                if (anchorY < 8) anchorY = 8;
            }
            root.anchor.rect.y = anchorY;
            if (pos === "left")
                root.anchor.rect.x = tx + tw + gap;
            else
                root.anchor.rect.x = tx - menuWidth - gap;
        } else {
            // Top / bottom bars: popup centered horizontally on trigger
            var anchorX = tx + tw / 2 - menuWidth / 2;
            // Clamp to screen bounds
            if (anchorWin && anchorWin.screen) {
                var screenW = anchorWin.screen.width;
                if (anchorX + menuWidth > screenW - 8) anchorX = screenW - menuWidth - 8;
                if (anchorX < 8) anchorX = 8;
            }
            root.anchor.rect.x = anchorX;

            if (pos === "bottom")
                root.anchor.rect.y = ty - root.height - gap;
            else
                root.anchor.rect.y = ty + th + gap;
        }

        root.visible = true;
        contentRect.forceActiveFocus();
    }

    function close() {
        root.visible = false;
        root.model = [];
        root.focusedIndex = -1;
    }

    function executeItem(index) {
        var item = model[index];
        if (!item || item.separator || item.disabled) return;
        var fn = item.action;
        close();
        if (typeof fn === "function") fn();
    }

    function moveFocus(delta) {
        if (model.length === 0) return;
        var next = focusedIndex + delta;
        for (var attempts = 0; attempts < model.length; attempts++) {
            if (next < 0) next = model.length - 1;
            else if (next >= model.length) next = 0;
            if (!model[next].separator && !model[next].disabled) {
                focusedIndex = next;
                return;
            }
            next += delta;
        }
    }

    onVisibleChanged: {
        if (!visible) {
            model = [];
            focusedIndex = -1;
        }
    }

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: Colors.radiusMedium
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        focus: root.visible
        Keys.onUpPressed: root.moveFocus(-1)
        Keys.onDownPressed: root.moveFocus(1)
        Keys.onReturnPressed: root.executeItem(root.focusedIndex)
        Keys.onEnterPressed: root.executeItem(root.focusedIndex)
        Keys.onEscapePressed: root.close()

        layer.enabled: root.visible && root.allowLayer(width, height)
        layer.smooth: true

        ElevationShadow {}

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.menuPadding
            spacing: 0

            Repeater {
                model: root.model

                delegate: Item {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: modelData.separator ? root.separatorHeight : root.itemHeight

                    // Separator
                    Rectangle {
                        visible: modelData.separator === true
                        anchors.centerIn: parent
                        width: parent.width - Colors.spacingS * 2
                        height: 1
                        color: Colors.border
                    }

                    // Menu item
                    Rectangle {
                        visible: !modelData.separator
                        anchors.fill: parent
                        radius: Colors.radiusXS
                        color: root.focusedIndex === index || itemMouse.containsMouse
                            ? Colors.highlightLight : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Colors.spacingS
                            anchors.rightMargin: Colors.spacingS
                            spacing: Colors.spacingS

                            Text {
                                visible: !!modelData.icon
                                text: modelData.icon || ""
                                color: modelData.danger ? Colors.error
                                    : (modelData.disabled ? Colors.textDisabled : Colors.textSecondary)
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeMedium
                            }

                            Text {
                                text: modelData.label || ""
                                color: modelData.danger ? Colors.error
                                    : (modelData.disabled ? Colors.textDisabled : Colors.text)
                                font.pixelSize: Colors.fontSizeSmall
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !modelData.separator && !modelData.disabled
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.executeItem(index)
                            onEntered: root.focusedIndex = index
                        }
                    }
                }
            }
        }
    }
}
