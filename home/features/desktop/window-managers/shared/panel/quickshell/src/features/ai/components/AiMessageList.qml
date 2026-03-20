import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

// Scrollable message history with streaming indicator and error display.
// Required properties are provided by AiChat.qml.
Rectangle {
    id: root

    // Function references injected by AiChat.qml
    required property var renderBlocksFn    // function(text) -> blocks array
    required property var renderMarkdownFn  // function(text) -> HTML string (for system messages)

    signal quickStartSelected(string text)

    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1
    radius: Appearance.radiusMedium
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
        contentHeight: messageColumn.implicitHeight + Appearance.paddingLarge
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ScrollBar.vertical: ScrollBar {
            policy: messageFlickable.contentHeight > messageFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        Column {
            id: messageColumn
            width: messageFlickable.width - (messageFlickable.contentHeight > messageFlickable.height ? 12 : 0)
            spacing: Appearance.spacingS
            topPadding: Appearance.spacingM
            bottomPadding: Appearance.spacingM
            leftPadding: Appearance.spacingM
            rightPadding: Appearance.spacingM

            // Empty state
            Column {
                width: parent.width - Appearance.spacingM * 2
                visible: AiService.activeMessages.length === 0 && !AiService.isStreaming
                spacing: Appearance.spacingL
                topPadding: 40

                SharedWidgets.SvgIcon {
                    source: "sparkle.svg"
                    color: Colors.primaryRing
                    size: Appearance.fontSizeGigantic
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    width: parent.width
                    text: "Start a conversation"
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeLarge
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: "Type a message or use <b>/help</b> for commands"
                    textFormat: Text.RichText
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                }

                // Quick-start prompt chips
                Flow {
                    width: parent.width
                    spacing: Appearance.spacingS
                    leftPadding: Appearance.spacingL
                    rightPadding: Appearance.spacingL

                    Repeater {
                        model: [
                            { icon: "copy.svg", label: "Summarize clipboard", prompt: "Summarize the text in my clipboard concisely." },
                            { icon: "bug.svg", label: "Explain error", prompt: "Explain this error and suggest a fix:" },
                            { icon: "terminal.svg", label: "Write a script", prompt: "Write a shell script that " },
                            { icon: "settings.svg", label: "System check", prompt: "Analyze my current system status and suggest improvements." }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            width: qsChipRow.implicitWidth + Appearance.spacingL
                            height: 30
                            radius: Appearance.radiusPill
                            color: qsChipMouse.containsMouse ? Colors.primaryGhost : Colors.textFaint
                            border.color: qsChipMouse.containsMouse ? Colors.primaryRing : Colors.border
                            border.width: 1

                            Row {
                                id: qsChipRow
                                anchors.centerIn: parent
                                spacing: Appearance.spacingXS
                                Loader {
                                    property string _ic: modelData.icon || ""
                                    sourceComponent: String(_ic).endsWith(".svg") ? _qsSvg : _qsNerd
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Component { id: _qsSvg; SharedWidgets.SvgIcon { source: parent._ic; color: qsChipMouse.containsMouse ? Colors.primary : Colors.textSecondary; size: Appearance.fontSizeSmall } }
                                Component { id: _qsNerd; Text { text: parent._ic; color: qsChipMouse.containsMouse ? Colors.primary : Colors.textSecondary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeSmall } }
                                Text {
                                    text: modelData.label
                                    color: qsChipMouse.containsMouse ? Colors.text : Colors.textSecondary
                                    font.pixelSize: Appearance.fontSizeSmall
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: qsChipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.quickStartSelected(modelData.prompt)
                            }
                        }
                    }
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

                    width: messageColumn.width - Appearance.spacingM * 2
                    height: isSystem ? systemBubble.height + Appearance.spacingXS : msgLayout.implicitHeight + Appearance.spacingXS
                    x: Appearance.spacingM

                    // System message (slash command output)
                    Rectangle {
                        id: systemBubble
                        visible: isSystem
                        width: parent.width
                        height: visible ? systemText.implicitHeight + Appearance.spacingS * 2 : 0
                        radius: Appearance.radiusXS
                        color: Colors.withAlpha(Colors.textDisabled, 0.08)
                        border.color: Colors.withAlpha(Colors.textDisabled, 0.15)
                        border.width: 1

                        TextEdit {
                            id: systemText
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingS
                            text: isSystem ? root.renderMarkdownFn(modelData.content) : ""
                            textFormat: TextEdit.RichText
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeSmall
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
                            width: Math.min(parent.width * 0.85, userMsgContent.implicitWidth + Appearance.spacingL * 2)
                            height: visible ? userMsgContent.implicitHeight + Appearance.spacingM * 2 : 0
                            radius: Appearance.radiusMedium
                            color: Colors.highlightLight
                            border.color: Colors.primaryRing
                            border.width: 1
                            anchors.right: parent.right

                            TextEdit {
                                id: userMsgContent
                                anchors.fill: parent
                                anchors.margins: Appearance.spacingM
                                text: isUser ? modelData.content : ""
                                textFormat: TextEdit.PlainText
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
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
                                radius: Appearance.radiusXXS
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 4
                                anchors.rightMargin: 4
                                color: userCopyHover.containsMouse ? Colors.bgWidget : "transparent"
                                opacity: userHoverArea.containsMouse ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: Appearance.durationFast }
                                }
                                SharedWidgets.SvgIcon {
                                    anchors.centerIn: parent
                                    source: "copy.svg"
                                    color: Colors.textSecondary
                                    size: Appearance.fontSizeSmall
                                }
                                MouseArea {
                                    id: userCopyHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", modelData.content]);
                                        ToastService.showNotice("Copied", "Message copied to clipboard");
                                    }
                                }
                                Tooltip {
                                    text: "Copy message"
                                    shown: userCopyHover.containsMouse
                                    preferredSide: Qt.LeftEdge
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
                            spacing: Appearance.spacingXS

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

                            // Regenerate + copy actions row
                            Row {
                                spacing: Appearance.spacingXS
                                opacity: assistantHoverArea.containsMouse ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { duration: Appearance.durationFast }
                                }

                                Rectangle {
                                    width: 22; height: 22
                                    radius: Appearance.radiusXXS
                                    color: regenHover.containsMouse ? Colors.bgWidget : "transparent"
                                    SharedWidgets.SvgIcon {
                                        anchors.centerIn: parent
                                        source: "arrow-repeat.svg"
                                        color: Colors.textSecondary
                                        size: Appearance.fontSizeSmall
                                    }
                                    MouseArea {
                                        id: regenHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AiService.regenerateFromMessage(msgDelegate.index)
                                    }
                                    Tooltip {
                                        text: "Regenerate response"
                                        shown: regenHover.containsMouse
                                        preferredSide: Qt.BottomEdge
                                    }
                                }

                                Rectangle {
                                    width: 22; height: 22
                                    radius: Appearance.radiusXXS
                                    color: assistCopyHover.containsMouse ? Colors.bgWidget : "transparent"
                                    SharedWidgets.SvgIcon {
                                        anchors.centerIn: parent
                                        source: "copy.svg"
                                        color: Colors.textSecondary
                                        size: Appearance.fontSizeSmall
                                    }
                                    MouseArea {
                                        id: assistCopyHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", msgDelegate.modelData.content]);
                                            ToastService.showNotice("Copied", "Response copied to clipboard");
                                        }
                                    }
                                    Tooltip {
                                        text: "Copy response"
                                        shown: assistCopyHover.containsMouse
                                        preferredSide: Qt.BottomEdge
                                    }
                                }
                            }
                        }
                    }

                    // Hover area for assistant actions — lives on the delegate Item, not inside the Column
                    MouseArea {
                        id: assistantHoverArea
                        anchors.fill: parent
                        visible: isAssistant
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        propagateComposedEvents: true
                    }
                }
            }

            // Streaming indicator
            Column {
                width: messageColumn.width - Appearance.spacingM * 2
                visible: AiService.isStreaming
                spacing: Appearance.spacingXS
                readonly property var streamingBlocks: root.renderBlocksFn(AiService.streamingContent)

                // Waiting-for-first-token placeholder
                Rectangle {
                    visible: AiService.isStreaming && AiService.streamingContent.length === 0
                    width: 140
                    height: Appearance.controlRowHeight
                    radius: Appearance.radiusMedium
                    color: Colors.bgGlass
                    border.color: Colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingM
                        spacing: Appearance.spacingS
                        SharedWidgets.SvgIcon {
                            source: "sparkle.svg"
                            color: Colors.primary
                            size: Appearance.fontSizeLarge
                            OpacityAnimator on opacity {
                                from: 0.3; to: 1.0; duration: Appearance.durationLong
                                running: AiService.isStreaming && AiService.streamingContent.length === 0
                                loops: Animation.Infinite
                            }
                        }
                        Text {
                            text: "Thinking" + (AiService.streamElapsedSec > 0 ? "... " + AiService.streamElapsedSec + "s" : "...")
                            color: Colors.textDisabled
                            font.pixelSize: Appearance.fontSizeSmall
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
                width: messageColumn.width - Appearance.spacingM * 2
                height: errorRow.height + Appearance.spacingXS
                visible: AiService.lastError.length > 0 && !AiService.isStreaming
                x: Appearance.spacingM

                RowLayout {
                    id: errorRow
                    width: parent.width
                    spacing: Appearance.spacingS

                    Rectangle {
                        Layout.fillWidth: true
                        height: errorText.implicitHeight + Appearance.spacingM * 2
                        radius: Appearance.radiusMedium
                        color: Colors.withAlpha(Colors.error, 0.12)
                        border.color: Colors.withAlpha(Colors.error, 0.3)
                        border.width: 1

                        Text {
                            id: errorText
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingM
                            text: AiService.lastError
                            color: Colors.error
                            font.pixelSize: Appearance.fontSizeSmall
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                    }

                    // Retry button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: Appearance.radiusXS
                        color: "transparent"
                        SharedWidgets.SvgIcon {
                            anchors.centerIn: parent
                            source: "arrow-repeat.svg"
                            color: Colors.textSecondary
                            size: Appearance.fontSizeLarge
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
                        Tooltip {
                            text: "Retry"
                            shown: retryHover.containsMouse
                            preferredSide: Qt.TopEdge
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
