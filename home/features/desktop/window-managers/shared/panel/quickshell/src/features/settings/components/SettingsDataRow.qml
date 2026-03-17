import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
    id: root

    property string iconName: ""
    property string label: ""
    property string value: ""
    property int labelWidth: 88
    property bool monoValue: true
    readonly property bool narrowLayout: width < 420

    Layout.fillWidth: true
    implicitHeight: dataContent.implicitHeight + Colors.spacingM * 2
    radius: Colors.radiusXS
    color: Colors.modalFieldSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
        id: dataContent
        anchors.fill: parent
        anchors.leftMargin: Colors.spacingM
        anchors.rightMargin: Colors.spacingM
        anchors.topMargin: Colors.spacingM
        anchors.bottomMargin: Colors.spacingM
        spacing: Colors.spacingM

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingM

            Text {
                visible: root.iconName !== ""
                text: root.iconName
                color: Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
            }

            Text {
                width: root.narrowLayout ? parent.width : root.labelWidth
                text: root.label
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeMedium
                wrapMode: Text.WordWrap
            }
        }

        Text {
            text: root.value
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.family: root.monoValue ? Colors.fontMono : ""
            Layout.fillWidth: true
            wrapMode: Text.WrapAnywhere
        }
    }
}
