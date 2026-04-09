import QtQuick
import Quickshell
import "../../services"
import "../../services/ShellUtils.js" as SU
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
            icon: "arrow-counterclockwise.svg",
            action: () => ModelUsageService.refresh()
        },
        {
            label: "Switch Provider",
            icon: "arrow-swap.svg",
            visible: (ModelUsageService.claudeEnabled ? 1 : 0)
                   + (ModelUsageService.codexEnabled ? 1 : 0)
                   + (ModelUsageService.geminiEnabled ? 1 : 0) > 1,
            action: () => ModelUsageService.switchProvider()
        },
        {
            label: "Settings",
            icon: "settings.svg",
            action: () => Quickshell.execDetached(SU.ipcCall("SettingsHub", "openTab", "model-usage"))
        }
    ]

    Row {
        spacing: Appearance.spacingS

        SharedWidgets.SvgIcon {
            source: ModelUsageService.providerIcon
            color: ModelUsageService.providerColor
            size: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationMedium } }
        }
    }
}
