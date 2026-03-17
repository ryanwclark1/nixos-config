import QtQuick
import QtQuick.Layouts
import "../../services"
import ".."

ColumnLayout {
    id: root
    required property var lockContext
    required property bool timerActive
    required property string pendingAction
    required property int timeRemaining
    required property bool compact

    signal cancelRequested()
    signal unlockRequested()

    spacing: Colors.spacingL

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
        PropertyAnimation { target: root; property: "shakeOffset"; to: 10; duration: 50 }
        PropertyAnimation { target: root; property: "shakeOffset"; to: -10; duration: 50 }
        PropertyAnimation { target: root; property: "shakeOffset"; to: 0; duration: 50 }
    }

    // Password input
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        color: Colors.highlightLight
        radius: Colors.radiusCard
        border.color: pwInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.paddingSmall

            Text {
                text: "󰌾"
                color: Colors.textDisabled
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
            }

            TextInput {
                id: pwInput
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                color: Colors.text
                font.pixelSize: Colors.fontSizeXL
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
                width: 28; height: 28; radius: Colors.radiusMedium
                color: Colors.withAlpha(Colors.primary, 0.6)
                visible: pwInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "󰁔"
                    color: Colors.background
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
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
            font.pixelSize: Colors.fontSizeLarge
            visible: !pwInput.text && !pwInput.activeFocus
        }
    }

    // Error message
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.lockContext ? root.lockContext.errorMessage : ""
        color: Colors.error
        font.pixelSize: Colors.fontSizeSmall
        font.weight: Font.Medium
        visible: root.lockContext ? root.lockContext.showError : false
    }

    // Unlock in progress indicator
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Authenticating..."
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeSmall
        visible: root.lockContext ? root.lockContext.unlockInProgress : false
    }

    // Countdown display
    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        visible: root.timerActive
        width: countdownRow.implicitWidth + 24
        height: 36
        radius: 18
        color: Colors.withAlpha(Colors.error, 0.15)
        border.color: Colors.error
        border.width: 1

        RowLayout {
            id: countdownRow
            anchors.centerIn: parent
            spacing: Colors.spacingS

            Text {
                text: root.pendingAction.charAt(0).toUpperCase() + root.pendingAction.slice(1) + " in " + Math.ceil(root.timeRemaining / 1000) + "s"
                color: Colors.error
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.Medium
            }

            Rectangle {
                width: 20; height: 20; radius: Colors.radiusSmall
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
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXS
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
