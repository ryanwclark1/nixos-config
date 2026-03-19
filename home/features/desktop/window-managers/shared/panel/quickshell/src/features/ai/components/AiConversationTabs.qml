import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets
import "../services/AiProviders.js" as Providers

// Horizontal AI conversation switcher with a visible recent strip, overflow menu,
// close/restore actions, and tab context menus.
RowLayout {
    id: root
    spacing: Colors.spacingS

    property string editingConversationId: ""
    readonly property bool compactMode: width < 420
    readonly property bool narrowMode: width < 320
    readonly property int visibleTabLimit: width < 260 ? 1 : (width < 380 ? 2 : (width < 520 ? 3 : 4))
    readonly property int reservedWidth: 32 + Colors.spacingS + 32 + Colors.spacingXS + (overflowConversations.length > 0 ? 34 + Colors.spacingS : 0)
    readonly property int tabStripWidth: Math.max(96, width - reservedWidth)
    readonly property int tabMaxWidth: Math.max(narrowMode ? 96 : 112, Math.floor(tabStripWidth / Math.max(1, visibleTabLimit)) - Colors.spacingS)

    readonly property var _splitConversations: {
        var convs = AiService.conversations.slice();
        convs.sort(function(a, b) {
            return (b.updatedAt || 0) - (a.updatedAt || 0);
        });
        var active = AiService.activeConversation;
        var limit = visibleTabLimit;
        var primary = [];
        var seen = ({});
        if (active) { primary.push(active); seen[active.id] = true; }
        for (var i = 0; i < convs.length && primary.length < limit; i++) {
            if (!seen[convs[i].id]) { primary.push(convs[i]); seen[convs[i].id] = true; }
        }
        var overflow = [];
        for (var j = 0; j < convs.length; j++) {
            if (!seen[convs[j].id]) overflow.push(convs[j]);
        }
        return { primary: primary, overflow: overflow };
    }
    readonly property var primaryConversations: _splitConversations.primary
    readonly property var overflowConversations: _splitConversations.overflow

    function _formatUpdatedAt(timestamp) {
        if (!timestamp)
            return "Unknown";
        return Qt.formatDateTime(new Date(timestamp), "MMM d · hh:mm");
    }

    function _tabTooltip(conv) {
        return conv.title + "\n" + Providers.providerLabel(conv.provider) + " · " + conv.model + "\nUpdated " + _formatUpdatedAt(conv.updatedAt);
    }

    function _closeConversationWithUndo(id, wasStreaming) {
        if (!AiService.closeConversation(id))
            return;
        editingConversationId = "";
        ToastService.showNoticeAction("Chat closed", wasStreaming ? "Stream cancelled. Undo is available." : "Undo is available for the most recently closed chat.", "Undo", function() {
            AiService.restoreLastClosedConversation();
        });
    }

    function _closeOthersWithNotice(id) {
        var closed = AiService.closeOtherConversations(id);
        if (closed > 0)
            ToastService.showNotice("Other chats closed", closed + " chat" + (closed !== 1 ? "s" : "") + " closed. Use Ctrl+Shift+T to reopen.");
    }

    function _buildTabContextModel(conv) {
        return [
            {
                label: "Rename",
                icon: "󰑕",
                action: function() {
                    AiService.setActiveConversation(conv.id);
                    editingConversationId = conv.id;
                }
            },
            {
                label: "Clear",
                icon: "󰃢",
                action: function() {
                    var wasStreaming = AiService.isStreaming && AiService.activeConversationId === conv.id;
                    AiService.clearConversation(conv.id);
                    ToastService.showNotice("Chat cleared", wasStreaming ? "Stream cancelled and messages were cleared." : "Messages and draft were cleared.");
                }
            },
            {
                label: "Duplicate Prompt",
                icon: "󰆏",
                action: function() {
                    AiService.duplicateConversationPrompt(conv.id);
                }
            },
            { separator: true },
            {
                label: "Close Others",
                icon: "󰘴",
                disabled: AiService.conversations.length <= 1,
                action: function() {
                    _closeOthersWithNotice(conv.id);
                }
            },
            {
                label: "Close",
                icon: "󰅖",
                danger: true,
                action: function() {
                    _closeConversationWithUndo(conv.id, AiService.isStreaming && AiService.activeConversationId === conv.id);
                }
            }
        ];
    }

    Item {
        Layout.fillWidth: true
        height: 38
        clip: true

        Row {
            id: tabRow
            anchors.fill: parent
            spacing: Colors.spacingS
            clip: true

            Repeater {
                model: root.primaryConversations

                delegate: Item {
                    id: tabDelegate
                    required property var modelData
                    required property int index
                    readonly property bool isActive: modelData.id === AiService.activeConversationId
                    readonly property bool isEditing: root.editingConversationId === modelData.id

                    width: isEditing ? Math.min(tabEditInput.width + 22, root.tabMaxWidth) : Math.min(tabLabelText.contentWidth + (root.compactMode ? 52 : 70), root.tabMaxWidth)
                    height: 32

                    Behavior on width {
                        Anim { duration: Colors.durationFast }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Colors.radiusSmall
                        color: isActive ? Colors.highlightLight : (tabMouse.containsMouse ? Colors.withAlpha(Colors.text, 0.05) : "transparent")
                        border.color: isActive ? Colors.primary : (tabMouse.containsMouse ? Colors.withAlpha(Colors.text, 0.25) : Colors.border)
                        border.width: isActive ? 1.5 : 1

                        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
                        Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

                        SharedWidgets.StateLayer {
                            id: tabStateLayer
                            hovered: tabMouse.containsMouse
                            pressed: tabMouse.pressed
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 1.5
                        width: isActive ? parent.width - 20 : 0
                        height: 2
                        radius: Colors.radiusXXXS
                        color: Colors.primary
                        opacity: isActive ? 1 : 0
                        visible: width > 0

                        Behavior on width {
                            NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: Colors.durationFast }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Colors.spacingS
                        anchors.rightMargin: (closeTabBtn.visible ? closeTabBtn.width + 12 : 8)
                        spacing: Colors.spacingXS

                        Text {
                            text: Providers.providerIcon(modelData.provider)
                            color: isActive ? Colors.primary : Colors.textSecondary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeSmall
                            visible: !tabDelegate.isEditing && !root.narrowMode
                        }

                        Rectangle {
                            width: 6
                            height: 6
                            radius: Colors.radiusXS
                            color: Colors.primary
                            visible: isActive && AiService.isStreaming
                            Layout.alignment: Qt.AlignVCenter

                            OpacityAnimator on opacity {
                                from: 0.3
                                to: 1.0
                                duration: Colors.durationPulse
                                running: isActive && AiService.isStreaming
                                loops: Animation.Infinite
                            }
                        }

                        Text {
                            id: tabLabelText
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: modelData.title
                            color: isActive ? Colors.primary : (tabMouse.containsMouse ? Colors.text : Colors.textSecondary)
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: isActive ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            visible: !tabDelegate.isEditing
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    TextInput {
                        id: tabEditInput
                        anchors.left: parent.left
                        anchors.leftMargin: Colors.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(Math.max(72, contentWidth + 8), root.tabMaxWidth - 20)
                        text: modelData.title
                        color: Colors.primary
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.DemiBold
                        visible: tabDelegate.isEditing
                        selectByMouse: true
                        onVisibleChanged: if (visible) {
                            selectAll();
                            forceActiveFocus();
                        }
                        property bool _cancelledEdit: false
                        Keys.onReturnPressed: {
                            AiService.renameConversation(modelData.id, text);
                            root.editingConversationId = "";
                        }
                        Keys.onEscapePressed: { _cancelledEdit = true; root.editingConversationId = ""; }
                        onEditingFinished: {
                            if (!_cancelledEdit)
                                AiService.renameConversation(modelData.id, text);
                            _cancelledEdit = false;
                        }
                    }

                    Rectangle {
                        id: closeTabBtn
                        width: 16
                        height: 16
                        z: 2
                        radius: width / 2
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        opacity: !root.compactMode && (tabMouse.containsMouse || tabDelegate.isActive) ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity {
                            NumberAnimation { duration: Colors.durationFast }
                        }

                        SharedWidgets.StateLayer {
                            id: closeTabStateLayer
                            hovered: closeTabMouse.containsMouse
                            pressed: closeTabMouse.pressed
                            stateColor: Colors.error
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: closeTabMouse.containsMouse ? "white" : Colors.textDisabled
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeXS
                        }

                        MouseArea {
                            id: closeTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                closeTabStateLayer.burst(mouse.x, mouse.y);
                                mouse.accepted = true;
                                root._closeConversationWithUndo(modelData.id, AiService.isStreaming && AiService.activeConversationId === modelData.id);
                            }
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            tabStateLayer.burst(mouse.x, mouse.y);
                            if (mouse.button === Qt.RightButton) {
                                var pos = tabDelegate.mapToItem(root.parent, 0, tabDelegate.height);
                                tabContextMenu.model = root._buildTabContextModel(modelData);
                                tabContextMenu.popup(pos.x, pos.y + Colors.spacingXS);
                                return;
                            }
                            if (!tabDelegate.isEditing)
                                AiService.setActiveConversation(modelData.id);
                        }
                        onDoubleClicked: {
                            AiService.setActiveConversation(modelData.id);
                            root.editingConversationId = modelData.id;
                        }
                    }

                    SharedWidgets.BarTooltip {
                        text: root._tabTooltip(modelData)
                        hovered: tabMouse.containsMouse
                        anchorItem: tabDelegate
                    }
                }
            }
        }
    }

    Rectangle {
        id: overflowButton
        visible: root.overflowConversations.length > 0
        width: 34
        height: 32
        radius: Colors.radiusSmall
        color: overflowMouse.containsMouse ? Colors.primaryGhost : Colors.bgWidget
        border.color: overflowMouse.containsMouse ? Colors.primary : Colors.border
        border.width: 1
        Layout.alignment: Qt.AlignVCenter

        Text {
            anchors.centerIn: parent
            text: root.narrowMode ? "…" : "󰅁"
            color: overflowMouse.containsMouse ? Colors.primary : Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeSmall
        }

        MouseArea {
            id: overflowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                var model = [];
                for (var i = 0; i < root.overflowConversations.length; i++) {
                    var conv = root.overflowConversations[i];
                    model.push({
                        label: conv.title,
                        icon: Providers.providerIcon(conv.provider),
                        action: (function(convId) {
                            return function() {
                                AiService.setActiveConversation(convId);
                            };
                        })(conv.id)
                    });
                }
                var pos = parent.mapToItem(root.parent, 0, parent.height);
                overflowMenu.model = model;
                overflowMenu.popup(pos.x, pos.y + Colors.spacingXS);
            }
        }

        SharedWidgets.BarTooltip {
            text: "More chats"
            hovered: overflowMouse.containsMouse
            anchorItem: overflowButton
        }
    }

    Rectangle {
        width: 32
        height: 32
        radius: Colors.radiusSmall
        color: addConvMouse.containsMouse ? Colors.primaryGhost : Colors.bgWidget
        border.color: addConvMouse.containsMouse ? Colors.primary : Colors.border
        border.width: 1
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: Colors.spacingXS

        Text {
            anchors.centerIn: parent
            text: "+"
            color: addConvMouse.containsMouse ? Colors.primary : Colors.textSecondary
            font.pixelSize: Colors.fontSizeXL
            font.weight: Font.Light
        }

        SharedWidgets.StateLayer {
            id: addConvStateLayer
            hovered: addConvMouse.containsMouse
            pressed: addConvMouse.pressed
        }

        MouseArea {
            id: addConvMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                addConvStateLayer.burst(mouse.x, mouse.y);
                AiService.newConversation();
            }
        }
    }

    SharedWidgets.ContextMenu {
        id: tabContextMenu
        parent: root.parent
    }

    SharedWidgets.ContextMenu {
        id: overflowMenu
        parent: root.parent
    }
}
