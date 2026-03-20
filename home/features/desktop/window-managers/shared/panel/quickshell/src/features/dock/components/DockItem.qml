import QtQuick
import Quickshell
import ".."
import "../../../services"
import "../../../shared"
import "../../../widgets"

Item {
    id: root

    required property var modelData
    required property int index
    required property var dockRoot
    required property bool vertical
    required property int iconSlotMain
    required property int iconSlotCross
    required property int dragSourceIndex
    required property int dragTargetIndex
    required property var anchorWindow

    property bool contextMenuVisible: false

    signal dragStarted(int index)
    signal dragEnded()
    signal dragTargetChanged(int index)
    signal dragTargetCleared(int index)
    signal dropReceived(int fromIndex, int toIndex)
    signal contextMenuRequested(var appData, int appIndex, var anchorItem)

    width: root.vertical ? root.iconSlotCross : root.iconSlotMain
    height: root.vertical ? root.iconSlotMain : root.iconSlotCross

    readonly property string appId: modelData.appId || ""
    readonly property var toplevels: modelData.toplevels || []
    readonly property bool isRunning: toplevels.length > 0
    readonly property bool isPinned: modelData.pinned || false
    readonly property bool isGrouped: toplevels.length > 1
    readonly property string appName: modelData.name || appId
    readonly property string iconSource: root.dockRoot ? root.dockRoot.getAppIcon(appId) : ""
    readonly property bool isFocused: {
        if (!isRunning) return false;
        var active = CompositorAdapter.activeWindow;
        if (!active) return false;
        for (var i = 0; i < toplevels.length; i++) {
            if (CompositorAdapter.sameWindow(toplevels[i], active)) return true;
        }
        return false;
    }

    property int prevToplevelCount: 0

    SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: iconContainer; property: root.vertical ? "x" : "y"; to: 0; duration: Appearance.durationSnap; easing.type: Easing.OutQuad }
        NumberAnimation { target: iconContainer; property: root.vertical ? "x" : "y"; to: 4; duration: Appearance.durationNormal; easing.type: Easing.OutBounce }
    }

    onToplevelsChanged: {
        if (toplevels.length > prevToplevelCount && prevToplevelCount > 0) bounceAnim.start();
        prevToplevelCount = toplevels.length;
    }
    Component.onCompleted: prevToplevelCount = toplevels.length

    DropArea {
        anchors.fill: parent
        keys: ["dock-app"]
        onEntered: function(drag) {
            root.dragTargetChanged(root.index);
        }
        onExited: {
            root.dragTargetCleared(root.index);
        }
        onDropped: function(drop) {
            if (drop.source && drop.source !== iconContainer)
                root.dropReceived(root.dragSourceIndex, root.index);
        }
    }

    Item {
        id: iconContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        x: root.vertical ? 4 : 0
        y: root.vertical ? 0 : 4
        width: Config.dockIconSize
        height: Config.dockIconSize

        property bool dragging: mouseArea.drag.active

        Drag.active: dragging
        Drag.source: iconContainer
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.keys: ["dock-app"]

        onDraggingChanged: {
            if (dragging) root.dragStarted(root.index);
            else root.dragEnded();
        }

        property real shiftMain: {
            if (root.dragSourceIndex < 0 || root.dragTargetIndex < 0 || dragging) return 0;
            var src = root.dragSourceIndex;
            var tgt = root.dragTargetIndex;
            var step = Config.dockIconSize + 8;
            if (src < tgt && root.index > src && root.index <= tgt)
                return -step;
            if (src > tgt && root.index >= tgt && root.index < src)
                return step;
            return 0;
        }

        transform: Translate {
            x: root.vertical ? 0 : iconContainer.shiftMain
            y: root.vertical ? iconContainer.shiftMain : 0
            Behavior on x { Anim { duration: Appearance.durationFast } }
            Behavior on y { Anim { duration: Appearance.durationFast } }
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.radiusSmall
            color: "transparent"
            scale: mouseArea.containsMouse ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: Appearance.durationFast; easing.type: Easing.OutBack } }

            StateLayer {
                hovered: mouseArea.containsMouse
                pressed: mouseArea.pressed
            }

            AppIcon {
                anchors.centerIn: parent
                iconName: root.iconSource
                appName: root.appName || ""
                iconSize: Config.dockIconSize - 8
                fallbackIcon: "󰀻"
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            drag.target: root.isPinned ? iconContainer : undefined
            drag.axis: root.vertical ? Drag.YAxis : Drag.XAxis

            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    root.contextMenuRequested(root.modelData, root.index, root);
                    return;
                }

                if (mouse.button === Qt.MiddleButton) {
                    if (root.isRunning) {
                        if (root.isGrouped) {
                            var active = CompositorAdapter.activeWindow;
                            var closed = false;
                            for (var i = 0; i < root.toplevels.length; i++) {
                                if (CompositorAdapter.sameWindow(root.toplevels[i], active)) {
                                    root.toplevels[i].close(); closed = true; break;
                                }
                            }
                            if (!closed && root.toplevels.length > 0) root.toplevels[0].close();
                        } else if (root.toplevels.length > 0) {
                            root.toplevels[0].close();
                        }
                    }
                    return;
                }

                if (root.isRunning) {
                    if (root.isGrouped) {
                        var activeTop = CompositorAdapter.activeWindow;
                        var idx = -1;
                        for (var j = 0; j < root.toplevels.length; j++) {
                            if (CompositorAdapter.sameWindow(root.toplevels[j], activeTop)) { idx = j; break; }
                        }
                        var next = (idx + 1) % root.toplevels.length;
                        root.toplevels[next].activate();
                    } else if (root.toplevels.length > 0) {
                        root.toplevels[0].activate();
                    }
                } else {
                    Quickshell.execDetached(["gtk-launch", root.appId]);
                }
            }

            onWheel: function(wheel) {
                if (!root.isGrouped) return;
                var active = CompositorAdapter.activeWindow;
                var idx = -1;
                for (var i = 0; i < root.toplevels.length; i++) {
                    if (CompositorAdapter.sameWindow(root.toplevels[i], active)) { idx = i; break; }
                }
                var count = root.toplevels.length;
                var delta = root.vertical ? wheel.angleDelta.x : wheel.angleDelta.y;
                var next = delta > 0 ? (idx + 1) % count : (idx - 1 + count) % count;
                root.toplevels[next].activate();
            }

            onReleased: {
                if (iconContainer.Drag.active) iconContainer.Drag.drop();
            }
        }
    }

    DockItemIndicators {
        active: root.isRunning
        anchors.bottom: root.vertical ? undefined : parent.bottom
        anchors.horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
        anchors.right: root.vertical ? parent.right : undefined
        anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
        anchors.bottomMargin: root.vertical ? 0 : 1
        anchors.rightMargin: root.vertical ? 1 : 0
        toplevels: root.toplevels
        isFocused: root.isFocused
        vertical: root.vertical
    }

    Rectangle {
        visible: root.isGrouped
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        width: 14; height: 14; radius: width / 2
        color: Colors.primary

        Text {
            anchors.centerIn: parent
            text: root.toplevels.length
            color: Colors.background
            font.pixelSize: Appearance.fontSizeXXS
            font.weight: Font.Bold
        }
    }

    // Simple tooltip for non-running apps
    BarTooltip {
        text: root.appName
        anchorItem: root
        anchorWindow: root.anchorWindow
        hovered: mouseArea.containsMouse && !iconContainer.dragging && !root.contextMenuVisible && !root.isRunning
    }

    // Window preview popup for running apps
    DockPreview {
        anchorItem: root
        anchorWindow: root.anchorWindow
        toplevels: root.toplevels
        appName: root.appName
        appIcon: root.iconSource
        vertical: root.vertical
        hovered: mouseArea.containsMouse && !iconContainer.dragging && !root.contextMenuVisible && root.isRunning
    }
}
