import QtQuick
import QtQuick.Layouts
import "../../../shared"
import "../../../services"
import "../../../widgets" as SharedWidgets

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

    spacing: Appearance.spacingS
    Layout.fillWidth: true
    Layout.minimumWidth: 0

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
            id: inputContainer
            Layout.fillWidth: true
            height: Appearance.controlRowHeight
            radius: Appearance.radiusSmall
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
                    NumberAnimation { target: textHighlightPulse; property: "_opacity"; from: 0; to: 0.2; duration: Appearance.durationSlow; easing.type: Easing.OutCubic }
                    NumberAnimation { target: textHighlightPulse; property: "_opacity"; from: 0.2; to: 0; duration: Appearance.durationSlow; easing.type: Easing.InCubic }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacingM
                anchors.rightMargin: Appearance.spacingM
                spacing: Appearance.spacingS

                Loader {
                    visible: root.leadingIcon !== ""
                    sourceComponent: String(root.leadingIcon).endsWith(".svg") ? _tiSvg : _tiNerd
                }
                Component { id: _tiSvg; SvgIcon { source: root.leadingIcon; color: Colors.textDisabled; size: Appearance.fontSizeLarge } }
                Component { id: _tiNerd; Text { text: root.leadingIcon; color: Colors.textDisabled; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeLarge } }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeMedium
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
