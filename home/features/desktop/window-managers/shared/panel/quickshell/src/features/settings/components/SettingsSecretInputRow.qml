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
    property bool secretVisible: false
    property alias text: input.text
    property alias inputActiveFocus: input.activeFocus

    signal textEdited(string value)
    signal submitted(string value)

    default property alias actions: actionsRow.data

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
            Layout.fillWidth: true
            height: Colors.controlRowHeight
            radius: Colors.radiusSmall
            color: Colors.modalFieldSurface
            border.color: input.activeFocus ? Colors.primary : Colors.border
            border.width: 1

            Behavior on border.color {
                enabled: !Colors.isTransitioning
                CAnim {}
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                spacing: Colors.spacingS

                Loader {
                    visible: root.leadingIcon !== ""
                    sourceComponent: root.leadingIcon.endsWith(".svg") ? _siSvg : _siNerd
                }
                Component { id: _siSvg; SvgIcon { source: root.leadingIcon; color: Colors.textDisabled; size: Colors.fontSizeLarge } }
                Component { id: _siNerd; Text { text: root.leadingIcon; color: Colors.textDisabled; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge } }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    clip: true
                    selectByMouse: true
                    selectedTextColor: Colors.text
                    selectionColor: Colors.withAlpha(Colors.primary, 0.45)
                    echoMode: root.secretVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
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
                    text: root.secretVisible ? "󰈈" : "󰈉"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.secretVisible = !root.secretVisible
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
