import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

Scope {
    id: root

    property bool isVisible: false
    property bool _destroyed: false
    Component.onDestruction: _destroyed = true

    // Snapshot of window list taken on show(), updated only when a window is closed
    property var _cachedWindowList: []

    // Compositor-agnostic MRU window list (live — used to detect closed windows)
    readonly property var windowList: {
        var mru = CompositorAdapter.mruWindowIds;
        if (mru.length === 0)
            return [];

        var windowMap = {};

        if (CompositorAdapter.isNiri && NiriService.available) {
            var niriWindows = NiriService.windows;
            for (var j = 0; j < niriWindows.length; j++) {
                var nw = niriWindows[j];
                windowMap[nw.id] = {
                    id: nw.id,
                    app_id: nw.app_id || "",
                    title: nw.title || "",
                    workspace_id: nw.workspace_id
                };
            }
        } else if (CompositorAdapter.isHyprland) {
            var toplevels = CompositorAdapter.toplevels || [];
            for (var k = 0; k < toplevels.length; k++) {
                var tl = toplevels[k];
                var addr = String(tl.address || "");
                if (addr === "") continue;
                windowMap[addr] = {
                    id: addr,
                    app_id: String(tl["class"] || ""),
                    title: String(tl.title || ""),
                    workspace_id: tl.workspace ? tl.workspace.id : undefined
                };
            }
        }

        var result = [];
        for (var i = 0; i < mru.length; i++) {
            var win = windowMap[mru[i]];
            if (win)
                result.push(win);
        }
        return result;
    }

    property int selectedIndex: 0

    // Only update cache when a window is closed (selected ID missing from live list)
    onWindowListChanged: {
        if (!isVisible || _cachedWindowList.length === 0)
            return;
        var selectedId = selectedIndex >= 0 && selectedIndex < _cachedWindowList.length
            ? _cachedWindowList[selectedIndex].id : null;
        if (selectedId !== null) {
            var found = false;
            for (var i = 0; i < windowList.length; i++) {
                if (windowList[i].id === selectedId) { found = true; break; }
            }
            if (!found) {
                // Window was closed — rebuild cache from live list
                _cachedWindowList = windowList.slice();
                if (selectedIndex >= _cachedWindowList.length)
                    selectedIndex = Math.max(0, _cachedWindowList.length - 1);
                if (_cachedWindowList.length <= 1)
                    hide();
            }
        }
    }

    function show() {
        Logger.d("AltTab", "show() called, windowList.length=" + windowList.length + ", mruIds=" + JSON.stringify(CompositorAdapter.mruWindowIds));
        if (windowList.length < 2)
            return;
        _cachedWindowList = windowList.slice();
        selectedIndex = 1; // Start on second (previous) window
        isVisible = true;
    }

    function hide() {
        isVisible = false;
    }

    function confirm() {
        if (selectedIndex >= 0 && selectedIndex < _cachedWindowList.length) {
            var win = _cachedWindowList[selectedIndex];
            CompositorAdapter.focusWindow(win.id);
        }
        hide();
    }

    function closeSelected() {
        if (selectedIndex >= 0 && selectedIndex < _cachedWindowList.length) {
            var win = _cachedWindowList[selectedIndex];
            CompositorAdapter.closeWindow(win.id);
        }
        // Cache update handled by onWindowListChanged
    }

    function cycleNext() {
        if (_cachedWindowList.length === 0)
            return;
        selectedIndex = (selectedIndex + 1) % _cachedWindowList.length;
    }

    function cyclePrev() {
        if (_cachedWindowList.length === 0)
            return;
        selectedIndex = (selectedIndex - 1 + _cachedWindowList.length) % _cachedWindowList.length;
    }

    IpcHandler {
        target: "AltTab"
        function show() {
            root.show();
        }
        function hide() {
            root.hide();
        }
        function toggle() {
            if (root.isVisible)
                root.confirm();
            else
                root.show();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                required property ShellScreen modelData

                Timer {
                    id: _hideTimer
                    interval: Appearance.durationFast
                    running: false
                }

                LazyLoader {
                    active: root.isVisible || _hideTimer.running

                    Connections {
                        target: root
                        function onIsVisibleChanged() {
                            if (!root.isVisible)
                                _hideTimer.restart();
                        }
                    }

                    PanelWindow {
                        id: switcherWindow
                        screen: modelData
                        visible: root.isVisible

                        anchors {
                            top: true
                            left: true
                            right: true
                            bottom: true
                        }
                        color: "transparent"
                        WlrLayershell.layer: WlrLayer.Overlay
                        WlrLayershell.namespace: "quickshell-alttab"
                        WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                        exclusiveZone: -1

                        onVisibleChanged: if (visible)
                            focusItem.forceActiveFocus()

                        Item {
                            id: focusItem
                            anchors.fill: parent
                            focus: true

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.hide();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                                    root.cycleNext();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                                    root.cyclePrev();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.confirm();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Delete || (event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier))) {
                                    root.closeSelected();
                                    event.accepted = true;
                                }
                            }

                            WheelHandler {
                                onWheel: event => {
                                    var delta = event.angleDelta.y;
                                    if (delta > 0)
                                        root.cyclePrev();
                                    else if (delta < 0)
                                        root.cycleNext();
                                }
                            }

                            // Dim background
                            Rectangle {
                                anchors.fill: parent
                                color: Colors.withAlpha(Colors.bg, 0.6)
                                opacity: root.isVisible ? 1.0 : 0.0
                                layer.enabled: opacity > 0 && opacity < 1
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Appearance.durationFast
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.hide()
                                }
                            }

                            // Centered card container
                            Item {
                                anchors.centerIn: parent
                                width: cardFlickable.width
                                height: cardFlickable.height + titleLabel.height + hintRow.height + Appearance.spacingM * 2 + (indexLabel.visible ? indexLabel.height + Appearance.spacingS : 0)

                                Flickable {
                                    id: cardFlickable
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(cardRow.implicitWidth, focusItem.width * 0.85)
                                    height: cardRow.implicitHeight
                                    contentWidth: cardRow.implicitWidth
                                    contentHeight: height
                                    flickableDirection: Flickable.HorizontalFlick
                                    clip: contentWidth > width
                                    boundsBehavior: Flickable.StopAtBounds

                                    Behavior on contentX {
                                        NumberAnimation {
                                            duration: Appearance.animMove.duration
                                            easing.type: Appearance.animMove.type
                                            easing.bezierCurve: Appearance.animMove.bezierCurve
                                        }
                                    }

                                    function ensureVisible(idx) {
                                        if (idx < 0 || idx >= root._cachedWindowList.length)
                                            return;
                                        var cardWidth = 148;
                                        var spacing = Appearance.spacingM;
                                        var cardX = idx * (cardWidth + spacing);
                                        var cardRight = cardX + cardWidth;
                                        if (cardX < contentX)
                                            contentX = Math.max(0, cardX - spacing);
                                        else if (cardRight > contentX + width)
                                            contentX = Math.min(contentWidth - width, cardRight - width + spacing);
                                    }

                                    Row {
                                        id: cardRow
                                        spacing: Appearance.spacingM

                                        Repeater {
                                            model: root._cachedWindowList

                                        delegate: Rectangle {
                                            id: card
                                            readonly property bool isSelected: index === root.selectedIndex
                                            width: 148
                                            height: 120
                                            radius: Appearance.radiusCard
                                            color: isSelected ? Colors.highlightLight : Colors.withAlpha(Colors.surface, 0.45)
                                            border.color: isSelected ? Colors.primary : Colors.border
                                            border.width: isSelected ? 2 : 1
                                            scale: isSelected ? 1.08 : 1.0
                                            layer.enabled: _scaleAnim.running
                                            Behavior on scale {
                                                NumberAnimation {
                                                    id: _scaleAnim
                                                    duration: Appearance.animMove.duration
                                                    easing.type: Appearance.animMove.type
                                                    easing.bezierCurve: Appearance.animMove.bezierCurve
                                                }
                                            }
                                            Behavior on color {
                                                enabled: !Colors.isTransitioning
                                                CAnim {}
                                            }

                                            gradient: isSelected ? selectedGradient : null

                                            Gradient {
                                                id: selectedGradient
                                                orientation: Gradient.Vertical

                                                GradientStop {
                                                    position: 0.0
                                                    color: Colors.primaryGhost
                                                }

                                                GradientStop {
                                                    position: 1.0
                                                    color: "transparent"
                                                }
                                            }

                                            SharedWidgets.InnerHighlight {
                                                hoveredOpacity: 0.3
                                                hovered: isSelected
                                            }

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: Appearance.spacingS

                                                SharedWidgets.AppIcon {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    iconName: modelData.app_id || ""
                                                    appName: modelData.title || modelData.app_id || ""
                                                    iconSize: 52
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: card.width - Appearance.spacingM * 2
                                                    text: modelData.app_id || "Unknown"
                                                    color: card.isSelected ? Colors.text : Colors.textSecondary
                                                    font.pixelSize: Appearance.fontSizeSmall
                                                    font.weight: Font.Medium
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: card.width - Appearance.spacingM * 2
                                                    text: modelData.title || ""
                                                    visible: text !== "" && text !== (modelData.app_id || "")
                                                    color: Colors.textSecondary
                                                    font.pixelSize: Appearance.fontSizeXS
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            // Workspace badge
                                            Rectangle {
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: Appearance.spacingXS
                                                width: wsBadgeText.implicitWidth + Appearance.spacingS * 2
                                                height: wsBadgeText.implicitHeight + Appearance.spacingXS
                                                radius: Appearance.radiusMicro
                                                color: Colors.withAlpha(Colors.bg, 0.7)
                                                visible: modelData.workspace_id !== undefined

                                                Text {
                                                    id: wsBadgeText
                                                    anchors.centerIn: parent
                                                    text: CompositorAdapter.workspaceNameById(modelData.workspace_id)
                                                    color: Colors.textSecondary
                                                    font.pixelSize: Appearance.fontSizeXXS
                                                }
                                            }

                                            MouseArea {
                                                id: cardMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: {
                                                    root.selectedIndex = index;
                                                    root.confirm();
                                                }
                                                onEntered: root.selectedIndex = index
                                            }

                                            // Close button — declared after cardMouse so it wins input priority
                                            SharedWidgets.IconButton {
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.margins: Appearance.spacingXS
                                                icon: "dismiss.svg"
                                                size: 22
                                                iconSize: Appearance.fontSizeXS
                                                iconColor: Colors.text
                                                normalColor: Colors.error
                                                tooltipText: "Close window"
                                                opacity: cardMouse.containsMouse ? 0.9 : 0.0
                                                visible: opacity > 0
                                                Behavior on opacity {
                                                    NumberAnimation { duration: Appearance.durationFast }
                                                }
                                                onClicked: {
                                                    root.selectedIndex = index;
                                                    root.closeSelected();
                                                }
                                            }
                                        }
                                        }
                                    }
                                }

                                // Left edge fade
                                Rectangle {
                                    anchors.left: cardFlickable.left
                                    anchors.top: cardFlickable.top
                                    anchors.bottom: cardFlickable.bottom
                                    width: 40
                                    visible: cardFlickable.contentX > 0
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: Colors.withAlpha(Colors.bg, 0.8) }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }

                                // Right edge fade
                                Rectangle {
                                    anchors.right: cardFlickable.right
                                    anchors.top: cardFlickable.top
                                    anchors.bottom: cardFlickable.bottom
                                    width: 40
                                    visible: cardFlickable.contentX < cardFlickable.contentWidth - cardFlickable.width - 1
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: Colors.withAlpha(Colors.bg, 0.8) }
                                    }
                                }

                                // Selected window title
                                Text {
                                    id: titleLabel
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: cardFlickable.bottom
                                    anchors.topMargin: Appearance.spacingM
                                    width: Math.min(parent.width, 500)
                                    text: root.selectedIndex >= 0 && root.selectedIndex < root._cachedWindowList.length ? (root._cachedWindowList[root.selectedIndex].title || "Untitled") : ""
                                    color: Colors.text
                                    font.pixelSize: Appearance.fontSizeLarge
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }

                                // Index counter (visible with many windows)
                                Text {
                                    id: indexLabel
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: titleLabel.bottom
                                    anchors.topMargin: Appearance.spacingS
                                    visible: root._cachedWindowList.length > 5
                                    text: (root.selectedIndex + 1) + " / " + root._cachedWindowList.length
                                    color: Colors.textDisabled
                                    font.pixelSize: Appearance.fontSizeXS
                                }

                                // Keyboard hint strip
                                Row {
                                    id: hintRow
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: indexLabel.visible ? indexLabel.bottom : titleLabel.bottom
                                    anchors.topMargin: Appearance.spacingM
                                    spacing: Appearance.spacingS
                                    opacity: 0.6

                                    Repeater {
                                        model: [
                                            { key: "Tab", action: "Next" },
                                            { key: "Enter", action: "Switch" },
                                            { key: "Del", action: "Close" },
                                            { key: "Esc", action: "Cancel" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            radius: Appearance.radiusMicro
                                            color: Colors.withAlpha(Colors.surface, 0.5)
                                            border.color: Colors.border
                                            border.width: 1
                                            implicitWidth: hintText.implicitWidth + Appearance.spacingS * 2
                                            implicitHeight: hintText.implicitHeight + Appearance.spacingXS

                                            Text {
                                                id: hintText
                                                anchors.centerIn: parent
                                                text: modelData.key + " \u2192 " + modelData.action
                                                color: Colors.textSecondary
                                                font.pixelSize: Appearance.fontSizeXXS
                                            }
                                        }
                                    }
                                }

                                Connections {
                                    target: root
                                    function onSelectedIndexChanged() {
                                        if (root._destroyed) return;
                                        cardFlickable.ensureVisible(root.selectedIndex);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
