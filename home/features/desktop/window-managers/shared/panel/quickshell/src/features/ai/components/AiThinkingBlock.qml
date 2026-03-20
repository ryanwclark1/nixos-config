import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

// Collapsible thinking block for extended-thinking model responses.
// Instantiated via Loader; the Loader delegate provides `modelData` (blockData).
Rectangle {
    id: root
    readonly property var blockData: parent ? parent.modelData : null
    property bool expanded: AiService.isStreaming
    readonly property string rawText: blockData ? (blockData.text || "") : ""
    readonly property int charCount: rawText.length
    width: parent ? parent.width : 0
    height: thinkingHeader.height + (expanded ? thinkingContent.implicitHeight + Appearance.spacingS : 0)
    radius: Appearance.radiusXS
    color: Colors.withAlpha(Colors.textDisabled, 0.06)
    border.color: Colors.withAlpha(Colors.textDisabled, 0.12)
    border.width: 1
    clip: true

    Behavior on height {
        Anim { duration: Appearance.durationFast }
    }

    RowLayout {
        id: thinkingHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.spacingS
        height: 28
        spacing: Appearance.spacingXS

        // Animated chevron
        SharedWidgets.SvgIcon {
            source: "sparkle.svg"
            rotation: root.expanded ? 0 : -90
            color: Colors.textDisabled
            size: Appearance.fontSizeSmall

            Behavior on rotation {
                Anim { duration: Appearance.durationFast }
            }
        }

        Text {
            text: AiService.isStreaming ? "Thinking..." : "Thought process"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeSmall
            font.italic: AiService.isStreaming
            Layout.fillWidth: true

            // Pulsing opacity while streaming
            SequentialAnimation on opacity {
                running: AiService.isStreaming
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.5; duration: Appearance.durationPulse }
                NumberAnimation { from: 0.5; to: 1.0; duration: Appearance.durationPulse }
            }
        }

        // Character count badge
        Rectangle {
            visible: root.charCount > 0 && !root.expanded
            width: countLabel.implicitWidth + Appearance.spacingS * 2
            height: 18
            radius: Appearance.radiusPill
            color: Colors.primaryFaint

            Text {
                id: countLabel
                anchors.centerIn: parent
                text: root.charCount > 999 ? (Math.floor(root.charCount / 1000) + "k chars") : root.charCount + " chars"
                color: Colors.primary
                font.pixelSize: Appearance.fontSizeXXS
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
        anchors.margins: Appearance.spacingS
        anchors.topMargin: Appearance.spacingXS
        visible: root.expanded
        text: root.blockData ? root.blockData.html : ""
        textFormat: TextEdit.RichText
        color: Colors.textSecondary
        font.pixelSize: Appearance.fontSizeSmall
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        readOnly: true
        selectByMouse: true
        opacity: 0.8
    }
}
