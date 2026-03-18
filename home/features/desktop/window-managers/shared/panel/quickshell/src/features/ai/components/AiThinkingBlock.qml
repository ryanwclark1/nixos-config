import QtQuick
import QtQuick.Layouts
import "../../../services"

// Collapsible thinking block for extended-thinking model responses.
// Instantiated via Loader; the Loader delegate provides `modelData` (blockData).
Rectangle {
    id: root
    readonly property var blockData: parent ? parent.modelData : null
    property bool expanded: AiService.isStreaming // Expanded by default while streaming
    width: parent ? parent.width : 0
    height: thinkingHeader.height + (expanded ? thinkingContent.implicitHeight + Colors.spacingS : 0)
    radius: Colors.radiusXS
    color: Colors.withAlpha(Colors.textDisabled, 0.06)
    border.color: Colors.withAlpha(Colors.textDisabled, 0.12)
    border.width: 1
    clip: true

    Behavior on height {
        NumberAnimation {
            duration: Colors.durationFast
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: thinkingHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Colors.spacingS
        height: 24
        spacing: Colors.spacingXS

        Text {
            text: root.expanded ? "▾" : "▸"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeSmall
        }
        Text {
            text: "Thinking..."
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeSmall
            font.italic: true
            Layout.fillWidth: true
        }
    }

    MouseArea {
        anchors.fill: thinkingHeader
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
    }

    TextEdit {
        id: thinkingContent
        anchors.top: thinkingHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Colors.spacingS
        anchors.topMargin: Colors.spacingXS
        visible: root.expanded
        text: root.blockData ? root.blockData.html : ""
        textFormat: TextEdit.RichText
        color: Colors.textSecondary
        font.pixelSize: Colors.fontSizeSmall
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        readOnly: true
        selectByMouse: true
        opacity: 0.8
    }
}
