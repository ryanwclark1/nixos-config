import QtQuick
import QtQuick.Layouts
import "../../services"

ColumnLayout {
    id: root

    property string label: ""
    property string placeholderText: ""
    property string leadingIcon: ""
    property string errorText: ""
    property bool showClearButton: true
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
            Layout.fillWidth: true
            height: 38
            radius: Colors.radiusSmall
            color: Colors.withAlpha(Colors.surface, 0.7)
            border.color: input.activeFocus ? Colors.primary : Colors.border
            border.width: 1

            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                spacing: Colors.spacingS

                Text {
                    visible: root.leadingIcon !== ""
                    text: root.leadingIcon
                    color: Colors.fgDim
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    clip: true
                    selectByMouse: true
                    selectedTextColor: Colors.text
                    selectionColor: Colors.withAlpha(Colors.primary, 0.45)
                    onTextChanged: root.textEdited(text)
                    onAccepted: root.submitted(text)

                    Text {
                        text: root.placeholderText
                        color: Colors.fgDim
                        font.pixelSize: parent.font.pixelSize
                        visible: parent.text.length === 0 && !parent.activeFocus
                    }
                }

                Text {
                    visible: root.showClearButton && input.text.length > 0
                    text: "󰅖"
                    color: Colors.fgDim
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
