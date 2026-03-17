import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root

    required property string primaryEnterHint
    required property string secondaryEnterHint
    required property string aliasHint
    required property string hotkeyHint
    property bool compact: false

    Layout.fillWidth: true
    color: Colors.bgWidget
    radius: Colors.radiusMedium
    border.color: Colors.border
    border.width: 1
    implicitHeight: webHintColumn.implicitHeight + (Colors.spacingS * 2)

    Column {
        id: webHintColumn
        anchors.fill: parent
        anchors.margins: Colors.spacingS
        spacing: root.compact ? 3 : Colors.spacingXS

        Row {
            width: parent.width
            spacing: Colors.spacingS

            Text {
                text: "󰖟"
                color: Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeSmall
            }

            Text {
                width: parent.width - x
                text: root.primaryEnterHint + " • " + root.secondaryEnterHint + " • " + root.aliasHint
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                wrapMode: Text.WordWrap
            }
        }

        Text {
            width: parent.width
            text: root.hotkeyHint
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WordWrap
        }
    }
}
