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
    implicitHeight: contentColumn.implicitHeight + Appearance.spacingM * 2
    radius: Appearance.radiusMedium
    color: Colors.withAlpha(Colors.primary, 0.07)
    border.color: Colors.primaryMarked
    border.width: 1

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.spacingM
        }
        spacing: Appearance.spacingS

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            Loader {
                visible: root.iconName !== ""
                sourceComponent: String(root.iconName).endsWith(".svg") ? _ciSvg : _ciNerd
                Layout.alignment: Qt.AlignTop
            }
            Component { id: _ciSvg; SvgIcon { source: root.iconName; color: Colors.primary; size: Appearance.fontSizeLarge } }
            Component { id: _ciNerd; Text { text: root.iconName; color: Colors.primary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeLarge } }

            Text {
                width: root.iconName !== "" ? Math.max(0, parent.width - Appearance.fontSizeLarge - Appearance.spacingS) : parent.width
                visible: root.title !== ""
                text: root.title
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }
        }

        Text {
            visible: root.body !== ""
            text: root.body
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeSmall
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
