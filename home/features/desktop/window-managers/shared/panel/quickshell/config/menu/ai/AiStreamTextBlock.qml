import QtQuick
import "../../services"

// Streaming text block — like AiTextBlock but with a blinking cursor overlay.
// Instantiated via Loader; the Loader delegate provides `modelData` (blockData)
// and `index` (position in the streaming blocks Repeater).
Rectangle {
    id: root
    property var blockData: parent ? parent.modelData : null
    property int blockIndex: parent ? parent.index : 0
    width: parent ? parent.width : 0
    height: streamTextBlockEdit.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1

    TextEdit {
        id: streamTextBlockEdit
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        anchors.rightMargin: Colors.spacingM + 12
        text: root.blockData ? root.blockData.html : ""
        textFormat: TextEdit.RichText
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        readOnly: true
        selectByMouse: true
    }

    // Blinking cursor — shown on the last streaming block.
    // Uses blockIndex (from parent.index on the Loader) compared against the
    // Repeater count, accessed via the Loader's parent chain.
    Rectangle {
        width: 2
        height: 16
        radius: 1
        color: Colors.primary
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: Colors.spacingM
        anchors.rightMargin: Colors.spacingS
        readonly property int streamingBlockCount: {
            // Walk up: root.parent = Loader, root.parent.parent = Column (streaming indicator),
            // then find the Repeater child that has a count property.
            var col = root.parent ? root.parent.parent : null;
            if (!col)
                return 0;
            for (var i = 0; i < col.children.length; i++) {
                if (col.children[i].count !== undefined)
                    return col.children[i].count;
            }
            return 0;
        }
        opacity: cursorBlink.running && (streamingBlockCount === 0 || root.blockIndex === streamingBlockCount - 1) ? (cursorBlink.cursorVisible ? 1 : 0) : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Colors.durationFast
            }
        }

        Timer {
            id: cursorBlink
            interval: 530
            repeat: true
            running: AiService.isStreaming
            property bool cursorVisible: true
            onTriggered: cursorVisible = !cursorVisible
        }
    }
}
