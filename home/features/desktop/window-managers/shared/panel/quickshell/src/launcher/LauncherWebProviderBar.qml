import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root

    required property var providers
    required property string selectedKey
    property color accentColor: Colors.primary

    signal providerSelected(string key)

    Layout.fillWidth: true
    color: "transparent"
    implicitHeight: providerFlowContainer.implicitHeight

    Column {
        id: providerFlowContainer
        anchors.fill: parent
        spacing: Colors.spacingXS

        Text {
            color: Colors.withAlpha(root.accentColor, 0.92)
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Colors.letterSpacingExtraWide
            text: "ACTIVE PROVIDERS"
        }

        Flow {
            width: parent.width
            spacing: Colors.spacingS

            Repeater {
                model: root.providers

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool selected: String(modelData.key || "") === root.selectedKey
                    color: selected ? Colors.withAlpha(root.accentColor, 0.16) : Colors.withAlpha(Colors.surface, 0.72)
                    radius: Colors.radiusPill
                    border.color: selected ? Colors.withAlpha(root.accentColor, 0.4) : Colors.border
                    border.width: 1
                    implicitHeight: 28
                    implicitWidth: Math.min(providerChipText.implicitWidth + 24, providerFlowContainer.width)

                    Text {
                        id: providerChipText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 18)
                        text: (modelData.icon || "󰖟") + " " + (modelData.name || "")
                        color: parent.selected ? root.accentColor : Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.providerSelected(String(modelData.key || ""))
                    }
                }
            }
        }
    }
}
