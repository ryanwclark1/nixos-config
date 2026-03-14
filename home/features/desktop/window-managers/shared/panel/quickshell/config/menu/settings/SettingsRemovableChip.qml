import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root
    required property string modelData
    required property int index
    signal removed()

    implicitWidth: chipRow.implicitWidth + 16
    implicitHeight: 28
    radius: Colors.radiusPill
    color: Colors.withAlpha(Colors.primary, 0.1)
    border.color: Colors.border
    border.width: 1

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Colors.spacingXS

        Text {
            text: root.modelData
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
        }

        Text {
            text: "󰅖"
            color: Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeSmall

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removed()
            }
        }
    }
}
