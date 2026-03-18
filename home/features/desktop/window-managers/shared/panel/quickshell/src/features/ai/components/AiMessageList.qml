import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../widgets" as SharedWidgets

// Scrollable message history with streaming indicator and error display.
// Required properties are provided by AiChat.qml.
Rectangle {
    id: root

    // Function references injected by AiChat.qml
    required property var renderBlocksFn    // function(text) -> blocks array
    required property var renderMarkdownFn  // function(text) -> HTML string (for system messages)
    required property var shellEscapeFn     // function(str) -> shell-escaped string

    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    // Inline Component wrappers so Loader.sourceComponent works with the
    // extracted block types registered via qmldir.
    Component { id: textBlockComp;       AiTextBlock {}       }
    Component { id: codeBlockComp;       AiCodeBlock {}       }
    Component { id: streamTextBlockComp; AiStreamTextBlock {} }
    Component { id: thinkingBlockComp;   AiThinkingBlock {}   }

    function scrollToBottom() {
        if (messageFlickable.contentHeight > messageFlickable.height) {
            messageFlickable.contentY = messageFlickable.contentHeight - messageFlickable.height;
        }
    }

    Flickable {
        id: messageFlickable
        anchors.fill: parent
        anchors.margins: 1
        contentWidth: width
        contentHeight: messageColumn.implicitHeight + Colors.paddingLarge
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ScrollBar.vertical: ScrollBar {
            policy: messageFlickable.contentHeight > messageFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        Column {
            id: messageColumn
            width: messageFlickable.width - (messageFlickable.contentHeight > messageFlickable.height ? 12 : 0)
            spacing: Colors.spacingS
            topPadding: Colors.spacingM
            bottomPadding: Colors.spacingM
            leftPadding: Colors.spacingM
            rightPadding: Colors.spacingM

            // Empty state
            Column {
                width: parent.width - Colors.spacingM * 2
                visible: AiService.activeMessages.length === 0 && !AiService.isStreaming
                spacing: Colors.spacingL
                topPadding: 40

                Text {
                    width: parent.width
                    text: "󰚩"
                    color: Colors.primaryRing
                    font.family: Colors.fontMono
                    font.pixelSize: 48
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: "Start a conversation"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeLarge
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: "Type a message or use <b>/help</b> for commands"
                    textFormat: Text.RichText
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: AiService.activeMessages

                delegate: Item {
                    id: msgDelegate
                    required property var modelData
                    required property int index
                    readonly property bool isUser: modelData.role === "user"
                    readonly property bool isSystem: modelData.role === "system"
                    readonly property bool isAssistant: modelData.role === "assistant"
                    readonly property bool isError: isAssistant && (modelData.content || "").indexOf("ERROR:") === 0
                    readonly property var contentBlocks: isAssistant ? root.renderBlocksFn(modelData.content) : []

                    width: messageColumn.width - Colors.spacingM * 2
                    height: isSystem ? systemBubble.height + Colors.spacingXS : msgLayout.implicitHeight + Colors.spacingXS
                    x: Colors.spacingM

                    // System message (slash command output)
                    Rectangle {
                        id: systemBubble
                        visible: isSystem
                        width: parent.width
                        height: visible ? systemText.implicitHeight + Colors.spacingS * 2 : 0
                        radius: Colors.radiusXS
                        color: Colors.withAlpha(Colors.textDisabled, 0.08)
                        border.color: Colors.withAlpha(Colors.textDisabled, 0.15)
                        border.width: 1

                        TextEdit {
                            id: systemText
                            anchors.fill: parent
                            anchors.margins: Colors.spacingS
                            text: isSystem ? root.renderMarkdownFn(modelData.content) : ""
                            textFormat: TextEdit.RichText
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                            readOnly: true
                            selectByMouse: true
                        }
                    }

                    // User and assistant messages
                    Column {
                        id: msgLayout
                        visible: !isSystem
                        width: parent.width
                        spacing: 0

                        // User bubble
                        Rectangle {
                            visible: isUser
                            width: Math.min(parent.width * 0.85, userMsgContent.implicitWidth + Colors.spacingL * 2)
                            height: visible ? userMsgContent.implicitHeight + Colors.spacingM * 2 : 0
                            radius: Colors.radiusMedium
                            color: Colors.highlightLight
                            border.color: Colors.primaryRing
                            border.width: 1
                            anchors.right: parent.right

                            TextEdit {
                                id: userMsgContent
                                anchors.fill: parent
                                anchors.margins: Colors.spacingM
                                text: isUser ? modelData.content : ""
                                textFormat: TextEdit.PlainText
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                readOnly: true
                                selectByMouse: true
                                selectedTextColor: Colors.background
                                selectionColor: Colors.primary
                            }

                            // Copy button (shown on hover)
                            Rectangle {
                                width: 22
                                height: 22
                                radius: Colors.radiusXXS
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 4
                                anchors.rightMargin: 4
                                color: userCopyHover.containsMouse ? Colors.bgWidget : "transparent"
                                opacity: userHoverArea.containsMouse ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: Colors.durationFast }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆏"
                                    color: Colors.textSecondary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeSmall
                                }
                                MouseArea {
                                    id: userCopyHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["sh", "-c", "printf '%s' " + root.shellEscapeFn(modelData.content) + " | wl-copy"]);
                                        ToastService.showNotice("Copied", "Message copied to clipboard");
                                    }
                                }
                            }
                            MouseArea {
                                id: userHoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                                propagateComposedEvents: true
                            }
                        }

                        // Assistant message — block-based rendering
                        Column {
                            visible: isAssistant
                            width: Math.min(parent.width * 0.85, parent.width)
                            spacing: Colors.spacingXS

                            Repeater {
                                model: contentBlocks

                                delegate: Loader {
                                    id: blockLoader
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    sourceComponent: {
                                        if (modelData.type === "code")
                                            return codeBlockComp;
                                        if (modelData.type === "thinking")
                                            return thinkingBlockComp;
                                        return textBlockComp;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Streaming indicator
            Column {
                width: messageColumn.width - Colors.spacingM * 2
                visible: AiService.isStreaming
                spacing: Colors.spacingXS
                readonly property var streamingBlocks: root.renderBlocksFn(AiService.streamingContent)

                // Waiting-for-first-token placeholder
                Rectangle {
                    visible: AiService.isStreaming && AiService.streamingContent.length === 0
                    width: 140
                    height: 38
                    radius: Colors.radiusMedium
                    color: Colors.bgGlass
                    border.color: Colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Colors.spacingM
                        spacing: Colors.spacingS
                        Text {
                            text: "󰚩"
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeLarge
                            OpacityAnimator on opacity {
                                from: 0.3; to: 1.0; duration: Colors.durationLong
                                running: AiService.isStreaming && AiService.streamingContent.length === 0
                                loops: Animation.Infinite
                            }
                        }
                        Text {
                            text: "Thinking..."
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeSmall
                            font.italic: true
                        }
                    }
                }

                Repeater {
                    model: parent.streamingBlocks

                    delegate: Loader {
                        id: streamBlockLoader
                        required property var modelData
                        required property int index
                        width: parent.width
                        sourceComponent: {
                            if (modelData.type === "code")
                                return codeBlockComp;
                            if (modelData.type === "thinking")
                                return thinkingBlockComp;
                            return streamTextBlockComp;
                        }
                    }
                }
            }

            // Error display
            Item {
                width: messageColumn.width - Colors.spacingM * 2
                height: errorRow.height + Colors.spacingXS
                visible: AiService.lastError.length > 0 && !AiService.isStreaming
                x: Colors.spacingM

                RowLayout {
                    id: errorRow
                    width: parent.width
                    spacing: Colors.spacingS

                    Rectangle {
                        Layout.fillWidth: true
                        height: errorText.implicitHeight + Colors.spacingM * 2
                        radius: Colors.radiusMedium
                        color: Colors.withAlpha(Colors.error, 0.12)
                        border.color: Colors.withAlpha(Colors.error, 0.3)
                        border.width: 1

                        Text {
                            id: errorText
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            text: AiService.lastError
                            color: Colors.error
                            font.pixelSize: Colors.fontSizeSmall
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                    }

                    // Retry button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: Colors.radiusXS
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            color: Colors.textSecondary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeLarge
                        }
                        SharedWidgets.StateLayer {
                            id: retryStateLayer
                            hovered: retryHover.containsMouse
                            pressed: retryHover.pressed
                        }
                        MouseArea {
                            id: retryHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                retryStateLayer.burst(mouse.x, mouse.y);
                                AiService.retryLastMessage();
                            }
                        }
                    }
                }
            }
        }
    }

    // Auto-scroll to bottom when new content arrives
    Connections {
        target: AiService
        function onStreamingContentChanged() { scrollToBottomTimer.restart(); }
        function onActiveMessagesChanged()   { scrollToBottomTimer.restart(); }
    }

    Timer {
        id: scrollToBottomTimer
        interval: 50
        onTriggered: root.scrollToBottom()
    }
}
