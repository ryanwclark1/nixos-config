import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false
    signal triggerRequested(var triggerItem)

    SharedWidgets.Ref { service: ModelUsageService }

    tooltipText: ModelUsageService.displayTooltip
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Refresh Now",
            icon: "󰑓",
            action: () => ModelUsageService.refresh()
        },
        {
            label: "Switch Provider",
            icon: "󰔡",
            visible: ModelUsageService.claudeEnabled && ModelUsageService.codexEnabled,
            action: () => ModelUsageService.switchProvider()
        }
    ]

    Row {
        spacing: Colors.spacingS

        Text {
            text: "󰊤"
            color: Colors.accent
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical)
            text: ModelUsageService.displayText
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
