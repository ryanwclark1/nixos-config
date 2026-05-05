import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets"

ColumnLayout {
    id: root

    required property PolkitPamContext pamContext
    signal submitRequested()

    spacing: Appearance.spacingM

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
                text: "\u{f0341}"
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
                    if (root.pamContext) root.pamContext.currentText = text;
                }

                Keys.onReturnPressed: root.submitRequested()
            }

            // Submit button
            Rectangle {
                width: 28; height: 28; radius: Appearance.radiusMedium
                color: Colors.withAlpha(Colors.primary, 0.6)
                visible: pwInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "\u{f0054}"
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
                        root.submitRequested();
                    }
                }
            }
        }

        // Placeholder
        Text {
            anchors.centerIn: parent
            text: "Password..."
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeLarge
            visible: !pwInput.text && !pwInput.activeFocus
        }
    }

    // Error message
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.pamContext ? root.pamContext.errorMessage : ""
        color: Colors.error
        font.pixelSize: Appearance.fontSizeSmall
        font.weight: Font.Medium
        visible: root.pamContext ? root.pamContext.showError : false
    }

    // Auth in progress indicator
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Authenticating..."
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeSmall
        visible: root.pamContext ? root.pamContext.authInProgress : false
    }
}
