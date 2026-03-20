import QtQuick
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root
    required property string modelData
    required property int index
    signal removed()

    implicitWidth: chipRow.implicitWidth + 16
    implicitHeight: 28
    radius: Appearance.radiusPill
    color: Colors.primaryGhost
    border.color: Colors.border
    border.width: 1

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Appearance.spacingXS

        Text {
            text: root.modelData
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
        }

        SharedWidgets.SvgIcon {
            source: "dismiss.svg"
            color: Colors.textSecondary
            size: Appearance.fontSizeSmall

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removed()
            }
        }
    }
}
