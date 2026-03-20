import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets"

ColumnLayout {
    id: root
    required property var lockContext
    required property bool timerActive
    required property string pendingAction
    required property int timeRemaining
    required property bool compact

    signal cancelRequested()
    signal unlockRequested()

    spacing: Appearance.spacingL

    property real shakeOffset: 0
    transform: Translate { x: root.shakeOffset }

    function forceActiveFocus() {
        pwInput.forceActiveFocus();
    }

    function clearInput() {
        pwInput.text = "";
    }

    function shake() {
        shakeAnim.start();
    }

    SequentialAnimation {
        id: shakeAnim
        PropertyAnimation { target: root; property: "shakeOffset"; to: 10; duration: Appearance.durationShake }
        PropertyAnimation { target: root; property: "shakeOffset"; to: -10; duration: Appearance.durationShake }
        PropertyAnimation { target: root; property: "shakeOffset"; to: 0; duration: Appearance.durationShake }
    }

    // Fingerprint status
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Appearance.spacingXS
        visible: root.lockContext && root.lockContext.fprintAvailable && Config.lockScreenFingerprint

        Text {
            id: fprintIcon
            Layout.alignment: Qt.AlignHCenter
            text: "󰈷"
            color: {
                if (!root.lockContext) return Colors.textDisabled;
                switch (root.lockContext.fprintStatus) {
                case "scanning": return Colors.primary;
                case "error":
                case "max_tries": return Colors.error;
                default: return Colors.textDisabled;
                }
            }
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeDisplay

            SequentialAnimation on opacity {
                id: fprintPulse
                running: root.lockContext && root.lockContext.fprintStatus === "scanning"
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: Appearance.durationPulse }
                NumberAnimation { to: 1.0; duration: Appearance.durationPulse }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                if (!root.lockContext) return "";
                switch (root.lockContext.fprintStatus) {
                case "scanning": return "Touch sensor to unlock";
                case "error": return "Try again or use password";
                case "max_tries": return "Use password";
                default: return "";
                }
            }
            color: root.lockContext && root.lockContext.fprintStatus === "scanning"
                ? Colors.textSecondary : Colors.error
            font.pixelSize: Appearance.fontSizeSmall
            visible: text !== ""
        }
    }

    // Password input
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        color: Colors.highlightLight
        radius: Appearance.radiusCard
        border.color: pwInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacingM
            spacing: Appearance.paddingSmall

            Text {
                text: "󰌾"
                color: Colors.textDisabled
                font.family: Appearance.fontMono
                font.pixelSize: Appearance.fontSizeXL
            }

            TextInput {
                id: pwInput
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                color: Colors.text
                font.pixelSize: Appearance.fontSizeXL
                echoMode: TextInput.Password
                focus: true

                onTextChanged: {
                    if (root.lockContext) root.lockContext.currentText = text;
                }

                Keys.onReturnPressed: {
                    if (root.lockContext) root.lockContext.tryUnlock();
                }
                Keys.onEscapePressed: {
                    if (root.timerActive) {
                        root.cancelRequested();
                    } else {
                        text = "";
                    }
                }
            }

            // Submit button
            Rectangle {
                width: 28; height: 28; radius: Appearance.radiusMedium
                color: Colors.withAlpha(Colors.primary, 0.6)
                visible: pwInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "󰁔"
                    color: Colors.background
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeMedium
                }

                StateLayer {
                    id: submitStateLayer
                    hovered: submitMa.containsMouse
                    pressed: submitMa.pressed
                    stateColor: Colors.primary
                }

                MouseArea {
                    id: submitMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        submitStateLayer.burst(mouse.x, mouse.y);
                        if (root.lockContext) root.lockContext.tryUnlock();
                    }
                }
            }
        }

        // Placeholder
        Text {
            anchors.centerIn: parent
            text: "Unlock..."
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeLarge
            visible: !pwInput.text && !pwInput.activeFocus
        }
    }

    // Error message
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.lockContext ? root.lockContext.errorMessage : ""
        color: Colors.error
        font.pixelSize: Appearance.fontSizeSmall
        font.weight: Font.Medium
        visible: root.lockContext ? root.lockContext.showError : false
    }

    // Unlock in progress indicator
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Authenticating..."
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeSmall
        visible: root.lockContext ? root.lockContext.unlockInProgress : false
    }

    // Countdown display
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        visible: root.timerActive
        width: countdownRow.implicitWidth + 24
        height: 36
        radius: Appearance.radiusPill
        color: Colors.errorLight
        border.color: Colors.error
        border.width: 1

        RowLayout {
            id: countdownRow
            anchors.centerIn: parent
            spacing: Appearance.spacingS

            Text {
                text: root.pendingAction.charAt(0).toUpperCase() + root.pendingAction.slice(1) + " in " + Math.ceil(root.timeRemaining / 1000) + "s"
                color: Colors.error
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.Medium
            }

            Rectangle {
                width: 20; height: 20; radius: Appearance.radiusSmall
                color: "transparent"
                border.color: Colors.error; border.width: 1

                StateLayer {
                    id: cancelStateLayer
                    hovered: cancelMa.containsMouse
                    pressed: cancelMa.pressed
                    stateColor: Colors.error
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: Colors.error
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeXS
                }

                MouseArea {
                    id: cancelMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        cancelStateLayer.burst(mouse.x, mouse.y);
                        root.cancelRequested();
                    }
                }
            }
        }
    }
}
