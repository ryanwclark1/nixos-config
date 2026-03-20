import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared" as Shared

Rectangle {
    id: root

    property string iconName: ""
    property string label: ""
    property string value: ""
    property int labelWidth: 88
    property bool monoValue: true
    readonly property bool narrowLayout: width < 420

    Layout.fillWidth: true
    implicitHeight: dataContent.implicitHeight + Appearance.spacingM * 2
    radius: Appearance.radiusXS
    color: Colors.modalFieldSurface
    border.color: Colors.border
    border.width: 1

    ColumnLayout {
        id: dataContent
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacingM
        anchors.rightMargin: Appearance.spacingM
        anchors.topMargin: Appearance.spacingM
        anchors.bottomMargin: Appearance.spacingM
        spacing: Appearance.spacingM

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingM

            Loader {
                visible: root.iconName !== ""
                sourceComponent: root.iconName.endsWith(".svg") ? _svgIcon : _nerdIcon
            }
            Component {
                id: _svgIcon
                Shared.SvgIcon { source: root.iconName; color: Colors.primary; size: Appearance.fontSizeXL }
            }
            Component {
                id: _nerdIcon
                Text {
                    text: root.iconName
                    color: Colors.primary
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeXL
                }
            }

            Text {
                width: root.narrowLayout ? parent.width : root.labelWidth
                text: root.label
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeMedium
                wrapMode: Text.WordWrap
            }
        }

        Text {
            text: root.value
            color: Colors.text
            font.pixelSize: Appearance.fontSizeMedium
            font.family: root.monoValue ? Appearance.fontMono : ""
            Layout.fillWidth: true
            wrapMode: Text.WrapAnywhere
        }
    }
}
