import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets
import "../services/AiProviders.js" as Providers

Rectangle {
    id: root

    required property var anchorWindow
    required property bool overlayMode
    required property bool open
    required property var closeConversationFn
    required property var clearConversationFn
    required property var copyConversationFn
    required property var duplicateConversationFn
    required property var closeOthersFn
    property string editingConversationId: ""

    signal closeRequested()

    readonly property var conversations: {
        var convs = AiService.conversations.slice();
        convs.sort(function(a, b) {
            return (b.updatedAt || 0) - (a.updatedAt || 0);
        });
        return convs;
    }

    color: Colors.withAlpha(Colors.background, overlayMode ? 0.94 : 0.72)
    border.color: Colors.border
    border.width: 1
    radius: Appearance.radiusLarge
    clip: true

    function previewText(conv) {
        if (!conv)
            return "";
        if (conv.draftText && conv.draftText.trim().length > 0)
            return conv.draftText.trim();
        var messages = Array.isArray(conv.messages) ? conv.messages : [];
        if (messages.length === 0)
            return "No messages yet";
        var latest = messages[messages.length - 1];
        return String(latest.content || "").replace(/\s+/g, " ").trim();
    }

    function timestampLabel(ts) {
        if (!ts)
            return "";
        var then = new Date(ts);
        var now = new Date();
        var sameDay = then.getFullYear() === now.getFullYear()
            && then.getMonth() === now.getMonth()
            && then.getDate() === now.getDate();
        return Qt.formatDateTime(then, sameDay ? "hh:mm" : "MMM d");
    }

    function messageCountLabel(conv) {
        var count = Array.isArray(conv && conv.messages) ? conv.messages.length : 0;
        return count + " msg";
    }

    function startRename(id) {
        editingConversationId = id;
    }

    SharedWidgets.InnerHighlight {
        highlightOpacity: 0.12
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacingM
        spacing: Appearance.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Text {
                text: "Recent Chats"
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            SharedWidgets.IconButton {
                icon: "add.svg"
                size: 28
                iconSize: Appearance.fontSizeMedium
                tooltipText: "New conversation"
                tooltipAnchorWindow: root.anchorWindow
                onClicked: AiService.newConversation()
            }

            SharedWidgets.IconButton {
                visible: root.overlayMode
                icon: "dismiss.svg"
                size: 28
                iconSize: Appearance.fontSizeMedium
                tooltipText: "Close history"
                tooltipAnchorWindow: root.anchorWindow
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.border
            opacity: 0.7
        }

        Text {
            Layout.fillWidth: true
            text: root.conversations.length > 0 ? "Pick up where you left off" : "Your conversations will show up here."
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            wrapMode: Text.WordWrap
        }

        ListView {
            id: historyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Appearance.spacingXS
            boundsBehavior: Flickable.StopAtBounds
            model: root.conversations

            delegate: Rectangle {
                id: rowCard
                required property var modelData
                required property int index
                readonly property bool isActive: modelData.id === AiService.activeConversationId
                readonly property bool isStreaming: isActive && AiService.isStreaming
                readonly property bool isEditing: root.editingConversationId === modelData.id

                width: ListView.view.width
                height: cardLayout.implicitHeight + Appearance.spacingS * 2
                radius: Appearance.radiusMedium
                color: isActive ? Colors.highlightLight : (rowHover.containsMouse ? Colors.withAlpha(Colors.text, 0.05) : "transparent")
                border.color: isActive ? Colors.primary : (rowHover.containsMouse ? Colors.withAlpha(Colors.text, 0.16) : Colors.border)
                border.width: isActive ? 1.5 : 1

                SharedWidgets.StateLayer {
                    hovered: rowHover.containsMouse
                    pressed: rowHover.pressed
                }

                RowLayout {
                    id: cardLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS
                    spacing: Appearance.spacingS

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        width: 28
                        height: 28
                        radius: Appearance.radiusSmall
                        color: Colors.withAlpha(isActive ? Colors.primary : Colors.surface, 0.24)
                        border.color: Colors.withAlpha(isActive ? Colors.primary : Colors.border, 0.32)
                        border.width: 1

                        SharedWidgets.SvgIcon {
                            anchors.centerIn: parent
                            source: Providers.providerIcon(modelData.provider)
                            color: isActive ? Colors.primary : Colors.textSecondary
                            size: Appearance.fontSizeMedium
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXS

                            Text {
                                visible: !rowCard.isEditing
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: modelData.title
                                color: isActive ? Colors.text : Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                                font.weight: isActive ? Font.DemiBold : Font.Medium
                                elide: Text.ElideRight
                            }

                            TextInput {
                                id: renameInput
                                visible: rowCard.isEditing
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: modelData.title
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeSmall
                                font.weight: Font.DemiBold
                                selectByMouse: true
                                onVisibleChanged: if (visible) {
                                    selectAll();
                                    forceActiveFocus();
                                }
                                property bool cancelled: false
                                Keys.onReturnPressed: {
                                    AiService.renameConversation(modelData.id, text);
                                    root.editingConversationId = "";
                                }
                                Keys.onEscapePressed: {
                                    cancelled = true;
                                    root.editingConversationId = "";
                                }
                                onEditingFinished: {
                                    if (!visible)
                                        return;
                                    if (!cancelled)
                                        AiService.renameConversation(modelData.id, text);
                                    cancelled = false;
                                    root.editingConversationId = "";
                                }
                            }

                            Rectangle {
                                visible: rowCard.isStreaming
                                width: 6
                                height: 6
                                radius: 3
                                color: Colors.primary
                                Layout.alignment: Qt.AlignVCenter

                                OpacityAnimator on opacity {
                                    from: 0.35
                                    to: 1.0
                                    duration: Appearance.durationPulse
                                    running: rowCard.isStreaming
                                    loops: Animation.Infinite
                                }
                            }

                            Text {
                                text: root.timestampLabel(modelData.updatedAt)
                                color: Colors.textDisabled
                                font.pixelSize: Appearance.fontSizeXS
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: root.previewText(modelData)
                            color: Colors.textDisabled
                            font.pixelSize: Appearance.fontSizeXS
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXS

                            Text {
                                text: Providers.providerLabel(modelData.provider)
                                color: isActive ? Colors.primary : Colors.textDisabled
                                font.pixelSize: Appearance.fontSizeXXS
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "·"
                                color: Colors.textDisabled
                                font.pixelSize: Appearance.fontSizeXXS
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: root.messageCountLabel(modelData)
                                color: Colors.textDisabled
                                font.pixelSize: Appearance.fontSizeXXS
                                elide: Text.ElideRight
                            }
                        }
                    }

                    SharedWidgets.IconButton {
                        id: rowMenuButton
                        Layout.alignment: Qt.AlignTop
                        icon: "more-horizontal.svg"
                        size: 24
                        iconSize: Appearance.fontSizeSmall
                        tooltipText: "Conversation actions"
                        tooltipAnchorWindow: root.anchorWindow
                        onClicked: {
                            var pos = rowCard.mapToItem(root, rowCard.width - width, rowCard.height);
                            rowMenu.model = [
                                {
                                    label: "Rename",
                                    icon: "rename.svg",
                                    action: function() {
                                        root.startRename(modelData.id);
                                    }
                                },
                                {
                                    label: "Duplicate Prompt",
                                    icon: "copy.svg",
                                    action: function() {
                                        root.duplicateConversationFn(modelData.id);
                                    }
                                },
                                {
                                    label: "Copy Transcript",
                                    icon: "copy.svg",
                                    action: function() {
                                        root.copyConversationFn(modelData.id);
                                    }
                                },
                                {
                                    label: "Clear",
                                    icon: "delete.svg",
                                    action: function() {
                                        root.clearConversationFn(modelData.id);
                                    }
                                },
                                { separator: true },
                                {
                                    label: "Close Others",
                                    icon: "dismiss.svg",
                                    disabled: AiService.conversations.length <= 1,
                                    action: function() {
                                        root.closeOthersFn(modelData.id);
                                    }
                                },
                                {
                                    label: "Close",
                                    icon: "dismiss.svg",
                                    danger: true,
                                    action: function() {
                                        root.closeConversationFn(modelData.id);
                                    }
                                }
                            ];
                            rowMenu.popup(pos.x, pos.y + Appearance.spacingXS);
                        }
                    }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            rowMenuButton.clicked(mouse.x, mouse.y);
                            return;
                        }
                        if (!rowCard.isEditing) {
                            AiService.setActiveConversation(modelData.id);
                            if (root.overlayMode)
                                root.closeRequested();
                        }
                    }
                    onDoubleClicked: root.startRename(modelData.id)
                }
            }
        }
    }

    SharedWidgets.ContextMenu {
        id: rowMenu
    }
}
