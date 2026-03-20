import QtQuick
import QtQuick.Layouts
import "../../../shared"
import "../../../services"

ColumnLayout {
    id: root

    property string label: ""
    property string placeholderText: ""
    property string leadingIcon: ""
    property string errorText: ""
    property bool showClearButton: true
    property bool highlighted: false
    property alias text: input.text
    property alias inputActiveFocus: input.activeFocus

    signal textEdited(string value)
    signal submitted(string value)

    default property alias actions: actionsRow.data
    readonly property bool narrowLayout: width < 480

    spacing: Colors.spacingS
    Layout.fillWidth: true

    Text {
        visible: root.label !== ""
        text: root.label
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        font.weight: Font.Medium
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingS

        Rectangle {
            id: inputContainer
            Layout.fillWidth: true
            height: 38
            radius: Colors.radiusSmall
            color: Colors.modalFieldSurface
            border.color: root.highlighted ? Colors.primary : input.activeFocus ? Colors.primary : Colors.border
            border.width: 1

            Behavior on border.color {
                enabled: !Colors.isTransitioning
                CAnim {}
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Colors.primary
                opacity: textHighlightPulse.running ? textHighlightPulse._opacity : 0
                visible: root.highlighted

                SequentialAnimation {
                    id: textHighlightPulse
                    property real _opacity: 0
                    running: root.highlighted
                    loops: 2
                    NumberAnimation { target: textHighlightPulse; property: "_opacity"; from: 0; to: 0.2; duration: Colors.durationSlow; easing.type: Easing.OutCubic }
                    NumberAnimation { target: textHighlightPulse; property: "_opacity"; from: 0.2; to: 0; duration: Colors.durationSlow; easing.type: Easing.InCubic }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                spacing: Colors.spacingS

                Loader {
                    visible: root.leadingIcon !== ""
                    sourceComponent: root.leadingIcon.endsWith(".svg") ? _tiSvg : _tiNerd
                }
                Component { id: _tiSvg; SvgIcon { source: root.leadingIcon; color: Colors.textDisabled; size: Colors.fontSizeLarge } }
                Component { id: _tiNerd; Text { text: root.leadingIcon; color: Colors.textDisabled; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge } }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    clip: true
                    selectByMouse: true
                    selectedTextColor: Colors.text
                    selectionColor: Colors.withAlpha(Colors.primary, 0.45)
                    onVisibleChanged: {
                        if (!visible && activeFocus)
                            focus = false;
                    }
                    onTextChanged: root.textEdited(text)
                    onAccepted: root.submitted(text)

                    Text {
                        text: root.placeholderText
                        color: Colors.textDisabled
                        font.pixelSize: parent.font.pixelSize
                        visible: parent.text.length === 0 && !parent.activeFocus
                    }
                }

                Text {
                    visible: root.showClearButton && input.text.length > 0
                    text: "󰅖"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: input.text = ""
                    }
                }
            }
        }

        Flow {
            id: actionsRow
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS
        }
    }

    Text {
        visible: root.errorText !== ""
        text: root.errorText
        color: Colors.error
        font.pixelSize: Colors.fontSizeXS
    }
}
