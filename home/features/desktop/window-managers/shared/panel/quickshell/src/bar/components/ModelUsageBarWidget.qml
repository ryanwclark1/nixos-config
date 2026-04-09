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
            label: "Settings",
            icon: "settings.svg",
            action: () => Quickshell.execDetached(SU.ipcCall("SettingsHub", "openTab", "model-usage"))
        }
    ]

    Row {
        spacing: Appearance.spacingS

        SharedWidgets.SvgIcon {
            visible: ModelUsageService.claudeEnabled
            source: "brands/anthropic-symbolic.svg"
            color: "#cc785c"
            size: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        SharedWidgets.SvgIcon {
            visible: ModelUsageService.codexEnabled
            source: "brands/openai-symbolic.svg"
            color: "#22c55e"
            size: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        SharedWidgets.SvgIcon {
            visible: ModelUsageService.geminiEnabled
            source: "brands/google-gemini-symbolic.svg"
            color: "#4285F4"
            size: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
