import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../services"
import "services/AiProviders.js" as Providers
import "services/AiMarkdown.js" as Markdown
import "services/AiProviderProfiles.js" as Profiles
import "../../shared"
import "../../widgets" as SharedWidgets
import "../../features/settings/components"
import "components"

PanelWindow {
    id: root

    readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")

    anchors {
        top: true
        right: true
        bottom: true
    }
    margins.top: edgeMargins.top
    margins.right: Math.max(edgeMargins.right, Appearance.spacingS)
    margins.bottom: edgeMargins.bottom

    implicitWidth: panelWidth
    color: "transparent"
    mask: Region {
        item: slidePanel
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.showContent ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell"

    // --- State ---
    property bool showContent: false
    property int panelWidth: _persist.panelWidth
    readonly property int panelMinWidth: 320
    readonly property int panelMaxWidth: 600

    PersistentProperties {
        id: _persist
        reloadableId: "aiChatState"
        property int panelWidth: 420
    }
    readonly property bool compactHeader: slidePanel.width < 420
    readonly property bool narrowHeader: slidePanel.width < 360
    readonly property bool compactFooter: slidePanel.width < 380
    readonly property bool narrowFooter: slidePanel.width < 340
    property bool includeWindowContext: false
    property bool includeVisualContext: false
    property bool includeSelectionContext: false

    property var attachedFiles: []
    property string _pendingMsgText: ""
    property int _fileReadIndex: 0
    property bool _privacyDismissed: false

    signal closeRequested

    function clearInteractiveFocus() {
        if (inputField.activeFocus)
            inputField.focus = false;
        if (slidePanel.activeFocus)
            slidePanel.focus = false;
    }

    // Panel visibility: stay mapped during slide-out animation
    visible: showContent || slidePanel.x < panelWidth

    onShowContentChanged: {
        if (showContent) {
            root._syncInputFromService();
            inputField.forceActiveFocus();
        } else {
            clearInteractiveFocus();
            providerDropdown.visible = false;
        }
    }

    Component.onCompleted: {
        root._syncInputFromService();
        // If AiChat was lazy-loaded after a region capture (e.g. "Analyze with AI"),
        // auto-enable visual context since the regionCaptured signal fired before creation.
        if (ScreenshotService.lastRegionPath !== "" && !root.includeVisualContext)
            root.includeVisualContext = true;
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
            fontMono: Appearance.fontMono,
            codeBg: Colors.textFaint
        })

    function _renderMarkdown(text) {
        return Markdown.toHtml(text, _mdColors);
    }

    function _renderBlocks(text) {
        return Markdown.toBlocks(text, _mdColors);
    }

    function _sortedConversationIds() {
        var convs = AiService.conversations.slice();
        convs.sort(function(a, b) {
            return (b.updatedAt || 0) - (a.updatedAt || 0);
        });
        var ids = [];
        for (var i = 0; i < convs.length; i++)
            ids.push(convs[i].id);
        return ids;
    }

    function _activateConversationOffset(delta) {
        var ids = _sortedConversationIds();
        if (ids.length <= 1)
            return;
        var currentIndex = ids.indexOf(AiService.activeConversationId);
        if (currentIndex === -1)
            currentIndex = 0;
        var nextIndex = (currentIndex + delta + ids.length) % ids.length;
        AiService.setActiveConversation(ids[nextIndex]);
    }

    function _closeConversationWithUndo(id) {
        if (!id)
            return;
        var wasStreaming = AiService.isStreaming && AiService.activeConversationId === id;
        if (!AiService.closeConversation(id))
            return;
        ToastService.showNoticeAction("Chat closed", wasStreaming ? "Stream cancelled. Undo is available." : "Undo is available for the most recently closed chat.", "Undo", function() {
            AiService.restoreLastClosedConversation();
        });
    }

    function _clearConversationWithNotice(id) {
        if (!id)
            return;
        var wasStreaming = AiService.isStreaming && AiService.activeConversationId === id;
        AiService.clearConversation(id);
        ToastService.showNotice("Chat cleared", wasStreaming ? "Stream cancelled and messages were cleared." : "Messages and draft were cleared.");
    }

    function _syncInputFromService() {
        if (inputField && inputField.text !== AiService.activeDraftText)
            inputField.text = AiService.activeDraftText;
    }

    // =========================================================
    //  Keyboard shortcuts
    // =========================================================
    // =========================================================
    //  Main panel rectangle — slides in from right
    // =========================================================
    Rectangle {
        id: slidePanel
        width: root.panelWidth
        height: parent.height
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1
        radius: Appearance.radiusLarge

        // Inner highlight
        SharedWidgets.InnerHighlight {
            highlightOpacity: 0.15
        }

        x: root.showContent ? 0 : root.panelWidth + 10
        opacity: root.showContent ? 1.0 : 0.0

        Behavior on x {
            NumberAnimation {
                id: slideAnim
                duration: Appearance.durationPanelOpen
                easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }
        }
        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: Appearance.durationPanelClose
            }
        }
        layer.enabled: slideAnim.running || fadeAnim.running

        Keys.onEscapePressed: root.closeRequested()
        Keys.onPressed: event => {
            if (!root.showContent || !(event.modifiers & Qt.ControlModifier))
                return;

            if (event.key === Qt.Key_N) {
                AiService.newConversation();
                event.accepted = true;
            } else if (event.key === Qt.Key_W) {
                root._closeConversationWithUndo(AiService.activeConversationId);
                event.accepted = true;
            } else if ((event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_T) {
                if (AiService.hasRestorableClosedConversation) {
                    AiService.restoreLastClosedConversation();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root._activateConversationOffset((event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab ? -1 : 1);
                event.accepted = true;
            }
        }

        DropArea {
            anchors.fill: parent
            keys: ["file"]
            onDropped: drop => {
                if (drop.hasUrls) {
                    for (var i = 0; i < drop.urls.length; i++) {
                        var url = drop.urls[i].toString();
                        var path = url.replace("file://", "");
                        var name = path.split("/").pop();
                        root.attachedFiles = root.attachedFiles.concat([
                            {
                                type: "file",
                                name: name,
                                path: path,
                                content: ""
                            }
                        ]);
                    }
                }
            }
        }

        // ----------------------------------------------------------
        //  Left-edge drag handle for resizing
        // ----------------------------------------------------------
        Rectangle {
            id: dragHandle
            width: 6
            height: parent.height * 0.15
            radius: Appearance.radiusXS
            color: dragArea.containsMouse ? Colors.primary : Colors.border
            anchors.left: parent.left
            anchors.leftMargin: -3
            anchors.verticalCenter: parent.verticalCenter
            opacity: dragArea.containsMouse || dragArea.pressed ? 1.0 : 0.4
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.durationFast
                }
            }
            Behavior on color {
                enabled: !Colors.isTransitioning
                CAnim {}
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                onPressed: mouse => {
                    root._dragStartX = mapToGlobal(mouse.x, mouse.y).x;
                    root._dragStartWidth = root.panelWidth;
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    var globalX = mapToGlobal(mouse.x, mouse.y).x;
                    var delta = root._dragStartX - globalX;
                    var newW = Math.max(root.panelMinWidth, Math.min(root.panelMaxWidth, root._dragStartWidth + delta));
                    _persist.panelWidth = Math.round(newW);
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.paddingLarge
            spacing: Appearance.spacingM

            // ---- Header ----
            RowLayout {
                Layout.fillWidth: true
                spacing: root.narrowHeader ? Appearance.spacingXS : Appearance.spacingS
                clip: true

                SharedWidgets.SvgIcon {
                    source: "sparkle.svg"
                    color: Colors.text
                    size: root.narrowHeader ? Appearance.fontSizeLarge : Appearance.fontSizeXL
                }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "AI Chat"
                    color: Colors.text
                    font.pixelSize: root.narrowHeader ? Appearance.fontSizeLarge : Appearance.fontSizeXL
                    font.weight: Font.DemiBold
                    font.letterSpacing: Appearance.letterSpacingTight
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Item {
                    Layout.fillWidth: true
                    visible: !root.narrowHeader
                }

                // Provider/model picker
                Rectangle {
                    id: providerPickerBtn
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: Appearance.spacingXS
                    Layout.maximumWidth: 140
                    width: providerPickerContent.implicitWidth + Appearance.spacingL
                    height: 24
                    visible: !root.compactHeader
                    radius: Appearance.radiusXXS
                    color: providerPickerMouse.containsMouse ? Colors.primaryGhost : "transparent"
                    border.color: providerPickerMouse.containsMouse ? Colors.primaryRing : "transparent"
                    border.width: 1

                    Row {
                        id: providerPickerContent
                        anchors.centerIn: parent
                        spacing: Appearance.spacingXS
                        width: Math.min(implicitWidth, 130)

                        SharedWidgets.SvgIcon {
                            source: Providers.providerIcon(AiService.activeProvider)
                            color: providerPickerMouse.containsMouse ? Colors.primary : Colors.textDisabled
                            size: Appearance.fontSizeXS
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: providerPickerText
                            text: AiService.activeModel
                            color: providerPickerMouse.containsMouse ? Colors.primary : Colors.textDisabled
                            font.pixelSize: Appearance.fontSizeXS
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 130 - parent.spacing - Appearance.fontSizeXS)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: providerPickerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: providerDropdown.visible = !providerDropdown.visible
                    }

                    Tooltip {
                        text: "Change AI provider and model"
                        shown: providerPickerMouse.containsMouse
                    }
                }

                // Copy All
                Rectangle {
                    id: copyAllButton
                    width: 28
                    height: 28
                    radius: Appearance.radiusXS
                    color: "transparent"
                    visible: !root.narrowHeader && AiService.activeMessages.length > 0
                    SharedWidgets.SvgIcon {
                        anchors.centerIn: parent
                        source: "copy.svg"
                        color: Colors.textSecondary
                        size: Appearance.fontSizeLarge
                    }
                    SharedWidgets.StateLayer {
                        id: copyAllStateLayer
                        hovered: copyAllHover.containsMouse
                        pressed: copyAllHover.pressed
                    }
                    MouseArea {
                        id: copyAllHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            copyAllStateLayer.burst(mouse.x, mouse.y);
                            var fullText = "";
                            var msgs = AiService.activeMessages;
                            for (var i = 0; i < msgs.length; i++) {
                                fullText += (msgs[i].role === "user" ? "### User\n" : "### Assistant\n") + msgs[i].content + "\n\n";
                            }
                            Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", fullText]);
                            ToastService.showNotice("Copied", "Full conversation copied to clipboard");
                        }
                    }
                    Tooltip {
                        text: "Copy full conversation"
                        shown: copyAllHover.containsMouse
                    }
                }

                // Clear conversation
                Rectangle {
                    id: clearChatButton
                    width: 28
                    height: 28
                    radius: Appearance.radiusXS
                    color: "transparent"
                    visible: !root.narrowHeader && (AiService.activeMessages.length > 0 || AiService.activeDraftText.length > 0)
                    SharedWidgets.SvgIcon {
                        anchors.centerIn: parent
                        source: "delete.svg"
                        color: Colors.textSecondary
                        size: Appearance.fontSizeLarge
                    }
                    SharedWidgets.StateLayer {
                        id: clearChatStateLayer
                        hovered: clearChatHover.containsMouse
                        pressed: clearChatHover.pressed
                    }
                    MouseArea {
                        id: clearChatHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            clearChatStateLayer.burst(mouse.x, mouse.y);
                            root._clearConversationWithNotice(AiService.activeConversationId);
                        }
                    }
                    Tooltip {
                        text: "Clear current chat messages"
                        shown: clearChatHover.containsMouse
                    }
                }

                // New conversation
                Rectangle {
                    id: newChatButton
                    width: 28
                    height: 28
                    radius: Appearance.radiusXS
                    color: newChatHover.containsMouse ? Colors.primaryGhost : "transparent"
                    border.color: newChatHover.containsMouse ? Colors.primaryRing : "transparent"
                    border.width: 1

                    SharedWidgets.SvgIcon {
                        anchors.centerIn: parent
                        source: "add.svg"
                        color: newChatHover.containsMouse ? Colors.primary : Colors.textSecondary
                        size: Appearance.fontSizeLarge
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
                        onClicked: mouse => {
                            newChatStateLayer.burst(mouse.x, mouse.y);
                            AiService.newConversation();
                        }
                    }
                    Tooltip {
                        text: "New Conversation (Ctrl+N)"
                        shown: newChatHover.containsMouse
                    }
                }

                // Close button
                Rectangle {
                    id: closeBtn
                    width: 28
                    height: 28
                    radius: Appearance.radiusMedium
                    color: "transparent"
                    SharedWidgets.SvgIcon {
                        anchors.centerIn: parent
                        source: "dismiss.svg"
                        color: Colors.textSecondary
                        size: Appearance.fontSizeLarge
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
                        onClicked: mouse => {
                            closeStateLayer.burst(mouse.x, mouse.y);
                            root.closeRequested();
                        }
                    }
                    Tooltip {
                        text: "Close AI Chat"
                        shown: closeHover.containsMouse
                    }
                }
            }

            // ---- Conversation tabs ----
            AiConversationTabs {
                Layout.fillWidth: true
            }

            // ---- Command Confirmation ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: cmdCol.implicitHeight + Appearance.paddingLarge
                radius: Appearance.radiusMedium
                color: Colors.withAlpha(Colors.accent, 0.12)
                border.color: Colors.accent
                border.width: 1
                visible: AiService.pendingCommand !== null
                clip: true

                opacity: visible ? 1.0 : 0.0
                scale: visible ? 1.0 : 0.95
                Behavior on opacity {
                    Anim {}
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.durationSlow
                        easing.type: Easing.OutBack
                    }
                }

                ColumnLayout {
                    id: cmdCol
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingM
                    spacing: Appearance.spacingS

                    RowLayout {
                        spacing: Appearance.spacingS
                        SharedWidgets.SvgIcon {
                            source: "settings.svg"
                            color: Colors.accent
                            size: Appearance.fontSizeXL
                        }
                        Text {
                            text: "Suggested System Action"
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: cmdLabel.implicitHeight + 16
                        radius: Appearance.radiusSmall
                        color: Colors.withAlpha(Colors.background, 0.4)
                        Text {
                            id: cmdLabel
                            anchors.centerIn: parent
                            text: AiService.pendingCommand ? AiService.pendingCommand.label : ""
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeMedium
                            font.weight: Font.Bold
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Appearance.spacingM

                        SettingsActionButton {
                            label: "Cancel"
                            iconName: "󰅖"
                            compact: true
                            enabled: !AiService.isCommandRunning
                            onClicked: AiService.cancelPendingCommand()
                        }

                        SettingsActionButton {
                            label: AiService.isCommandRunning ? "Running..." : "Execute"
                            iconName: AiService.isCommandRunning ? "󰦖" : "󰐊"
                            compact: true
                            enabled: !AiService.isCommandRunning
                            onClicked: AiService.executePendingCommand()
                        }
                    }
                }
            }

            // ---- Script Confirmation ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: scriptCol.implicitHeight + Appearance.paddingLarge
                radius: Appearance.radiusMedium
                color: Colors.withAlpha(Colors.success, 0.12)
                border.color: Colors.success
                border.width: 1
                visible: AiService.pendingScript !== null
                clip: true

                opacity: visible ? 1.0 : 0.0
                scale: visible ? 1.0 : 0.95
                Behavior on opacity {
                    Anim {}
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.durationSlow
                        easing.type: Easing.OutBack
                    }
                }

                ColumnLayout {
                    id: scriptCol
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingM
                    spacing: Appearance.spacingS

                    RowLayout {
                        spacing: Appearance.spacingS
                        SharedWidgets.SvgIcon {
                            source: "terminal.svg"
                            color: Colors.success
                            size: Appearance.fontSizeXL
                        }
                        Text {
                            text: "Install Shell Script"
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Appearance.radiusSmall
                        color: Colors.withAlpha(Colors.background, 0.4)
                        Text {
                            anchors.centerIn: parent
                            text: "filename: " + (AiService.pendingScript ? AiService.pendingScript.name : "")
                            color: Colors.success
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.Bold
                            font.family: Appearance.fontMono
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.min(200, scriptPreview.implicitHeight + 16)
                        radius: Appearance.radiusSmall
                        color: Colors.withAlpha(Colors.background, 0.6)
                        border.color: Colors.withAlpha(Colors.success, 0.2)
                        border.width: 1
                        clip: true

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 8
                            contentHeight: scriptPreview.implicitHeight
                            contentWidth: width
                            flickableDirection: Flickable.VerticalFlick
                            Text {
                                id: scriptPreview
                                width: parent.width
                                text: AiService.pendingScript ? AiService.pendingScript.content : ""
                                color: Colors.textSecondary
                                font.family: Appearance.fontMono
                                font.pixelSize: Appearance.fontSizeXS
                                wrapMode: Text.WrapAnywhere
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Appearance.spacingM

                        SettingsActionButton {
                            label: "Discard"
                            iconName: "󰅖"
                            compact: true
                            onClicked: AiService.cancelPendingScript()
                        }

                        SettingsActionButton {
                            label: "Install to ~/.local/bin"
                            iconName: "󰄬"
                            compact: true
                            onClicked: AiService.installPendingScript()
                        }
                    }
                }
            }

            // ---- Privacy warning for remote providers ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: privacyRow.implicitHeight + Appearance.spacingS * 2
                radius: Appearance.radiusXS
                color: Colors.withAlpha(Colors.warning, 0.08)
                border.color: Colors.withAlpha(Colors.warning, 0.25)
                border.width: 1
                visible: !root._privacyDismissed && !Profiles.isLocalProvider(Config.aiProvider, Profiles.loadProfile(Config.aiProviderProfiles, Config.aiProvider).endpoint || Config.aiCustomEndpoint)

                RowLayout {
                    id: privacyRow
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS
                    spacing: Appearance.spacingS

                    SharedWidgets.SvgIcon {
                        source: "warning.svg"
                        color: Colors.warning
                        size: Appearance.fontSizeMedium
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Remote provider — avoid sharing sensitive data"
                        color: Colors.withAlpha(Colors.warning, 0.85)
                        font.pixelSize: Appearance.fontSizeXS
                        wrapMode: Text.WordWrap
                    }
                    SharedWidgets.SvgIcon {
                        source: "dismiss.svg"
                        color: Colors.textDisabled
                        size: Appearance.fontSizeSmall
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._privacyDismissed = true
                        }
                    }
                }
            }

            // ---- Message list ----
            AiMessageList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                renderBlocksFn: root._renderBlocks
                renderMarkdownFn: root._renderMarkdown
                onQuickStartSelected: text => {
                    inputField.text = text;
                    inputField.forceActiveFocus();
                    inputField.cursorPosition = inputField.text.length;
                }
            }

            // ---- Input area ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: inputLayout.implicitHeight + Appearance.spacingM * 2
                color: Colors.cardSurface
                border.color: inputField.activeFocus ? Colors.primary : Colors.border
                border.width: inputField.activeFocus ? 1.5 : 1
                radius: Appearance.radiusMedium
                clip: true
                Behavior on border.color {
                    enabled: !Colors.isTransitioning
                    CAnim {}
                }

                ColumnLayout {
                    id: inputLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingM
                    spacing: Appearance.spacingXS

                    Flickable {
                        id: inputFlickable
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(24 + Appearance.spacingS * 2, Math.min(120 + Appearance.spacingS * 2, inputField.contentHeight + Appearance.spacingS * 2))
                        Layout.maximumHeight: 120 + Appearance.spacingS * 2
                        contentWidth: width
                        contentHeight: Math.max(height, inputField.contentHeight + Appearance.spacingS * 2)
                        flickableDirection: Flickable.VerticalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true
                        interactive: contentHeight > height

                        ScrollBar.vertical: ScrollBar {
                            policy: inputFlickable.contentHeight > inputFlickable.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                        }

                        TextEdit {
                            id: inputField
                            width: inputFlickable.width - (inputFlickable.contentHeight > inputFlickable.height ? 12 : 0)
                            topPadding: Appearance.spacingS
                            bottomPadding: Appearance.spacingS
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeMedium
                            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                            selectByMouse: true
                            selectedTextColor: Colors.background
                            selectionColor: Colors.primary

                            // Placeholder
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 1
                                anchors.top: parent.top
                                anchors.topMargin: Appearance.spacingS
                                text: "Type a message..."
                                color: Colors.textDisabled
                                font.pixelSize: Appearance.fontSizeMedium
                                visible: inputField.text.length === 0 && !inputField.activeFocus
                            }

                            onActiveFocusChanged: if (activeFocus)
                                providerDropdown.visible = false

                            onTextChanged: {
                                if (text !== AiService.activeDraftText)
                                    AiService.setActiveDraftText(text);
                            }

                            onCursorRectangleChanged: {
                                var cursorBottom = cursorRectangle.y + cursorRectangle.height;
                                var cursorTop = cursorRectangle.y;
                                if (cursorBottom > inputFlickable.contentY + inputFlickable.height) {
                                    inputFlickable.contentY = cursorBottom - inputFlickable.height + Appearance.spacingS;
                                } else if (cursorTop < inputFlickable.contentY) {
                                    inputFlickable.contentY = Math.max(0, cursorTop - Appearance.spacingS);
                                }
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                    event.accepted = true;
                                    root._sendCurrentMessage();
                                }
                            }
                        }
                    }

                    // Attached files flow
                    Flow {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingS
                        visible: root.attachedFiles.length > 0

                        Repeater {
                            model: root.attachedFiles
                            delegate: Rectangle {
                                width: fileText.width + removeButton.width + Appearance.spacingM
                                height: 24
                                color: Colors.highlightLight
                                radius: Appearance.radiusSmall
                                border.color: Colors.primaryRing
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Appearance.spacingS
                                    anchors.rightMargin: Appearance.spacingXS
                                    spacing: Appearance.spacingXS

                                    Text {
                                        id: fileText
                                        text: modelData.name
                                        color: Colors.text
                                        font.pixelSize: Appearance.fontSizeSmall
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 150
                                    }

                                    SharedWidgets.IconButton {
                                        id: removeButton
                                        icon: "window-close-symbolic"
                                        size: 16
                                        iconSize: 10
                                        color: "transparent"
                                        tooltipText: "Remove attachment"
                                        onClicked: {
                                            root.attachedFiles = root.attachedFiles.filter((_, i) => i !== index);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingS

                        // Window context toggle
                        Rectangle {
                            id: windowContextToggle
                            width: 24
                            height: 24
                            radius: Appearance.radiusXXS
                            color: root.includeWindowContext ? Colors.primaryMid : "transparent"
                            border.color: root.includeWindowContext ? Colors.primary : Colors.border
                            border.width: 1

                            SharedWidgets.SvgIcon {
                                anchors.centerIn: parent
                                source: "app-generic.svg"
                                color: root.includeWindowContext ? Colors.primary : Colors.textDisabled
                                size: Appearance.fontSizeSmall
                            }
                            MouseArea {
                                id: winCtxHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.includeWindowContext = !root.includeWindowContext
                            }

                            Tooltip {
                                text: "Attach Active Window Title"
                                shown: winCtxHover.containsMouse
                                preferredSide: Qt.TopEdge
                            }
                        }

                        // Visual context toggle
                        Rectangle {
                            id: visualContextToggle
                            width: 24
                            height: 24
                            radius: Appearance.radiusXXS
                            color: root.includeVisualContext ? Colors.primaryMid : "transparent"
                            border.color: root.includeVisualContext ? Colors.primary : Colors.border
                            border.width: 1

                            SharedWidgets.SvgIcon {
                                anchors.centerIn: parent
                                source: "camera.svg"
                                color: root.includeVisualContext ? Colors.primary : Colors.textDisabled
                                size: Appearance.fontSizeSmall
                            }
                            MouseArea {
                                id: visualCtxHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (ScreenshotService.lastRegionPath === "") {
                                        ScreenshotService.captureRegion();
                                    } else {
                                        root.includeVisualContext = !root.includeVisualContext;
                                    }
                                }
                                onDoubleClicked: ScreenshotService.captureRegion()
                            }

                            Tooltip {
                                text: "Attach Latest Screen Crop (Double-click to capture new)"
                                shown: visualCtxHover.containsMouse
                                preferredSide: Qt.TopEdge
                            }

                            Connections {
                                target: ScreenshotService
                                function onRegionCaptured(path) {
                                    root.includeVisualContext = true;
                                    // Only OCR if the model doesn't support vision directly
                                    if (!Providers.supportsVision(AiService.activeProvider, AiService.activeModel)) {
                                        AiService.performOcr(path);
                                    }
                                }
                            }
                        }

                        // Selection context toggle
                        Rectangle {
                            id: selectionContextToggle
                            width: 24
                            height: 24
                            radius: Appearance.radiusXXS
                            color: root.includeSelectionContext ? Colors.primaryMid : "transparent"
                            border.color: root.includeSelectionContext ? Colors.primary : Colors.border
                            border.width: 1

                            SharedWidgets.SvgIcon {
                                anchors.centerIn: parent
                                source: "select-all.svg"
                                color: root.includeSelectionContext ? Colors.primary : Colors.textDisabled
                                size: Appearance.fontSizeSmall
                            }
                            MouseArea {
                                id: selCtxHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.includeSelectionContext = !root.includeSelectionContext
                            }

                            Tooltip {
                                text: "Attach Current Selection (Middle-click/Primary)"
                                shown: selCtxHover.containsMouse
                                preferredSide: Qt.TopEdge
                            }
                        }

                        // OCR from screen
                        Rectangle {
                            id: ocrToggle
                            width: 24
                            height: 24
                            radius: Appearance.radiusXXS
                            color: AiService.isOcrBusy ? Colors.withAlpha(Colors.warning, 0.18) : "transparent"
                            border.color: AiService.isOcrBusy ? Colors.warning : Colors.border
                            border.width: 1

                            SharedWidgets.SvgIcon {
                                anchors.centerIn: parent
                                source: "scan-text.svg"
                                color: AiService.isOcrBusy ? Colors.warning : Colors.textDisabled
                                size: Appearance.fontSizeSmall
                            }
                            MouseArea {
                                id: ocrHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ScreenshotService.captureRegion()
                            }

                            Tooltip {
                                text: "Extract Text from Screen (OCR)"
                                shown: ocrHover.containsMouse
                                preferredSide: Qt.TopEdge
                            }

                            Connections {
                                target: AiService
                                function onLastOcrTextChanged() {
                                    if (AiService.lastOcrText.length > 0) {
                                        var prefix = inputField.text.length > 0 ? "\n\n" : "";
                                        inputField.insert(inputField.cursorPosition, prefix + "```\n" + AiService.lastOcrText + "\n```\n");
                                        ToastService.showNotice("OCR Complete", "Text inserted from screen");
                                    }
                                }
                            }
                        }

                        // System context toggle
                        Rectangle {
                            id: systemContextToggle
                            width: 24
                            height: 24
                            radius: Appearance.radiusXXS
                            color: Config.aiSystemContext ? Colors.primaryMid : "transparent"
                            border.color: Config.aiSystemContext ? Colors.primary : Colors.border
                            border.width: 1

                            SharedWidgets.SvgIcon {
                                anchors.centerIn: parent
                                source: "board.svg"
                                color: Config.aiSystemContext ? Colors.primary : Colors.textDisabled
                                size: Appearance.fontSizeSmall
                            }
                            MouseArea {
                                id: sysCtxHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.aiSystemContext = !Config.aiSystemContext
                            }

                            Tooltip {
                                text: "Attach System Stats (CPU/RAM)"
                                shown: sysCtxHover.containsMouse
                                preferredSide: Qt.TopEdge
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
                            font.pixelSize: Appearance.fontSizeXS
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // Send / Cancel button
                        Rectangle {
                            width: 32
                            height: 28
                            radius: Appearance.radiusXS
                            color: AiService.isStreaming ? Colors.withAlpha(Colors.error, 0.18) : (inputField.text.trim().length > 0 ? Colors.primaryMid : "transparent")
                            border.color: AiService.isStreaming ? Colors.error : Colors.primary
                            border.width: AiService.isStreaming || inputField.text.trim().length > 0 ? 1 : 0

                            SharedWidgets.SvgIcon {
                                anchors.centerIn: parent
                                source: AiService.isStreaming ? "stop.svg" : "send.svg"
                                color: AiService.isStreaming ? Colors.error : Colors.primary
                                size: Appearance.fontSizeLarge
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
                                onClicked: mouse => {
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
                spacing: Appearance.spacingS
                visible: !root.narrowFooter

                Text {
                    visible: !root.compactFooter
                    text: Providers.providerLabel(AiService.activeProvider)
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                }

                Text {
                    visible: !root.compactFooter
                    text: "·"
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                }

                Text {
                    text: AiService.activeModel
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }

                Text {
                    text: AiService.conversations.length + " chat" + (AiService.conversations.length !== 1 ? "s" : "")
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    visible: !root.compactFooter
                }
            }
        }

        // ── Provider/model dropdown ────────────────────
        AiProviderDropdown {
            id: providerDropdown
            anchors.right: parent.right
            anchors.rightMargin: Appearance.paddingLarge
            y: 60
        }

        // ── Slash command hints popup ─────────────────
        Rectangle {
            id: slashHints
            visible: inputField.text.indexOf("/") === 0 && inputField.text.indexOf(" ") === -1 && inputField.activeFocus && !AiService.isStreaming
            width: parent.width - Appearance.paddingLarge * 2
            height: slashHintsCol.implicitHeight + Appearance.spacingS * 2
            x: Appearance.paddingLarge
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 120 + Appearance.paddingLarge
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            radius: Appearance.radiusMedium
            z: 10

            Column {
                id: slashHintsCol
                anchors.fill: parent
                anchors.margins: Appearance.spacingS
                spacing: Appearance.spacingXXS

                Repeater {
                    model: ScriptModel {
                        values: {
                            var typed = inputField.text.toLowerCase();
                            var cmds = AiService.slashCommands;
                            var filtered = [];
                            for (var i = 0; i < cmds.length; i++) {
                                if (typed.length <= 1 || cmds[i].cmd.indexOf(typed) === 0)
                                    filtered.push(cmds[i]);
                            }
                            return filtered;
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: slashHintsCol.width - Appearance.spacingS * 2
                        height: 28
                        radius: Appearance.radiusXXS
                        color: slashItemMouse.containsMouse ? Colors.primaryGhost : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacingS
                            anchors.rightMargin: Appearance.spacingS
                            spacing: Appearance.spacingS

                            Text {
                                text: modelData.cmd
                                color: Colors.primary
                                font.pixelSize: Appearance.fontSizeSmall
                                font.family: Appearance.fontMono
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: modelData.desc
                                color: Colors.textDisabled
                                font.pixelSize: Appearance.fontSizeSmall
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

    // ── Helpers ──────────────────────────────────
    Process {
        id: fileReadProc
        command: ["cat", root.attachedFiles[root._fileReadIndex] ? root.attachedFiles[root._fileReadIndex].path : ""]
        onExited: exitCode => {
            if (exitCode === 0) {
                var files = root.attachedFiles.slice();
                files[root._fileReadIndex].content = stdout.readAll();
                root.attachedFiles = files;
            }
            root._fileReadIndex++;
            root._readNextAttachedFile();
        }
    }

    function _readNextAttachedFile() {
        if (root._fileReadIndex < root.attachedFiles.length) {
            fileReadProc.running = true;
        } else {
            // Finished reading all files, now handle selection if needed
            if (root.includeSelectionContext) {
                AiService.fetchSelection();
                // We wait for AiService.onLastSelectionTextChanged via Connections
            } else {
                root._finishAndSendMessage();
            }
        }
    }

    function _finishAndSendMessage() {
        var contextString = "";
        for (var i = 0; i < root.attachedFiles.length; i++) {
            contextString += "\n\nFile: " + root.attachedFiles[i].name + "\nContent:\n" + root.attachedFiles[i].content;
        }
        
        if (root.includeSelectionContext && AiService.lastSelectionText) {
            contextString += "\n\nCurrent Selection:\n```\n" + AiService.lastSelectionText + "\n```";
        }

        var text = root._pendingMsgText + contextString;
        var winCtx = root.includeWindowContext ? AiService.contextWindowTitle : "";
        var visualCtx = root.includeVisualContext ? ScreenshotService.lastRegionPath : "";
        AiService.sendMessage(text, winCtx, visualCtx);
        
        // Reset state
        root.attachedFiles = [];
        root._pendingMsgText = "";
        root.includeWindowContext = false;
        root.includeVisualContext = false;
        root.includeSelectionContext = false;
    }

    Connections {
        target: AiService
        function onLastSelectionTextChanged() {
            if (root.includeSelectionContext && root._pendingMsgText !== "") {
                root._finishAndSendMessage();
            }
        }
        function onActiveConversationIdChanged() {
            root._syncInputFromService();
        }
        function onConversationsChanged() {
            root._syncInputFromService();
        }
    }

    function _sendCurrentMessage() {
        var text = inputField.text.trim();
        if (text.length === 0 && root.attachedFiles.length === 0 && !root.includeSelectionContext)
            return;
        if (AiService.isStreaming)
            return;
        
        inputField.text = "";
        root._pendingMsgText = text;

        if (root.attachedFiles.length > 0) {
            root._fileReadIndex = 0;
            root._readNextAttachedFile();
        } else if (root.includeSelectionContext) {
            AiService.fetchSelection();
            // Wait for signal
        } else {
            root._finishAndSendMessage();
        }
    }

}
