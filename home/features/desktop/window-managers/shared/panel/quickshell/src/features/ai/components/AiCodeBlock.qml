import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

// Code block for assistant messages with language label and copy button.
// Instantiated via Loader; the Loader delegate provides `modelData` (blockData).
Rectangle {
    id: root
    readonly property var blockData: parent ? parent.modelData : null
    width: parent ? parent.width : 0
    height: codeHeader.height + codeEdit.implicitHeight + Appearance.spacingS * 2
    radius: Appearance.radiusXS
    color: Colors.textFaint
    border.color: Colors.textThin
    border.width: 1

    // Language label + copy button header
    RowLayout {
        id: codeHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.spacingS
        height: 22
        spacing: Appearance.spacingXS

        Text {
            text: (root.blockData && root.blockData.lang) ? root.blockData.lang : "code"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXS
            font.family: Appearance.fontMono
            Layout.fillWidth: true
        }

        Rectangle {
            width: 20
            height: 20
            radius: Appearance.radiusMicro
            color: codeCopyHover.containsMouse ? Colors.bgWidget : "transparent"
            SharedWidgets.SvgIcon {
                anchors.centerIn: parent
                source: "copy.svg"
                color: Colors.textSecondary
                size: Appearance.fontSizeXS
            }
            MouseArea {
                id: codeCopyHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.blockData) {
                        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", root.blockData.content]);
                        ToastService.showNotice("Copied", "Code copied to clipboard");
                    }
                }
            }
            Tooltip {
                text: "Copy code"
                shown: codeCopyHover.containsMouse
                preferredSide: Qt.LeftEdge
            }
        }
    }

    TextEdit {
        id: codeEdit
        anchors.top: codeHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Appearance.spacingS
        anchors.topMargin: Appearance.spacingXS
        text: (root.blockData && root.blockData.highlightedHtml) ? root.blockData.highlightedHtml : (root.blockData ? root.blockData.content : "")
        textFormat: (root.blockData && root.blockData.highlightedHtml) ? TextEdit.RichText : TextEdit.PlainText
        color: Colors.text
        font.pixelSize: Appearance.fontSizeSmall
        font.family: Appearance.fontMono
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        readOnly: true
        selectByMouse: true
        selectedTextColor: Colors.background
        selectionColor: Colors.primary
    }
}
