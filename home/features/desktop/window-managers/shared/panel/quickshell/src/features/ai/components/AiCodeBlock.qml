import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"

// Code block for assistant messages with language label and copy button.
// Instantiated via Loader; the Loader delegate provides `modelData` (blockData).
Rectangle {
    id: root
    property var blockData: parent ? parent.modelData : null
    width: parent ? parent.width : 0
    height: codeHeader.height + codeEdit.implicitHeight + Colors.spacingS * 2
    radius: Colors.radiusXS
    color: Colors.withAlpha(Colors.text, 0.06)
    border.color: Colors.withAlpha(Colors.text, 0.1)
    border.width: 1

    function _shellEscape(str) {
        return "'" + str.replace(/'/g, "'\\''") + "'";
    }

    // Language label + copy button header
    RowLayout {
        id: codeHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Colors.spacingS
        height: 22
        spacing: Colors.spacingXS

        Text {
            text: (root.blockData && root.blockData.lang) ? root.blockData.lang : "code"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.family: Colors.fontMono
            Layout.fillWidth: true
        }

        Rectangle {
            width: 20
            height: 20
            radius: Colors.radiusMicro
            color: codeCopyHover.containsMouse ? Colors.bgWidget : "transparent"
            Text {
                anchors.centerIn: parent
                text: "󰆏"
                color: Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXS
            }
            MouseArea {
                id: codeCopyHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.blockData) {
                        Quickshell.execDetached(["sh", "-c", "printf '%s' " + root._shellEscape(root.blockData.content) + " | wl-copy"]);
                        ToastService.showNotice("Copied", "Code copied to clipboard");
                    }
                }
            }
        }
    }

    TextEdit {
        id: codeEdit
        anchors.top: codeHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Colors.spacingS
        anchors.topMargin: Colors.spacingXS
        text: (root.blockData && root.blockData.highlightedHtml) ? root.blockData.highlightedHtml : (root.blockData ? root.blockData.content : "")
        textFormat: (root.blockData && root.blockData.highlightedHtml) ? TextEdit.RichText : TextEdit.PlainText
        color: Colors.text
        font.pixelSize: Colors.fontSizeSmall
        font.family: Colors.fontMono
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        readOnly: true
        selectByMouse: true
        selectedTextColor: Colors.background
        selectionColor: Colors.primary
    }
}
