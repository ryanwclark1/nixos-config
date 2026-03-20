import QtQuick
import QtQuick.Layouts
import "../../../shared"
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../widgets" as SharedWidgets

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

    spacing: Appearance.spacingS
    Layout.fillWidth: true

    Text {
        visible: root.label !== ""
        text: root.label
        color: Colors.text
        font.pixelSize: Appearance.fontSizeMedium
        font.weight: Font.Medium
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingS

        Rectangle {
            Layout.fillWidth: true
            height: Appearance.controlRowHeight
            radius: Appearance.radiusSmall
            color: Colors.modalFieldSurface
            border.color: input.activeFocus ? Colors.primary : Colors.border
            border.width: 1

            Behavior on border.color {
                enabled: !Colors.isTransitioning
                CAnim {}
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacingM
                anchors.rightMargin: Appearance.spacingM
                spacing: Appearance.spacingS

                Loader {
                    visible: root.leadingIcon !== ""
                    sourceComponent: String(root.leadingIcon).endsWith(".svg") ? _siSvg : _siNerd
                }
                Component { id: _siSvg; SvgIcon { source: root.leadingIcon; color: Colors.textDisabled; size: Appearance.fontSizeLarge } }
                Component { id: _siNerd; Text { text: root.leadingIcon; color: Colors.textDisabled; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeLarge } }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeMedium
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

                SharedWidgets.SvgIcon {
                    source: IconHelpers.secretVisibilityIcon(root.secretVisible)
                    color: Colors.textDisabled
                    size: Appearance.fontSizeLarge

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.secretVisible = !root.secretVisible
                    }
                }

                SharedWidgets.SvgIcon {
                    visible: root.showClearButton && input.text.length > 0
                    source: "dismiss.svg"
                    color: Colors.textDisabled
                    size: Appearance.fontSizeLarge

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
            spacing: Appearance.spacingS
        }
    }

    Text {
        visible: root.errorText !== ""
        text: root.errorText
        color: Colors.error
        font.pixelSize: Appearance.fontSizeXS
    }
}
