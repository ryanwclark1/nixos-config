import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets

Scope {
    id: root

    property bool isVisible: false

    // Resolved MRU window list from NiriService
    readonly property var windowList: {
        if (!CompositorAdapter.isNiri || !NiriService.available)
            return [];
        var mru = NiriService.mruWindowIds;
        var allWindows = NiriService.windows;
        // Build id → window map for O(1) lookups
        var windowMap = {};
        for (var j = 0; j < allWindows.length; j++)
            windowMap[allWindows[j].id] = allWindows[j];
        var result = [];
        for (var i = 0; i < mru.length; i++) {
            var win = windowMap[mru[i]];
            if (win)
                result.push(win);
        }
        return result;
    }

    property int selectedIndex: 0

    // Clamp selectedIndex when window list shrinks (e.g. window closed while switcher open)
    onWindowListChanged: {
        if (selectedIndex >= windowList.length)
            selectedIndex = Math.max(0, windowList.length - 1);
    }

    function show() {
        if (windowList.length < 2)
            return;
        selectedIndex = 1; // Start on second (previous) window
        isVisible = true;
    }

    function hide() {
        isVisible = false;
    }

    function confirm() {
        if (selectedIndex >= 0 && selectedIndex < windowList.length) {
            var win = windowList[selectedIndex];
            CompositorAdapter.focusWindow(win.id);
        }
        hide();
    }

    function cycleNext() {
        if (windowList.length === 0)
            return;
        selectedIndex = (selectedIndex + 1) % windowList.length;
    }

    function cyclePrev() {
        if (windowList.length === 0)
            return;
        selectedIndex = (selectedIndex - 1 + windowList.length) % windowList.length;
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
                    interval: Colors.durationFast
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
                                        duration: Colors.durationFast
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.hide()
                                }
                            }

                            // Centered card row
                            Item {
                                anchors.centerIn: parent
                                width: cardRow.width
                                height: cardRow.height + titleLabel.height + Colors.spacingM

                                Row {
                                    id: cardRow
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: Colors.spacingM

                                    Repeater {
                                        model: root.windowList

                                    delegate: Rectangle {
                                        id: card
                                        readonly property bool isSelected: index === root.selectedIndex
                                        width: 120
                                        height: 100
                                        radius: Colors.radiusCard
                                        color: isSelected ? Colors.withAlpha(Colors.primary, 0.15) : Colors.withAlpha(Colors.surface, 0.45)
                                        border.color: isSelected ? Colors.primary : Colors.border
                                        border.width: isSelected ? 2 : 1
                                        scale: isSelected ? 1.15 : 1.0
                                        Behavior on scale {
                                            SpringAnimation {
                                                spring: 5.0
                                                damping: 0.3
                                                epsilon: 0.005
                                            }
                                        }
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Colors.durationFast
                                            }
                                        }

                                        gradient: isSelected ? selectedGradient : null

                                        Gradient {
                                            id: selectedGradient
                                            orientation: Gradient.Vertical

                                            GradientStop {
                                                position: 0.0
                                                color: Colors.withAlpha(Colors.primary, 0.1)
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
                                            spacing: Colors.spacingS

                                            SharedWidgets.AppIcon {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                iconName: modelData.app_id || ""
                                                appName: modelData.title || modelData.app_id || ""
                                                iconSize: 40
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: card.width - Colors.spacingM * 2
                                                text: modelData.app_id || "Unknown"
                                                color: card.isSelected ? Colors.text : Colors.textSecondary
                                                font.pixelSize: Colors.fontSizeXS
                                                font.family: Colors.fontMono
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                            }
                                        }

                                        // Workspace badge
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: Colors.spacingXS
                                            width: wsBadgeText.implicitWidth + Colors.spacingS * 2
                                            height: wsBadgeText.implicitHeight + Colors.spacingXS
                                            radius: Colors.radiusMicro
                                            color: Colors.withAlpha(Colors.bg, 0.7)
                                            visible: modelData.workspace_id !== undefined

                                            Text {
                                                id: wsBadgeText
                                                anchors.centerIn: parent
                                                text: {
                                                    if (modelData.workspace_id === undefined)
                                                        return "";
                                                    var ws = NiriService.workspaces ? NiriService.workspaces[modelData.workspace_id] : null;
                                                    return ws ? String(ws.name || ws.idx || modelData.workspace_id) : String(modelData.workspace_id);
                                                }
                                                color: Colors.textSecondary
                                                font.pixelSize: Colors.fontSizeXXS
                                            }
                                        }

                                        MouseArea {
                                            id: cardMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor

                                            drag.target: card
                                            drag.axis: Drag.XAndYAxis

                                            onClicked: {
                                                root.selectedIndex = index;
                                                root.confirm();
                                            }
                                            onEntered: root.selectedIndex = index
                                        }

                                        Drag.active: cardMouse.drag.active
                                        Drag.source: ({
                                                type: "window",
                                                windowId: modelData.id,
                                                windowAddress: modelData.address,
                                                appId: modelData.app_id
                                            })
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2

                                        states: [
                                            State {
                                                when: cardMouse.drag.active
                                                ParentChange {
                                                    target: card
                                                    parent: focusItem
                                                }
                                                PropertyChanges {
                                                    target: card
                                                    opacity: 0.8
                                                    scale: 0.8
                                                }
                                            }
                                        ]
                                    }
                                    }
                                }

                                // Selected window title
                                Text {
                                    id: titleLabel
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: cardRow.bottom
                                    anchors.topMargin: Colors.spacingM
                                    width: Math.min(parent.width, 500)
                                    text: root.selectedIndex >= 0 && root.selectedIndex < root.windowList.length ? (root.windowList[root.selectedIndex].title || "Untitled") : ""
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
