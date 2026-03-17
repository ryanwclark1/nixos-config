import QtQuick
import "../../services"

// Text block for rendered assistant message content.
// Instantiated via Loader; the Loader delegate provides `modelData` (blockData).
Rectangle {
    id: root
    property var blockData: parent ? parent.modelData : null
    width: parent ? parent.width : 0
    height: textBlockEdit.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1

    TextEdit {
        id: textBlockEdit
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        text: root.blockData ? root.blockData.html : ""
        textFormat: TextEdit.RichText
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        readOnly: true
        selectByMouse: true
        selectedTextColor: Colors.background
        selectionColor: Colors.primary
    }
}
