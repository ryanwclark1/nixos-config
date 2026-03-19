pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"

ColumnLayout {
    id: root

    property string title: ""
    property string description: ""
    default property alias content: bodyColumn.data

    Layout.fillWidth: true
    spacing: Colors.spacingS

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingXXS
        visible: !!root.title || !!root.description

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Colors.text
            font.pixelSize: Colors.fontSizeLarge
            font.weight: Font.Black
            wrapMode: Text.WordWrap
            visible: !!text
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            wrapMode: Text.WordWrap
            visible: !!text
        }
    }

    ColumnLayout {
        id: bodyColumn
        Layout.fillWidth: true
        spacing: Colors.spacingL
    }
}
