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
    spacing: Appearance.spacingS

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingXXS
        visible: !!root.title || !!root.description

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Colors.text
            font.pixelSize: Appearance.fontSizeLarge
            font.weight: Font.Black
            wrapMode: Text.WordWrap
            visible: !!text
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeSmall
            wrapMode: Text.WordWrap
            visible: !!text
        }
    }

    ColumnLayout {
        id: bodyColumn
        Layout.fillWidth: true
        spacing: Appearance.spacingL
    }
}
