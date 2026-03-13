import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    property string iconName: ""
    property string label: ""
    property string value: ""
    property int labelWidth: 88
    property bool monoValue: true

    Layout.fillWidth: true
    implicitHeight: 52
    radius: Colors.radiusXS
    color: Colors.bgWidget
    border.color: Colors.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Colors.spacingM
        anchors.rightMargin: Colors.spacingM
        spacing: Colors.spacingM

        Text {
            visible: root.iconName !== ""
            text: root.iconName
            color: Colors.primary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeXL
        }

        Text {
            text: root.label
            color: Colors.fgSecondary
            font.pixelSize: Colors.fontSizeMedium
            Layout.preferredWidth: root.labelWidth
            elide: Text.ElideRight
        }

        Text {
            text: root.value
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.family: root.monoValue ? Colors.fontMono : ""
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
