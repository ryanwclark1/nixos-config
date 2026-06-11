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

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)

    tooltipText: ModelUsageService.displayTooltip
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Refresh Now",
            icon: "arrow-counterclockwise.svg",
            action: () => ModelUsageService.refresh()
        },

        {
            label: "Settings",
            icon: "settings.svg",
            action: () => Quickshell.execDetached(SU.ipcCall("SettingsHub", "openTab", "model-usage"))
        }
    ]

    Row {
        spacing: Appearance.spacingS * root.iconScale

        SharedWidgets.SvgIcon {
            source: root.iconOnly ? ModelUsageService.providerIcon : "board.svg"
            color: ModelUsageService.providerColor
            size: Appearance.fontSizeLarge * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly
            text: ModelUsageService.formatTokenCount(ModelUsageService.todayPrompts)
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
