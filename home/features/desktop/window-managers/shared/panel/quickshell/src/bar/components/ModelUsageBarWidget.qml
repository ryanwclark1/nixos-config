import QtQuick
import Quickshell
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
            visible: (ModelUsageService.claudeEnabled ? 1 : 0)
                   + (ModelUsageService.codexEnabled ? 1 : 0)
                   + (ModelUsageService.geminiEnabled ? 1 : 0) > 1,
            action: () => ModelUsageService.switchProvider()
        },
        {
            label: "Settings",
            icon: "settings.svg",
            action: () => Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "model-usage"])
        }
    ]

    Row {
        spacing: Appearance.spacingS

        Text {
            text: ModelUsageService.providerIcon
            color: ModelUsageService.providerColor
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationMedium } }
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical)
            text: ModelUsageService.displayText
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
