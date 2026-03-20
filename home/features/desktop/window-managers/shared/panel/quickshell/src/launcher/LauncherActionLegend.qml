import QtQuick
import QtQuick.Layouts
import "../services"

Item {
    id: root

    required property string summaryText
    required property string primaryAction
    required property string secondaryAction
    required property string tertiaryAction
    property color accentColor: Colors.primary
    property bool compact: false
    property bool helpExpanded: false

    signal helpToggled

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: root.compact ? Appearance.spacingXS : Appearance.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Text {
                text: "ACTION MAP"
                color: Colors.withAlpha(root.accentColor, 0.92)
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingExtraWide
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: 1
                radius: Appearance.radiusXXXS
                color: Colors.withAlpha(root.accentColor, 0.18)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Rectangle {
                radius: Appearance.radiusPill
                color: Colors.withAlpha(root.accentColor, 0.14)
                border.color: Colors.withAlpha(root.accentColor, 0.34)
                border.width: 1
                implicitHeight: 24
                implicitWidth: primaryLabel.implicitWidth + 16

                Text {
                    id: primaryLabel
                    anchors.centerIn: parent
                    text: root.primaryAction
                    color: root.accentColor
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.DemiBold
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.summaryText
                color: Colors.textSecondary
                font.pixelSize: root.compact ? Appearance.fontSizeXS : Appearance.fontSizeSmall
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }

            Rectangle {
                radius: Appearance.radiusPill
                color: helpMouse.containsMouse ? Colors.withAlpha(root.accentColor, 0.12) : Colors.withAlpha(Colors.surface, 0.7)
                border.color: root.helpExpanded ? Colors.withAlpha(root.accentColor, 0.34) : Colors.border
                border.width: 1
                implicitHeight: root.compact ? 24 : 26
                implicitWidth: helpLabel.implicitWidth + 18

                Text {
                    id: helpLabel
                    anchors.centerIn: parent
                    text: root.helpExpanded ? "Hide Help" : "Show Help"
                    color: root.helpExpanded ? root.accentColor : Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: helpMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.helpToggled()
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: root.helpExpanded
            spacing: root.compact ? Appearance.spacingXS : Appearance.spacingS

            Repeater {
                model: [root.primaryAction, root.secondaryAction, root.tertiaryAction].filter(function(textValue) {
                    return String(textValue || "").trim() !== "";
                })

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    radius: Appearance.radiusPill
                    color: index === 0 ? Colors.withAlpha(root.accentColor, 0.14) : (index === 1 ? Colors.withAlpha(Colors.textSecondary, 0.08) : Colors.surface)
                    border.color: index === 0 ? Colors.withAlpha(root.accentColor, 0.34) : (index === 1 ? Colors.withAlpha(Colors.textSecondary, 0.16) : Colors.primarySubtle)
                    border.width: 1
                    implicitHeight: root.compact ? 24 : 26
                    implicitWidth: actionLabel.implicitWidth + (root.compact ? 14 : 18)

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: index === 0 ? root.accentColor : (index === 1 ? Colors.textSecondary : Colors.textDisabled)
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
