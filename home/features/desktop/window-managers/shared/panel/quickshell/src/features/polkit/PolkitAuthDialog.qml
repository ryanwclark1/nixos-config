import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../widgets" as SharedWidgets
import "../../shared"

PanelWindow {
    id: root

    property var screenRef: screen || Quickshell.cursorScreen || Config.primaryScreen()
    screen: screenRef

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // Auth request state (set by PolkitAgent)
    property string cookie: ""
    property string actionId: ""
    property string authMessage: ""
    property string iconName: ""
    property var identities: []
    property var details: ({})
    property bool isVisible: false

    visible: root.isVisible || fadeAnim.running || _polkitElasticScale.running

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:polkit"

    signal authResult(string cookie, bool authenticated)

    // PAM context
    PolkitPamContext {
        id: pamContext

        onAuthenticated: {
            root.authResult(root.cookie, true);
            root._dismiss();
        }

        onFailed: {
            if (pamContext.attemptsExhausted) {
                // Auto-cancel after max attempts
                root._cancel();
            } else {
                prompt.shake();
                prompt.clearInput();
                prompt.forceActiveFocus();
            }
        }
    }

    // 120s auto-cancel timeout
    Timer {
        id: timeoutTimer
        interval: 120000
        running: root.isVisible
        onTriggered: root._cancel()
    }

    function _cancel() {
        authResult(cookie, false);
        _dismiss();
    }

    function _dismiss() {
        pamContext.reset();
        prompt.clearInput();
        isVisible = false;
    }

    onIsVisibleChanged: {
        if (isVisible) {
            prompt.forceActiveFocus();
        }
    }

    // Readable description from details dict if available
    readonly property string _actionDescription: {
        var d = root.details || {};
        return d["polkit.gettext_domain"] ? "" : (d["polkit.message"] || "");
    }

    Item {
        anchors.fill: parent
        visible: root.isVisible
        focus: root.isVisible

        Keys.onEscapePressed: root._cancel()

        // Backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: root._cancel()

            Rectangle {
                anchors.fill: parent
                color: Colors.background
                opacity: root.isVisible ? 0.85 : 0.0
                Behavior on opacity { NumberAnimation { duration: Appearance.durationSlow; easing.type: Easing.OutCubic } }
            }
        }

        SharedWidgets.ElasticNumber {
            id: _polkitElasticScale
            target: root.isVisible ? 1.0 : 0.92
            fastDuration: Appearance.durationFast
            slowDuration: Appearance.durationEmphasis
            fastWeight: 0.4
        }

        // Dialog card
        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 420
            implicitHeight: cardContent.implicitHeight + 2 * Appearance.paddingLarge
            radius: Appearance.radiusLarge
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            scale: _polkitElasticScale.value
            opacity: root.isVisible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { id: fadeAnim; duration: Appearance.durationEmphasis; easing.type: Easing.OutCubic } }
            layer.enabled: _polkitElasticScale.running || fadeAnim.running

            SharedWidgets.InnerHighlight { highlightOpacity: 0.12 }

            ColumnLayout {
                id: cardContent
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Appearance.paddingLarge
                }
                spacing: Appearance.spacingL

                // Shield icon
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "\u{f0552}"
                    color: Colors.primary
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeGigantic
                }

                // Title
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Authentication Required"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeHuge
                    font.weight: Font.Bold
                    font.letterSpacing: Appearance.letterSpacingTight
                }

                // Auth message
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: root.authMessage || "An application is requesting elevated privileges."
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeMedium
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                // Action ID (monospace, faint)
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    text: root.actionId
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    font.family: Appearance.fontMono
                    wrapMode: Text.WrapAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    visible: root.actionId !== ""
                }

                // Identity display
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Appearance.spacingS
                    visible: root.identities.length > 0

                    Text {
                        text: "\u{f0004}"
                        color: Colors.textSecondary
                        font.family: Appearance.fontMono
                        font.pixelSize: Appearance.fontSizeMedium
                    }

                    Text {
                        text: {
                            var parts = [];
                            for (var i = 0; i < root.identities.length; i++) {
                                var id = root.identities[i];
                                var colonIdx = id.indexOf(":");
                                parts.push(colonIdx >= 0 ? id.substring(colonIdx + 1) : id);
                            }
                            return parts.join(", ");
                        }
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeMedium
                        font.weight: Font.Medium
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.border
                }

                // Password prompt
                PolkitAuthPrompt {
                    id: prompt
                    Layout.fillWidth: true
                    pamContext: pamContext

                    onSubmitRequested: {
                        if (pamContext.currentText.length > 0 && !pamContext.attemptsExhausted) {
                            pamContext.tryAuth();
                        }
                    }
                }

                // Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingM

                    // Cancel button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Appearance.radiusSmall
                        color: Colors.highlightLight
                        border.color: Colors.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        SharedWidgets.StateLayer {
                            id: cancelState
                            hovered: cancelMa.containsMouse
                            pressed: cancelMa.pressed
                        }

                        MouseArea {
                            id: cancelMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._cancel()
                        }
                    }

                    // Authenticate button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Appearance.radiusSmall
                        color: pamContext.attemptsExhausted
                            ? Colors.highlightLight
                            : Colors.withAlpha(Colors.primary, 0.15)
                        border.color: pamContext.attemptsExhausted
                            ? Colors.border
                            : Colors.withAlpha(Colors.primary, 0.3)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Authenticate"
                            color: pamContext.attemptsExhausted ? Colors.textDisabled : Colors.primary
                            font.pixelSize: Appearance.fontSizeMedium
                            font.weight: Font.Bold
                        }

                        SharedWidgets.StateLayer {
                            id: authState
                            hovered: authMa.containsMouse
                            pressed: authMa.pressed
                            stateColor: Colors.primary
                        }

                        MouseArea {
                            id: authMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: pamContext.attemptsExhausted ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (pamContext.currentText.length > 0 && !pamContext.attemptsExhausted)
                                    pamContext.tryAuth();
                            }
                        }
                    }
                }
            }
        }
    }
}
