import QtQuick
import QtQuick.Layouts
import "../services"

ColumnLayout {
    id: root

    required property var launcher
    property color accentColor: launcher && launcher.modeAccentColor ? launcher.modeAccentColor : Colors.primary

    spacing: Colors.spacingS
    visible: launcher.prefixQuickModes.length > 0

    RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingS

        Text {
            text: "PREFIXES"
            color: Colors.withAlpha(root.accentColor, 0.92)
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Colors.letterSpacingExtraWide
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: 1
            radius: Colors.radiusXXXS
            color: Colors.withAlpha(root.accentColor, 0.18)
        }
    }

    Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: Colors.spacingS

        Repeater {
            model: launcher.prefixQuickModes

            delegate: Rectangle {
                required property var modelData

                readonly property var modeInfo: root.launcher.modeMeta(modelData)
                readonly property bool active: root.launcher.mode === modelData

                radius: Colors.radiusPill
                color: active ? Colors.withAlpha(root.accentColor, 0.18) : Colors.withAlpha(Colors.surface, 0.72)
                border.color: active ? Colors.withAlpha(root.accentColor, 0.38) : Colors.border
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
                        color: active ? root.accentColor : Colors.textSecondary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.Black
                    }

                    Text {
                        text: modeInfo.label
                        color: active ? root.accentColor : Colors.text
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
}
