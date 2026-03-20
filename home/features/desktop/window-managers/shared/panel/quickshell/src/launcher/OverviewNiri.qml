import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

ColumnLayout {
    id: content
    spacing: Appearance.spacingLG

    signal closeRequested()
    required property string screenName
    required property real windowWidth

    property string searchQuery: ""

    // Filter workspaces to this screen's output
    readonly property var screenWorkspaces: {
        var all = NiriService.allWorkspaces;
        if (!screenName || all.length === 0)
            return all;
        var filtered = all.filter(function (ws) {
            return ws.output === screenName;
        });
        return filtered.length > 0 ? filtered : all;
    }

    // Group windows by workspace
    readonly property var workspaceWindows: {
        var result = {};
        var allWs = NiriService.allWorkspaces;
        for (var i = 0; i < allWs.length; i++)
            result[allWs[i].id] = [];
        var wins = NiriService.windows;
        for (var w = 0; w < wins.length; w++) {
            var wsId = wins[w].workspace_id;
            if (!result[wsId])
                result[wsId] = [];
            result[wsId].push(wins[w]);
        }
        return result;
    }

    // Build context menu model for a window card
    function buildContextModel(win, currentWs, allWs) {
        var items = [];

        for (var i = 0; i < allWs.length; i++) {
            var ws = allWs[i];
            if (ws.id === currentWs.id)
                continue;
            var wsLabel = ws.name || ("Workspace " + (ws.idx || ws.id));
            (function (targetWs) {
                    items.push({
                        label: "Move to " + wsLabel,
                        icon: "󰁔",
                        action: function () {
                            NiriService.moveWindowToWorkspace(win.id, targetWs.idx, false);
                        }
                    });
                })(ws);
        }

        if (items.length > 0)
            items.push({
                separator: true
            });

        items.push({
            label: "Fullscreen",
            icon: "󰊓",
            action: function () {
                CompositorAdapter.focusWindow(win.id);
                NiriService.fullscreenWindow();
            }
        });

        items.push({
            label: "Float",
            icon: "󰖲",
            action: function () {
                CompositorAdapter.focusWindow(win.id);
                NiriService.toggleWindowFloating();
            }
        });

        items.push({
            separator: true
        });

        items.push({
            label: "Close",
            icon: "󰅙",
            danger: true,
            action: function () {
                CompositorAdapter.closeWindow(win.id);
            }
        });

        return items;
    }

    // Search bar
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.min(400, content.width * 0.5)
        Layout.preferredHeight: 44
        radius: Appearance.radiusPill
        color: Colors.surface
        border.color: searchInput.activeFocus ? Colors.primary : Colors.border
        border.width: searchInput.activeFocus ? 2 : 1

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spacingS

            Text {
                text: ""
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeLarge
                font.family: Appearance.fontMono
                anchors.verticalCenter: parent.verticalCenter
            }

            TextInput {
                id: searchInput
                width: Math.min(320, content.windowWidth * 0.4)
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                clip: true
                onTextChanged: content.searchQuery = text.toLowerCase()
                anchors.verticalCenter: parent.verticalCenter

                Keys.onEscapePressed: {
                    if (text !== "") {
                        text = "";
                    } else {
                        content.closeRequested();
                    }
                }

                Text {
                    visible: !searchInput.text
                    text: "Search windows..."
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeMedium
                }
            }
        }
    }

    // Workspace columns
    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: wsRow.width
        contentHeight: height
        clip: true
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: wsRow
            spacing: Appearance.spacingXL
            height: parent.height

            Repeater {
                model: content.screenWorkspaces

                delegate: Rectangle {
                    id: wsColumn
                    readonly property var ws: modelData
                    readonly property int wsIndex: index
                    readonly property bool isFocused: ws.is_focused
                    property bool dropHighlight: false

                    // Staggered entry animation
                    opacity: 0
                    transform: Translate {
                        id: wsSlide
                        y: 20
                        Behavior on y {
                            Anim {}
                        }
                    }
                    Behavior on opacity {
                        Anim {}
                    }

                    Timer {
                        running: true
                        interval: wsColumn.wsIndex * 60
                        onTriggered: {
                            wsColumn.opacity = 1;
                            wsSlide.y = 0;
                        }
                    }
                    readonly property var wsWindows: {
                        var all = content.workspaceWindows[ws.id] || [];
                        if (content.searchQuery === "")
                            return all;
                        return all.filter(function (w) {
                            return (w.title || "").toLowerCase().indexOf(content.searchQuery) !== -1 || (w.app_id || "").toLowerCase().indexOf(content.searchQuery) !== -1;
                        });
                    }

                    width: Math.max(280, Math.min(400, content.windowWidth / Math.max(content.screenWorkspaces.length, 1) - Appearance.spacingXL))
                    height: parent.height
                    radius: Appearance.radiusLarge
                    color: Colors.withAlpha(Colors.surface, 0.4)
                    border.color: dropHighlight ? Colors.accent : (isFocused ? Colors.primary : Colors.border)
                    border.width: (dropHighlight || isFocused) ? 2 : 1

                    gradient: SharedWidgets.SurfaceGradient {}

                    SharedWidgets.InnerHighlight {
                        hoveredOpacity: 0.25
                        hovered: isFocused
                    }

                    DropArea {
                        anchors.fill: parent
                        keys: ["overview-window"]
                        onEntered: wsColumn.dropHighlight = true
                        onExited: wsColumn.dropHighlight = false
                        onDropped: drop => {
                            wsColumn.dropHighlight = false;
                            if (drop.source && drop.source.windowId !== undefined)
                                NiriService.moveWindowToWorkspace(drop.source.windowId, wsColumn.ws.idx, false);
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.paddingMedium
                        spacing: Appearance.spacingM

                        // Workspace header
                        Text {
                            text: ws.name || ("Workspace " + (ws.idx || ws.id))
                            color: wsColumn.isFocused ? Colors.primary : Colors.text
                            font.pixelSize: Appearance.fontSizeXL
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // Window count
                        Text {
                            text: wsColumn.wsWindows.length + " window" + (wsColumn.wsWindows.length !== 1 ? "s" : "")
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // Window list
                        Flickable {
                            id: windowFlick
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: windowCol.height
                            clip: true
                            flickableDirection: Flickable.VerticalFlick

                            SharedWidgets.OverscrollGlow {
                                flickable: windowFlick
                                glowColor: Colors.primary
                            }

                            Column {
                                id: windowCol
                                width: parent.width
                                spacing: Appearance.spacingS

                                Repeater {
                                    model: wsColumn.wsWindows

                                    delegate: Rectangle {
                                        id: windowCard
                                        width: windowCol.width
                                        height: 56
                                        radius: Appearance.radiusSmall
                                        color: modelData.is_focused ? Colors.highlightLight : (cardMouse.containsMouse ? Colors.highlightLight : Colors.withAlpha(Colors.surface, 0.25))
                                        border.color: modelData.is_focused ? Colors.primary : (cardMouse.containsMouse ? Colors.border : "transparent")
                                        border.width: 1

                                        SharedWidgets.InnerHighlight {
                                            hoveredOpacity: 0.3
                                            hovered: modelData.is_focused
                                        }

                                        // Drag-and-drop support
                                        property int windowId: modelData.id
                                        Drag.active: cardMouse.drag.active
                                        Drag.source: windowCard
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        Drag.keys: ["overview-window"]

                                        // Reset position after drag ends
                                        onXChanged: if (!cardMouse.drag.active)
                                            x = 0
                                        onYChanged: if (!cardMouse.drag.active)
                                            y = 0

                                        MouseArea {
                                            id: cardMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            drag.target: windowCard
                                            drag.axis: Drag.XAndYAxis
                                            onClicked: mouse => {
                                                if (mouse.button === Qt.RightButton) {
                                                    windowContextMenu.model = content.buildContextModel(modelData, wsColumn.ws, content.screenWorkspaces);
                                                    windowContextMenu.popup(mouse.x, mouse.y);
                                                } else {
                                                    CompositorAdapter.focusWindow(modelData.id);
                                                    content.closeRequested();
                                                }
                                            }
                                            onReleased: windowCard.Drag.drop()
                                        }

                                        SharedWidgets.ContextMenu {
                                            id: windowContextMenu
                                        }

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: Appearance.spacingS
                                            spacing: Appearance.spacingM

                                            SharedWidgets.AppIcon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                iconName: modelData.app_id || ""
                                                appName: modelData.title || modelData.app_id || ""
                                                iconSize: Appearance.iconSizeMedium
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - Appearance.iconSizeMedium - Appearance.spacingM * 2 - closeBtn.width
                                                spacing: Appearance.spacingXXS

                                                Text {
                                                    width: parent.width
                                                    text: modelData.title || "Untitled"
                                                    color: Colors.text
                                                    font.pixelSize: Appearance.fontSizeSmall
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    width: parent.width
                                                    text: modelData.app_id || ""
                                                    color: Colors.textSecondary
                                                    font.pixelSize: Appearance.fontSizeXS
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        // Close button (above cardMouse in z-stack)
                                        Text {
                                            id: closeBtn
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: Appearance.spacingS
                                            text: "󰅙"
                                            color: closeMouse.containsMouse ? Colors.error : Colors.textSecondary
                                            font.pixelSize: Appearance.fontSizeLarge
                                            font.family: Appearance.fontMono
                                            visible: cardMouse.containsMouse

                                            MouseArea {
                                                id: closeMouse
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: CompositorAdapter.closeWindow(modelData.id)
                                            }
                                        }
                                    }
                                }

                                // Empty state
                                Text {
                                    visible: wsColumn.wsWindows.length === 0
                                    text: content.searchQuery ? "No matches" : "Empty"
                                    color: Colors.textDisabled
                                    font.pixelSize: Appearance.fontSizeSmall
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    topPadding: Appearance.spacingXL
                                }
                            }
                        }
                    }

                    // Click empty area to switch workspace
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            CompositorAdapter.focusWorkspace(ws.idx || ws.id);
                            content.closeRequested();
                        }
                    }
                }
            }
        }
    }
}
