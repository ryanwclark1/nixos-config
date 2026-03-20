import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"

Rectangle {
    id: root

    property string iconName: "info.svg"
    property string title: ""
    property string body: ""
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusMedium
    color: Colors.withAlpha(Colors.primary, 0.07)
    border.color: Colors.primaryMarked
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

            Loader {
                visible: root.iconName !== ""
                sourceComponent: root.iconName.endsWith(".svg") ? _ciSvg : _ciNerd
                Layout.alignment: Qt.AlignTop
            }
            Component { id: _ciSvg; SvgIcon { source: root.iconName; color: Colors.primary; size: Colors.fontSizeLarge } }
            Component { id: _ciNerd; Text { text: root.iconName; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge } }

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
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
