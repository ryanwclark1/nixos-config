import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root
    property string placeholder: "Search..."
    property alias text: searchInput.text
    readonly property alias inputItem: searchInput
    property int preferredHeight: Appearance.controlRowHeight

    Layout.fillWidth: true
    height: preferredHeight
    radius: Appearance.radiusSmall
    color: Colors.highlightLight
    border.color: searchInput.activeFocus ? Colors.primary : "transparent"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacingS
        spacing: Appearance.spacingS

        SvgIcon {
            source: "search-visual.svg"
            color: Colors.textSecondary
            size: Appearance.fontSizeMedium
        }

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            verticalAlignment: Text.AlignVCenter
            onVisibleChanged: if (!visible && activeFocus) focus = false
        }

        Text {
            text: root.placeholder
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeSmall
            visible: !searchInput.text && !searchInput.activeFocus
        }
    }
}
