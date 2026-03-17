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
    height: dropdownCol.implicitHeight + Colors.spacingS * 2
    color: Colors.bgWidget
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    z: 20

    Column {
        id: dropdownCol
        anchors.fill: parent
        anchors.margins: Colors.spacingS
        spacing: Colors.spacingXS

        // Provider section header
        Text {
            text: "Provider"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.DemiBold
            leftPadding: Colors.spacingXS
        }

        Repeater {
            model: Providers.allProviders()

            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool isCurrent: modelData === Config.aiProvider
                width: dropdownCol.width - Colors.spacingS * 2
                height: 26
                radius: Colors.radiusXXS
                color: isCurrent ? Colors.withAlpha(Colors.primary, 0.15) : providerItemMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.08) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Colors.spacingS
                    anchors.rightMargin: Colors.spacingS
                    spacing: Colors.spacingXS

                    Text {
                        text: Providers.providerIcon(modelData)
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeSmall
                        color: isCurrent ? Colors.primary : Colors.text
                    }
                    Text {
                        text: Providers.providerLabel(modelData)
                        font.pixelSize: Colors.fontSizeSmall
                        color: isCurrent ? Colors.primary : Colors.text
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: Providers.needsApiKey(modelData) && !AiService.apiKeyAvailable(modelData)
                        text: "󰌆"
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeXS
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
            width: dropdownCol.width - Colors.spacingS * 2
            height: 1
            color: Colors.border
        }

        // Model section header
        Text {
            text: "Model"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.DemiBold
            leftPadding: Colors.spacingXS
        }

        Repeater {
            model: AiService.availableModels

            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool isCurrent: modelData === AiService.activeModel
                width: dropdownCol.width - Colors.spacingS * 2
                height: 26
                radius: Colors.radiusXXS
                color: isCurrent ? Colors.withAlpha(Colors.primary, 0.15) : modelItemMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.08) : "transparent"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Colors.spacingS
                    text: modelData
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontMono
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
