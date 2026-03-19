import QtQuick
import QtQuick.Layouts
import "../services"

Flow {
    id: root

    required property var launcher

    spacing: Colors.spacingS
    visible: launcher.prefixQuickModes.length > 0

    Repeater {
        model: launcher.prefixQuickModes

        delegate: Rectangle {
            required property var modelData

            readonly property var modeInfo: root.launcher.modeMeta(modelData)
            readonly property bool active: root.launcher.mode === modelData

            radius: Colors.radiusPill
            color: active ? Colors.primarySubtle : Colors.withAlpha(Colors.surface, 0.72)
            border.color: active ? Colors.primaryRing : Colors.border
            border.width: 1
            implicitHeight: 30
            implicitWidth: prefixRow.implicitWidth + 20

            RowLayout {
                id: prefixRow
                anchors.centerIn: parent
                spacing: Colors.spacingXS

                Text {
                    text: modeInfo.prefix || ""
                    visible: text !== ""
                    color: active ? Colors.primary : Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Black
                }

                Text {
                    text: modeInfo.label
                    color: active ? Colors.primary : Colors.text
                    font.pixelSize: Colors.fontSizeXS
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
