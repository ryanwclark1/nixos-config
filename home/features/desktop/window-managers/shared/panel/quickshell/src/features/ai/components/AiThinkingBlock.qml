import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"

// Collapsible thinking block for extended-thinking model responses.
// Instantiated via Loader; the Loader delegate provides `modelData` (blockData).
Rectangle {
    id: root
    readonly property var blockData: parent ? parent.modelData : null
    property bool expanded: AiService.isStreaming
    readonly property string rawText: blockData ? (blockData.text || "") : ""
    readonly property int charCount: rawText.length
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
        height: 28
        spacing: Colors.spacingXS

        // Animated chevron
        Text {
            text: "\u{f0156}"
            rotation: root.expanded ? 0 : -90
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeSmall

            Behavior on rotation {
                Anim { duration: Colors.durationFast }
            }
        }

        Text {
            text: AiService.isStreaming ? "Thinking..." : "Thought process"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeSmall
            font.italic: AiService.isStreaming
            Layout.fillWidth: true

            // Pulsing opacity while streaming
            SequentialAnimation on opacity {
                running: AiService.isStreaming
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.5; duration: Colors.durationPulse }
                NumberAnimation { from: 0.5; to: 1.0; duration: Colors.durationPulse }
            }
        }

        // Character count badge
        Rectangle {
            visible: root.charCount > 0 && !root.expanded
            width: countLabel.implicitWidth + Colors.spacingS * 2
            height: 18
            radius: Colors.radiusPill
            color: Colors.primaryFaint

            Text {
                id: countLabel
                anchors.centerIn: parent
                text: root.charCount > 999 ? (Math.floor(root.charCount / 1000) + "k chars") : root.charCount + " chars"
                color: Colors.primary
                font.pixelSize: Colors.fontSizeXXS
                font.weight: Font.Bold
            }
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
