import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root

    required property string primaryEnterHint
    required property string secondaryEnterHint
    required property string aliasHint
    required property string hotkeyHint
    property color accentColor: Colors.primary
    property bool compact: false

    Layout.fillWidth: true
    color: "transparent"
    implicitHeight: webHintColumn.implicitHeight

    Column {
        id: webHintColumn
        anchors.fill: parent
        spacing: root.compact ? 3 : Colors.spacingXS

        Text {
            width: parent.width
            text: "WEB CONTROLS"
            color: Colors.withAlpha(root.accentColor, 0.92)
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Colors.letterSpacingExtraWide
        }

        Row {
            width: parent.width
            spacing: Colors.spacingS

            Text {
                text: "󰖟"
                color: root.accentColor
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
