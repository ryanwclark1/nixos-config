import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root

    required property string summaryText
    required property string primaryAction
    required property string secondaryAction
    required property string tertiaryAction
    property bool compact: false
    property bool helpExpanded: false

    signal helpToggled

    color: Colors.withAlpha(Colors.surface, 0.4)
    radius: Colors.radiusMedium
    border.color: Colors.border
    border.width: 1
    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + (root.compact ? Colors.spacingS * 2 : Colors.paddingSmall * 2)

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.compact ? Colors.spacingS : Colors.paddingSmall
        spacing: root.compact ? Colors.spacingXS : Colors.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                Layout.fillWidth: true
                text: root.summaryText
                color: Colors.textSecondary
                font.pixelSize: root.compact ? Colors.fontSizeXS : Colors.fontSizeSmall
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }

            Rectangle {
                radius: Colors.radiusPill
                color: helpMouse.containsMouse ? Colors.primarySubtle : Colors.withAlpha(Colors.surface, 0.7)
                border.color: root.helpExpanded ? Colors.primaryRing : Colors.border
                border.width: 1
                implicitHeight: root.compact ? 24 : 26
                implicitWidth: helpLabel.implicitWidth + 18

                Text {
                    id: helpLabel
                    anchors.centerIn: parent
                    text: root.helpExpanded ? "Hide Help" : "Show Help"
                    color: root.helpExpanded ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
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
            spacing: root.compact ? Colors.spacingXS : Colors.spacingS

            Repeater {
                model: [root.primaryAction, root.secondaryAction, root.tertiaryAction].filter(function(textValue) {
                    return String(textValue || "").trim() !== "";
                })

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    radius: Colors.radiusPill
                    color: index === 0 ? Colors.primarySubtle : (index === 1 ? Colors.withAlpha(Colors.textSecondary, 0.08) : Colors.surface)
                    border.color: index === 0 ? Colors.primaryRing : (index === 1 ? Colors.primaryAccent : Colors.primarySubtle)
                    border.width: 1
                    implicitHeight: root.compact ? 24 : 26
                    implicitWidth: actionLabel.implicitWidth + (root.compact ? 14 : 18)

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: index === 0 ? Colors.primary : (index === 1 ? Colors.textSecondary : Colors.textDisabled)
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
