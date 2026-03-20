import QtQuick
import "../../../services"

// Text block for rendered assistant message content.
// Instantiated via Loader; the Loader delegate provides `modelData` (blockData).
Rectangle {
    id: root
    readonly property var blockData: parent ? parent.modelData : null
    width: parent ? parent.width : 0
    height: textBlockEdit.implicitHeight + Appearance.spacingM * 2
    radius: Appearance.radiusMedium
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1

    TextEdit {
        id: textBlockEdit
        anchors.fill: parent
        anchors.margins: Appearance.spacingM
        text: root.blockData ? root.blockData.html : ""
        textFormat: TextEdit.RichText
        color: Colors.text
        font.pixelSize: Appearance.fontSizeMedium
        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
        readOnly: true
        selectByMouse: true
        selectedTextColor: Colors.background
        selectionColor: Colors.primary
    }
}
