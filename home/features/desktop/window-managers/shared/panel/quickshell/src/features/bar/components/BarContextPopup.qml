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
    readonly property int menuPadding: Appearance.spacingXS
    readonly property int menuWidth: 200
    readonly property int maxLayerTextureSize: 4096

    color: "transparent"
    visible: false
    implicitWidth: menuWidth + 2
    implicitHeight: menuPadding * 2 + contentColumn.implicitHeight + 2
    anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY

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
        var gap = Appearance.spacingXS;

        if (pos === "left" || pos === "right") {
            // Side bars: popup beside the bar, vertically centered on trigger
            root.anchor.rect.y = ty + th / 2 - root.implicitHeight / 2;
            if (pos === "left")
                root.anchor.rect.x = tx + tw + gap;
            else
                root.anchor.rect.x = tx - menuWidth - gap;
        } else {
            // Top / bottom bars: popup centered horizontally on trigger
            root.anchor.rect.x = tx + tw / 2 - menuWidth / 2;

            if (pos === "bottom")
                root.anchor.rect.y = ty - root.implicitHeight - gap;
            else
                root.anchor.rect.y = ty + th + gap;
        }

        root.visible = true;
        FocusGrabManager.requestGrab("barContextMenu", function() { root.close(); });
        contentRect.forceActiveFocus();
    }

    function close() {
        FocusGrabManager.releaseGrab("barContextMenu");
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
            // Safety: if compositor hid us (popup_done) or external close,
            // ensure grab is released.
            FocusGrabManager.releaseGrab("barContextMenu");
            model = [];
            focusedIndex = -1;
        }
    }

    Rectangle {
        id: contentRect
        anchors.fill: parent
        radius: Appearance.radiusMedium
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        focus: root.visible
        onActiveFocusChanged: {
            if (!activeFocus && root.visible)
                root.close();
        }
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
                        width: parent.width - Appearance.spacingS * 2
                        height: 1
                        color: Colors.border
                    }

                    // Menu item
                    Rectangle {
                        visible: !modelData.separator
                        anchors.fill: parent
                        radius: Appearance.radiusXS
                        color: root.focusedIndex === index || itemMouse.containsMouse
                            ? Colors.highlightLight : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacingS
                            anchors.rightMargin: Appearance.spacingS
                            spacing: Appearance.spacingS

                            Loader {
                                visible: !!modelData.icon
                                property string _ic: modelData.icon || ""
                                property color _co: modelData.danger ? Colors.error
                                    : (modelData.disabled ? Colors.textDisabled : Colors.textSecondary)
                                sourceComponent: _ic.endsWith(".svg") ? _bcpSvg : _bcpNerd
                            }
                            Component { id: _bcpSvg; SvgIcon { source: parent._ic; color: parent._co; size: Appearance.fontSizeMedium } }
                            Component { id: _bcpNerd; Text { text: parent._ic; color: parent._co; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeMedium } }

                            Text {
                                text: modelData.label || ""
                                color: modelData.danger ? Colors.error
                                    : (modelData.disabled ? Colors.textDisabled : Colors.text)
                                font.pixelSize: Appearance.fontSizeSmall
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
