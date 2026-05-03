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

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property var powerAction: SystemActionRegistry.actionById("powerMenu")

    tooltipText: "System power and session controls"
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Lock Screen",
            icon: "lock-closed.svg",
            action: () => SystemActionRegistry.execute("lock")
        },
        {
            separator: true
        },
        {
            label: "Logout",
            icon: "arrow-enter-left.svg",
            action: () => SystemActionRegistry.execute("logout")
        },
        {
            label: "Reboot",
            icon: "arrow-counterclockwise.svg",
            danger: true,
            action: () => SystemActionRegistry.execute("reboot")
        },
        {
            label: "Shutdown",
            icon: "power.svg",
            danger: true,
            action: () => SystemActionRegistry.execute("shutdown")
        }
    ]

    Row {
        spacing: Appearance.spacingS * root.iconScale

        SharedWidgets.SvgIcon {
            source: "power.svg"
            color: Colors.error
            size: Appearance.fontSizeIcon * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly
            text: "Power"
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
