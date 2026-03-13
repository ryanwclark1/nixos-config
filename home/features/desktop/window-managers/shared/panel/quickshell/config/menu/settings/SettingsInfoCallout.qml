import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    property string iconName: "󰋗"
    property string title: ""
    property string body: ""
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.07)
    border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
    border.width: 1

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Colors.spacingM
        }
        spacing: Colors.spacingS

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            Text {
                visible: root.iconName !== ""
                text: root.iconName
                color: Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeLarge
                Layout.alignment: Qt.AlignTop
            }

            Text {
                width: root.iconName !== "" ? Math.max(0, parent.width - Colors.fontSizeLarge - Colors.spacingS) : parent.width
                visible: root.title !== ""
                text: root.title
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }
        }

        Text {
            visible: root.body !== ""
            text: root.body
            color: Colors.fgSecondary
            font.pixelSize: Colors.fontSizeSmall
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
