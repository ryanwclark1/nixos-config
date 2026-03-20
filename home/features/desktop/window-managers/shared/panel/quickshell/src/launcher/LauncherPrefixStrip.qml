import QtQuick
import QtQuick.Layouts
import "../services"

Flow {
    id: root

    required property var launcher
    property color accentColor: launcher && launcher.modeAccentColor ? launcher.modeAccentColor : Colors.primary

    Layout.fillWidth: true
    width: parent ? parent.width : 0
    spacing: Appearance.spacingXS
    visible: launcher.prefixQuickModes.length > 0

    Repeater {
        model: launcher.prefixQuickModes

        delegate: Rectangle {
            required property var modelData

            readonly property var modeInfo: root.launcher.modeMeta(modelData)
            readonly property bool active: root.launcher.mode === modelData

            radius: Appearance.radiusPill
            color: active ? Colors.withAlpha(root.accentColor, 0.18) : Colors.withAlpha(Colors.surface, 0.72)
            border.color: active ? Colors.withAlpha(root.accentColor, 0.38) : Colors.border
            border.width: 1
            implicitHeight: 26
            implicitWidth: prefixRow.implicitWidth + 16

            RowLayout {
                id: prefixRow
                anchors.centerIn: parent
                spacing: Appearance.spacingXS

                Text {
                    text: modeInfo.prefix || ""
                    visible: text !== ""
                    color: active ? root.accentColor : Colors.textSecondary
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Black
                }

                Text {
                    text: modeInfo.label
                    color: active ? root.accentColor : Colors.text
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: active ? Font.Bold : Font.DemiBold
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launcher.open(modelData, true)
            }
        }
    }
}
