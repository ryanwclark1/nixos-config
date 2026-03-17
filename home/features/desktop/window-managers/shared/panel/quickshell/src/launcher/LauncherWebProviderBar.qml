import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
    id: root

    required property var providers
    required property string selectedKey

    signal providerSelected(string key)

    Layout.fillWidth: true
    color: Colors.bgWidget
    radius: Colors.radiusMedium
    border.color: Colors.border
    border.width: 1
    implicitHeight: providerFlowContainer.implicitHeight + (Colors.spacingM * 2)

    Column {
        id: providerFlowContainer
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingXS

        Text {
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
            text: "PROVIDERS"
        }

        Flow {
            width: parent.width
            spacing: Colors.spacingS

            Repeater {
                model: root.providers

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool selected: String(modelData.key || "") === root.selectedKey
                    color: selected ? Colors.primaryMid : Colors.surface
                    radius: Colors.radiusPill
                    border.color: selected ? Colors.withAlpha(Colors.primary, 0.6) : Colors.border
                    border.width: 1
                    implicitHeight: 28
                    implicitWidth: Math.min(providerChipText.implicitWidth + 24, providerFlowContainer.width)

                    Text {
                        id: providerChipText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 18)
                        text: (modelData.icon || "󰖟") + " " + (modelData.name || "")
                        color: parent.selected ? Colors.primary : Colors.textSecondary
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
