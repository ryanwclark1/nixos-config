import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../services/AiProviders.js" as Providers

// Floating dropdown for selecting the AI provider and model.
// Position and visibility are controlled by the parent (AiChat.qml).
Rectangle {
    id: root
    visible: false
    width: 220
    height: dropdownCol.implicitHeight + Appearance.spacingS * 2
    color: Colors.bgWidget
    border.color: Colors.border
    border.width: 1
    radius: Appearance.radiusMedium
    z: 20

    Column {
        id: dropdownCol
        anchors.fill: parent
        anchors.margins: Appearance.spacingS
        spacing: Appearance.spacingXS

        // Provider section header
        Text {
            text: "Provider"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXS
            font.weight: Font.DemiBold
            leftPadding: Appearance.spacingXS
        }

        Repeater {
            model: Providers.allProviders()

            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool isCurrent: modelData === Config.aiProvider
                width: dropdownCol.width - Appearance.spacingS * 2
                height: 26
                radius: Appearance.radiusXXS
                color: isCurrent ? Colors.highlightLight : providerItemMouse.containsMouse ? Colors.primaryFaint : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.spacingS
                    anchors.rightMargin: Appearance.spacingS
                    spacing: Appearance.spacingXS

                    Text {
                        text: Providers.providerIcon(modelData)
                        font.family: Appearance.fontMono
                        font.pixelSize: Appearance.fontSizeSmall
                        color: isCurrent ? Colors.primary : Colors.text
                    }
                    Text {
                        text: Providers.providerLabel(modelData)
                        font.pixelSize: Appearance.fontSizeSmall
                        color: isCurrent ? Colors.primary : Colors.text
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: Providers.needsApiKey(modelData) && !AiService.apiKeyAvailable(modelData)
                        text: "󰌆"
                        font.family: Appearance.fontMono
                        font.pixelSize: Appearance.fontSizeXS
                        color: Colors.warning
                    }
                }

                MouseArea {
                    id: providerItemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.aiProvider = modelData;
                        Config.aiModel = "";
                        root.visible = false;
                    }
                }
            }
        }

        // Separator
        Rectangle {
            width: dropdownCol.width - Appearance.spacingS * 2
            height: 1
            color: Colors.border
        }

        // Model section header
        Text {
            text: "Model"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXS
            font.weight: Font.DemiBold
            leftPadding: Appearance.spacingXS
        }

        Repeater {
            model: AiService.availableModels

            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool isCurrent: modelData === AiService.activeModel
                width: dropdownCol.width - Appearance.spacingS * 2
                height: 26
                radius: Appearance.radiusXXS
                color: isCurrent ? Colors.highlightLight : modelItemMouse.containsMouse ? Colors.primaryFaint : "transparent"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Appearance.spacingS
                    text: modelData
                    font.pixelSize: Appearance.fontSizeSmall
                    font.family: Appearance.fontMono
                    color: isCurrent ? Colors.primary : Colors.text
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: modelItemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.aiModel = modelData;
                        root.visible = false;
                    }
                }
            }
        }
    }
}
