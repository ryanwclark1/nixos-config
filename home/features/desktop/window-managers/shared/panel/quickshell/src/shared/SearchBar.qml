import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root
    property string placeholder: "Search..."
    property alias text: searchInput.text
    readonly property alias inputItem: searchInput
    property int preferredHeight: 38

    Layout.fillWidth: true
    height: preferredHeight
    radius: Colors.radiusSmall
    color: Colors.highlightLight
    border.color: searchInput.activeFocus ? Colors.primary : "transparent"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingS
        spacing: Colors.spacingS

        Text {
            text: "󰍉"
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeMedium
        }

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            verticalAlignment: Text.AlignVCenter
            onVisibleChanged: if (!visible && activeFocus) focus = false
        }

        Text {
            text: root.placeholder
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeSmall
            visible: !searchInput.text && !searchInput.activeFocus
        }
    }
}
