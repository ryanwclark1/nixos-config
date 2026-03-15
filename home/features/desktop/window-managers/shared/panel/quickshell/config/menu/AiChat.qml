import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../services"
import "../services/config/AiProviders.js" as Providers
import "../services/config/AiMarkdown.js" as Markdown
import "../widgets" as SharedWidgets

PanelWindow {
    id: root

    readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")

    anchors {
        top: true
        right: true
        bottom: true
    }
    margins.top: edgeMargins.top
    margins.right: edgeMargins.right
    margins.bottom: edgeMargins.bottom

    implicitWidth: panelWidth
    color: "transparent"
    mask: Region {
        item: slidePanel
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell"

    // --- State ---
    property bool showContent: false
    property int panelWidth: 420
    readonly property int panelMinWidth: 320
    readonly property int panelMaxWidth: 600

    signal closeRequested()

    // Panel visibility: stay mapped during slide-out animation
    visible: showContent || slidePanel.x < panelWidth

    onShowContentChanged: {
        if (showContent) {
            inputField.forceActiveFocus();
        } else {
            if (inputField.activeFocus) inputField.focus = false;
            providerDropdown.visible = false;
        }
    }

    // --- Drag-resize state ---
    property real _dragStartX: 0
    property real _dragStartWidth: 0

    // Markdown rendering helpers
    readonly property var _mdColors: ({
        text: Colors.text,
        textSecondary: Colors.textSecondary,
        primary: Colors.primary,
        bgWidget: Colors.bgWidget,
        fontMono: Colors.fontMono,
        codeBg: Colors.withAlpha(Colors.text, 0.06)
    })

    function _renderMarkdown(text) {
        return Markdown.toHtml(text, _mdColors);
    }

    function _renderBlocks(text) {
        return Markdown.toBlocks(text, _mdColors);
    }

    // =========================================================
    //  Keyboard shortcuts
    // =========================================================
    Shortcut {
        sequence: "Escape"
        enabled: root.showContent
        onActivated: root.closeRequested()
    }

    Shortcut {
        sequence: "Ctrl+N"
        enabled: root.showContent
        onActivated: AiService.newConversation()
    }

    // =========================================================
    //  Main panel rectangle — slides in from right
    // =========================================================
    Rectangle {
        id: slidePanel
        width: root.panelWidth
        height: parent.height
        color: Colors.withAlpha(Colors.surface, 0.96)
        border.color: Colors.border
        border.width: 1
        radius: Colors.radiusLarge

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
            GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
        }

        // Inner highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.color: Colors.borderLight
            border.width: 1
            opacity: 0.15
        }

        x: root.showContent ? 0 : root.panelWidth + 10
        opacity: root.showContent ? 1.0 : 0.0

        Behavior on x {
            NumberAnimation {
                id: slideAnim
                duration: 320
                easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }
        }
        Behavior on opacity {
            NumberAnimation { id: fadeAnim; duration: 260 }
        }
        layer.enabled: slideAnim.running || fadeAnim.running

        Keys.onEscapePressed: root.closeRequested()

        // ----------------------------------------------------------
        //  Left-edge drag handle for resizing
        // ----------------------------------------------------------
        Rectangle {
            id: dragHandle
            width: 6
            height: parent.height * 0.15
            radius: 3
            color: dragArea.containsMouse ? Colors.primary : Colors.border
            anchors.left: parent.left
            anchors.leftMargin: -3
            anchors.verticalCenter: parent.verticalCenter
            opacity: dragArea.containsMouse || dragArea.pressed ? 1.0 : 0.4
            Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
            Behavior on color { ColorAnimation { duration: Colors.durationFast } }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                onPressed: (mouse) => {
                    root._dragStartX = mapToGlobal(mouse.x, mouse.y).x;
                    root._dragStartWidth = root.panelWidth;
                }
                onPositionChanged: (mouse) => {
                    if (!pressed) return;
                    var globalX = mapToGlobal(mouse.x, mouse.y).x;
                    var delta = root._dragStartX - globalX;
                    var newW = Math.max(root.panelMinWidth, Math.min(root.panelMaxWidth, root._dragStartWidth + delta));
                    root.panelWidth = Math.round(newW);
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingLarge
            spacing: Colors.spacingM

            // ---- Header ----
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰚩  AI Chat"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXL
                    font.weight: Font.DemiBold
                    font.letterSpacing: Colors.letterSpacingTight
                }

                Item { Layout.fillWidth: true }

                // Provider/model picker
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: Colors.spacingXS
                    Layout.maximumWidth: 140
                    width: providerPickerText.implicitWidth + Colors.spacingL
                    height: 24
                    radius: Colors.radiusXXS
                    color: providerPickerMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.1) : "transparent"
                    border.color: providerPickerMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.3) : "transparent"
                    border.width: 1

                    Text {
                        id: providerPickerText
                        anchors.centerIn: parent
                        text: Providers.providerIcon(AiService.activeProvider) + " " + AiService.activeModel
                        color: providerPickerMouse.containsMouse ? Colors.primary : Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        font.family: Colors.fontMono
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 130)
                    }

                    MouseArea {
                        id: providerPickerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: providerDropdown.visible = !providerDropdown.visible
                    }
                }

                // New conversation
                Rectangle {
                    width: 28; height: 28; radius: Colors.radiusXS
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰐕"
                        color: Colors.textSecondary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeLarge
                    }
                    SharedWidgets.StateLayer {
                        id: newChatStateLayer
                        hovered: newChatHover.containsMouse
                        pressed: newChatHover.pressed
                    }
                    MouseArea {
                        id: newChatHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            newChatStateLayer.burst(mouse.x, mouse.y);
                            AiService.newConversation();
                        }
                    }
                }

                // Close button
                Rectangle {
                    width: 28; height: 28; radius: Colors.radiusMedium
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: Colors.textSecondary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeLarge
                    }
                    SharedWidgets.StateLayer {
                        id: closeStateLayer
                        hovered: closeHover.containsMouse
                        pressed: closeHover.pressed
                    }
                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            closeStateLayer.burst(mouse.x, mouse.y);
                            root.closeRequested();
                        }
                    }
                }
            }

            // ---- Conversation tabs ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingSM

                Item {
                    Layout.fillWidth: true
                    height: 32
                    clip: true

                    Flickable {
                        id: tabFlickable
                        anchors.fill: parent
                        contentWidth: tabRow.implicitWidth
                        contentHeight: height
                        flickableDirection: Flickable.HorizontalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Row {
                            id: tabRow
                            spacing: Colors.spacingXS
                            height: parent.height

                            Repeater {
                                model: AiService.conversations

                                delegate: Item {
                                    id: tabDelegate
                                    required property var modelData
                                    required property int index
                                    property bool isActive: modelData.id === AiService.activeConversationId
                                    property bool isEditing: false

                                    width: isEditing ? tabEditInput.width + 16 : Math.min(tabLabelText.contentWidth + 36, 140)
                                    height: 28

                                    Behavior on width { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Colors.radiusXXS
                                        color: isActive
                                            ? Colors.withAlpha(Colors.primary, 0.18)
                                            : Colors.bgWidget
                                        border.color: isActive ? Colors.primary : Colors.border
                                        border.width: isActive ? 1.5 : 1
                                        Behavior on color { ColorAnimation { duration: Colors.durationFast } }

                                        SharedWidgets.StateLayer {
                                            id: tabStateLayer
                                            hovered: tabMouse.containsMouse
                                            pressed: tabMouse.pressed
                                        }
                                    }

                                    Text {
                                        id: tabLabelText
                                        anchors.left: parent.left
                                        anchors.leftMargin: Colors.spacingS
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.right: deleteTabBtn.left
                                        anchors.rightMargin: Colors.spacingXS
                                        text: modelData.title
                                        color: isActive ? Colors.primary : Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeSmall
                                        font.weight: isActive ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                        visible: !tabDelegate.isEditing
                                    }

                                    TextInput {
                                        id: tabEditInput
                                        anchors.left: parent.left
                                        anchors.leftMargin: Colors.spacingS
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.max(60, contentWidth + 4)
                                        text: modelData.title
                                        color: Colors.primary
                                        font.pixelSize: Colors.fontSizeSmall
                                        font.weight: Font.DemiBold
                                        visible: tabDelegate.isEditing
                                        selectByMouse: true
                                        onVisibleChanged: if (visible) { selectAll(); forceActiveFocus(); }
                                        Keys.onReturnPressed: {
                                            AiService.renameConversation(modelData.id, text);
                                            tabDelegate.isEditing = false;
                                        }
                                        Keys.onEscapePressed: tabDelegate.isEditing = false
                                        onEditingFinished: {
                                            AiService.renameConversation(modelData.id, text);
                                            tabDelegate.isEditing = false;
                                        }
                                    }

                                    Rectangle {
                                        id: deleteTabBtn
                                        width: 14; height: 14; radius: width / 2
                                        anchors.right: parent.right
                                        anchors.rightMargin: 5
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "transparent"
                                        opacity: (tabMouse.containsMouse || tabDelegate.isActive) && AiService.conversations.length > 1 ? 1 : 0
                                        visible: AiService.conversations.length > 1
                                        Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }

                                        SharedWidgets.StateLayer {
                                            id: deleteTabStateLayer
                                            hovered: deleteTabMouse.containsMouse
                                            pressed: deleteTabMouse.pressed
                                            stateColor: Colors.error
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            color: deleteTabMouse.containsMouse ? "white" : Colors.textDisabled
                                            font.family: Colors.fontMono
                                            font.pixelSize: Colors.fontSizeXS
                                        }
                                        MouseArea {
                                            id: deleteTabMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: (mouse) => {
                                                deleteTabStateLayer.burst(mouse.x, mouse.y);
                                                mouse.accepted = true;
                                                AiService.deleteConversation(modelData.id);
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: tabMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            tabStateLayer.burst(mouse.x, mouse.y);
                                            if (mouse.button === Qt.RightButton) {
                                                tabDelegate.isEditing = true;
                                                return;
                                            }
                                            if (!tabDelegate.isEditing) AiService.setActiveConversation(modelData.id);
                                        }
                                        onDoubleClicked: tabDelegate.isEditing = true
                                    }
                                }
                            }
                        }
                    }
                }

                // "+" add conversation button
                Rectangle {
                    width: 28; height: 28; radius: Colors.radiusXS
                    color: Colors.bgWidget
                    border.color: Colors.border; border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeLarge
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
                        onClicked: (mouse) => {
                            addConvStateLayer.burst(mouse.x, mouse.y);
                            AiService.newConversation();
                        }
                    }
                }
            }

            // ---- Message list ----
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.withAlpha(Colors.surface, 0.35)
                border.color: Colors.border
                border.width: 1
                radius: Colors.radiusMedium
                clip: true

                Flickable {
                    id: messageFlickable
                    anchors.fill: parent
                    anchors.margins: 1
                    contentWidth: width
                    contentHeight: messageColumn.implicitHeight + 24
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: messageFlickable.contentHeight > messageFlickable.height
                            ? ScrollBar.AlwaysOn
                            : ScrollBar.AlwaysOff
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
                                color: Colors.withAlpha(Colors.primary, 0.3)
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
                                readonly property var contentBlocks: isAssistant ? root._renderBlocks(modelData.content) : []

                                width: messageColumn.width - Colors.spacingM * 2
                                height: isSystem ? systemBubble.height + Colors.spacingXS : msgLayout.implicitHeight + Colors.spacingXS
                                x: Colors.spacingM

                                // ── System message (slash command output) ──
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
                                        text: isSystem ? root._renderMarkdown(modelData.content) : ""
                                        textFormat: TextEdit.RichText
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeSmall
                                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                        readOnly: true
                                        selectByMouse: true
                                    }
                                }

                                // ── User message ──
                                Column {
                                    id: msgLayout
                                    visible: !isSystem
                                    width: parent.width
                                    spacing: 0

                                    // User bubble (simple, single block)
                                    Rectangle {
                                        visible: isUser
                                        width: Math.min(parent.width * 0.85, userMsgContent.implicitWidth + Colors.spacingL * 2)
                                        height: visible ? userMsgContent.implicitHeight + Colors.spacingM * 2 : 0
                                        radius: Colors.radiusMedium
                                        color: Colors.withAlpha(Colors.primary, 0.15)
                                        border.color: Colors.withAlpha(Colors.primary, 0.3)
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

                                        // Copy button on hover
                                        Rectangle {
                                            width: 22; height: 22; radius: Colors.radiusXXS
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.topMargin: 4; anchors.rightMargin: 4
                                            color: userCopyHover.containsMouse ? Colors.bgWidget : "transparent"
                                            opacity: userHoverArea.containsMouse ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰆏"; color: Colors.textSecondary
                                                font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeSmall
                                            }
                                            MouseArea {
                                                id: userCopyHover
                                                anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Quickshell.execDetached(["sh", "-c", "printf '%s' " + root._shellEscape(modelData.content) + " | wl-copy"]);
                                                    ToastService.showNotice("Copied", "Message copied to clipboard");
                                                }
                                            }
                                        }
                                        MouseArea {
                                            id: userHoverArea
                                            anchors.fill: parent; hoverEnabled: true
                                            acceptedButtons: Qt.NoButton; propagateComposedEvents: true
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
                                                    if (modelData.type === "code") return codeBlockComponent;
                                                    if (modelData.type === "thinking") return thinkingBlockComponent;
                                                    return textBlockComponent;
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

                            Rectangle {
                                id: streamingBubble
                                width: Math.min(parent.width * 0.85, streamingText.implicitWidth + Colors.spacingL * 2 + 20)
                                height: streamingText.implicitHeight + Colors.spacingM * 2
                                radius: Colors.radiusMedium
                                color: Colors.bgGlass
                                border.color: Colors.border
                                border.width: 1

                                TextEdit {
                                    id: streamingText
                                    anchors.fill: parent
                                    anchors.margins: Colors.spacingM
                                    anchors.rightMargin: Colors.spacingM + 16
                                    text: AiService.streamingContent.length > 0
                                        ? root._renderMarkdown(AiService.streamingContent)
                                        : '<span style="color: ' + Colors.textDisabled + ';">Thinking...</span>'
                                    textFormat: TextEdit.RichText
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                    readOnly: true
                                    selectByMouse: true
                                }

                                // Blinking cursor
                                Rectangle {
                                    width: 2; height: 16
                                    radius: 1
                                    color: Colors.primary
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    anchors.bottomMargin: Colors.spacingM
                                    anchors.rightMargin: Colors.spacingS
                                    opacity: cursorBlink.running ? (cursorBlink.cursorVisible ? 1 : 0) : 0
                                    Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }

                                    Timer {
                                        id: cursorBlink
                                        interval: 530
                                        repeat: true
                                        running: AiService.isStreaming
                                        property bool cursorVisible: true
                                        onTriggered: cursorVisible = !cursorVisible
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
                                    width: 28; height: 28; radius: Colors.radiusXS
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
                                        onClicked: (mouse) => {
                                            retryStateLayer.burst(mouse.x, mouse.y);
                                            AiService.retryLastMessage();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Auto-scroll to bottom on new content
                Connections {
                    target: AiService
                    function onStreamingContentChanged() {
                        scrollToBottomTimer.restart();
                    }
                    function onActiveMessagesChanged() {
                        scrollToBottomTimer.restart();
                    }
                }

                Timer {
                    id: scrollToBottomTimer
                    interval: 50
                    onTriggered: {
                        if (messageFlickable.contentHeight > messageFlickable.height) {
                            messageFlickable.contentY = messageFlickable.contentHeight - messageFlickable.height;
                        }
                    }
                }
            }

            // ---- Input area ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: inputLayout.implicitHeight + Colors.spacingM * 2
                color: Colors.withAlpha(Colors.surface, 0.35)
                border.color: inputField.activeFocus ? Colors.primary : Colors.border
                border.width: inputField.activeFocus ? 1.5 : 1
                radius: Colors.radiusMedium
                Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

                ColumnLayout {
                    id: inputLayout
                    anchors.fill: parent
                    anchors.margins: Colors.spacingM
                    spacing: Colors.spacingXS

                    TextEdit {
                        id: inputField
                        Layout.fillWidth: true
                        Layout.minimumHeight: 24
                        Layout.maximumHeight: 120
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                        selectByMouse: true
                        selectedTextColor: Colors.background
                        selectionColor: Colors.primary

                        // Placeholder
                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Type a message..."
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeMedium
                            visible: inputField.text.length === 0 && !inputField.activeFocus
                        }

                        onActiveFocusChanged: if (activeFocus) providerDropdown.visible = false

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                event.accepted = true;
                                root._sendCurrentMessage();
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingS

                        // System context toggle
                        Rectangle {
                            width: 24; height: 24; radius: Colors.radiusXXS
                            color: Config.aiSystemContext ? Colors.withAlpha(Colors.primary, 0.18) : "transparent"
                            border.color: Config.aiSystemContext ? Colors.primary : Colors.border
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰒍"
                                color: Config.aiSystemContext ? Colors.primary : Colors.textDisabled
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeSmall
                            }
                            MouseArea {
                                id: sysCtxHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.aiSystemContext = !Config.aiSystemContext
                            }
                        }

                        // Token / message info
                        Text {
                            text: {
                                var parts = [AiService.activeMessages.length + " msg"];
                                if (AiService.lastTotalTokens > 0) {
                                    parts.push(AiService.lastTotalTokens + " tok");
                                }
                                return parts.join(" · ");
                            }
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXS
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }

                        // Send / Cancel button
                        Rectangle {
                            width: 32; height: 28; radius: Colors.radiusXS
                            color: AiService.isStreaming
                                ? Colors.withAlpha(Colors.error, 0.18)
                                : (inputField.text.trim().length > 0 ? Colors.withAlpha(Colors.primary, 0.18) : "transparent")
                            border.color: AiService.isStreaming ? Colors.error : Colors.primary
                            border.width: AiService.isStreaming || inputField.text.trim().length > 0 ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: AiService.isStreaming ? "󰅖" : "󰒊"
                                color: AiService.isStreaming ? Colors.error : Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeLarge
                            }
                            SharedWidgets.StateLayer {
                                id: sendStateLayer
                                hovered: sendHover.containsMouse
                                pressed: sendHover.pressed
                            }
                            MouseArea {
                                id: sendHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    sendStateLayer.burst(mouse.x, mouse.y);
                                    if (AiService.isStreaming) {
                                        AiService.cancelStream();
                                    } else {
                                        root._sendCurrentMessage();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Footer ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    text: Providers.providerLabel(AiService.activeProvider)
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                }

                Text {
                    text: "·"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                }

                Text {
                    text: AiService.activeModel
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: AiService.conversations.length + " chat" + (AiService.conversations.length !== 1 ? "s" : "")
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                }
            }
        }

        // ── Provider/model dropdown ────────────────────
        Rectangle {
            id: providerDropdown
            visible: false
            width: 220
            height: providerDropdownCol.implicitHeight + Colors.spacingS * 2
            anchors.right: parent.right
            anchors.rightMargin: Colors.paddingLarge
            y: 60
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            radius: Colors.radiusMedium
            z: 20

            Column {
                id: providerDropdownCol
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: Colors.spacingXS

                // Provider section header
                Text {
                    text: "Provider"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.DemiBold
                    leftPadding: Colors.spacingXS
                }

                Repeater {
                    model: Providers.allProviders()

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        property bool isCurrent: modelData === Config.aiProvider
                        width: providerDropdownCol.width - Colors.spacingS * 2
                        height: 26
                        radius: Colors.radiusXXS
                        color: isCurrent ? Colors.withAlpha(Colors.primary, 0.15)
                            : providerItemMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.08) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Colors.spacingS
                            anchors.rightMargin: Colors.spacingS
                            spacing: Colors.spacingXS

                            Text {
                                text: Providers.providerIcon(modelData)
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeSmall
                                color: isCurrent ? Colors.primary : Colors.text
                            }
                            Text {
                                text: Providers.providerLabel(modelData)
                                font.pixelSize: Colors.fontSizeSmall
                                color: isCurrent ? Colors.primary : Colors.text
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: Providers.needsApiKey(modelData) && !AiService.apiKeyAvailable(modelData)
                                text: "󰌆"
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeXS
                                color: Colors.warning
                            }
                        }

                        MouseArea {
                            id: providerItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.aiProvider = modelData;
                                Config.aiModel = "";
                                providerDropdown.visible = false;
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: providerDropdownCol.width - Colors.spacingS * 2
                    height: 1
                    color: Colors.border
                }

                // Model section header
                Text {
                    text: "Model"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.DemiBold
                    leftPadding: Colors.spacingXS
                }

                Repeater {
                    model: AiService.availableModels

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        property bool isCurrent: modelData === AiService.activeModel
                        width: providerDropdownCol.width - Colors.spacingS * 2
                        height: 26
                        radius: Colors.radiusXXS
                        color: isCurrent ? Colors.withAlpha(Colors.primary, 0.15)
                            : modelItemMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.08) : "transparent"

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: Colors.spacingS
                            text: modelData
                            font.pixelSize: Colors.fontSizeSmall
                            font.family: Colors.fontMono
                            color: isCurrent ? Colors.primary : Colors.text
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: modelItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.aiModel = modelData;
                                providerDropdown.visible = false;
                            }
                        }
                    }
                }
            }
        }

        // ── Slash command hints popup ─────────────────
        Rectangle {
            id: slashHints
            visible: inputField.text.indexOf("/") === 0 && inputField.text.indexOf(" ") === -1 && inputField.activeFocus && !AiService.isStreaming
            width: parent.width - Colors.paddingLarge * 2
            height: slashHintsCol.implicitHeight + Colors.spacingS * 2
            x: Colors.paddingLarge
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 120 + Colors.paddingLarge
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            radius: Colors.radiusMedium
            z: 10

            Column {
                id: slashHintsCol
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: 2

                Repeater {
                    model: {
                        var typed = inputField.text.toLowerCase();
                        var cmds = AiService.slashCommands;
                        var filtered = [];
                        for (var i = 0; i < cmds.length; i++) {
                            if (typed.length <= 1 || cmds[i].cmd.indexOf(typed) === 0)
                                filtered.push(cmds[i]);
                        }
                        return filtered;
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: slashHintsCol.width - Colors.spacingS * 2
                        height: 28
                        radius: Colors.radiusXXS
                        color: slashItemMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.1) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Colors.spacingS
                            anchors.rightMargin: Colors.spacingS
                            spacing: Colors.spacingS

                            Text {
                                text: modelData.cmd
                                color: Colors.primary
                                font.pixelSize: Colors.fontSizeSmall
                                font.family: Colors.fontMono
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: modelData.desc
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeSmall
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: slashItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                inputField.text = modelData.cmd + " ";
                                inputField.cursorPosition = inputField.text.length;
                                inputField.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Block components for assistant messages ──
    Component {
        id: textBlockComponent
        Rectangle {
            id: textBlock
            property var blockData: parent ? parent.modelData : null
            width: parent ? parent.width : 0
            height: textBlockEdit.implicitHeight + Colors.spacingM * 2
            radius: Colors.radiusMedium
            color: Colors.bgGlass
            border.color: Colors.border
            border.width: 1

            TextEdit {
                id: textBlockEdit
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                text: blockData ? blockData.html : ""
                textFormat: TextEdit.RichText
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                readOnly: true
                selectByMouse: true
                selectedTextColor: Colors.background
                selectionColor: Colors.primary
            }
        }
    }

    Component {
        id: codeBlockComponent
        Rectangle {
            id: codeBlock
            property var blockData: parent ? parent.modelData : null
            width: parent ? parent.width : 0
            height: codeHeader.height + codeEdit.implicitHeight + Colors.spacingS * 2
            radius: Colors.radiusXS
            color: Colors.withAlpha(Colors.text, 0.06)
            border.color: Colors.withAlpha(Colors.text, 0.1)
            border.width: 1

            // Language label + copy button header
            RowLayout {
                id: codeHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Colors.spacingS
                height: 22
                spacing: Colors.spacingXS

                Text {
                    text: (blockData && blockData.lang) ? blockData.lang : "code"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 20; height: 20; radius: Colors.radiusMicro
                    color: codeCopyHover.containsMouse ? Colors.bgWidget : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰆏"; color: Colors.textSecondary
                        font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXS
                    }
                    MouseArea {
                        id: codeCopyHover
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (blockData) {
                                Quickshell.execDetached(["sh", "-c", "printf '%s' " + root._shellEscape(blockData.content) + " | wl-copy"]);
                                ToastService.showNotice("Copied", "Code copied to clipboard");
                            }
                        }
                    }
                }
            }

            TextEdit {
                id: codeEdit
                anchors.top: codeHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Colors.spacingS
                anchors.topMargin: Colors.spacingXS
                text: blockData ? blockData.content : ""
                textFormat: TextEdit.PlainText
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.family: Colors.fontMono
                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                readOnly: true
                selectByMouse: true
                selectedTextColor: Colors.background
                selectionColor: Colors.primary
            }
        }
    }

    Component {
        id: thinkingBlockComponent
        Rectangle {
            id: thinkingBlock
            property var blockData: parent ? parent.modelData : null
            property bool expanded: false
            width: parent ? parent.width : 0
            height: thinkingHeader.height + (expanded ? thinkingContent.implicitHeight + Colors.spacingS : 0)
            radius: Colors.radiusXS
            color: Colors.withAlpha(Colors.textDisabled, 0.06)
            border.color: Colors.withAlpha(Colors.textDisabled, 0.12)
            border.width: 1
            clip: true

            Behavior on height { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

            RowLayout {
                id: thinkingHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Colors.spacingS
                height: 24
                spacing: Colors.spacingXS

                Text {
                    text: expanded ? "▾" : "▸"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeSmall
                }
                Text {
                    text: "Thinking..."
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeSmall
                    font.italic: true
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                anchors.fill: thinkingHeader
                cursorShape: Qt.PointingHandCursor
                onClicked: thinkingBlock.expanded = !thinkingBlock.expanded
            }

            TextEdit {
                id: thinkingContent
                anchors.top: thinkingHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Colors.spacingS
                anchors.topMargin: Colors.spacingXS
                visible: thinkingBlock.expanded
                text: blockData ? blockData.html : ""
                textFormat: TextEdit.RichText
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                readOnly: true
                selectByMouse: true
                opacity: 0.8
            }
        }
    }

    // ── Helpers ──────────────────────────────────
    function _sendCurrentMessage() {
        var text = inputField.text.trim();
        if (text.length === 0) return;
        if (AiService.isStreaming) return;
        inputField.text = "";
        AiService.sendMessage(text);
    }

    function _shellEscape(str) {
        return "'" + str.replace(/'/g, "'\\''") + "'";
    }
}
