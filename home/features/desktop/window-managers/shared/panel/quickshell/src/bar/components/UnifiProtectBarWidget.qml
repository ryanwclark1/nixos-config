import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false
    signal triggerRequested(var triggerItem)

    visible: true
    tooltipText: {
        if (UnifiProtectService.status === "unconfigured") return "UniFi Protect — not configured";
        if (UnifiProtectService.status === "error") return "UniFi Protect — " + UnifiProtectService.errorMessage;
        return "UniFi Protect — " + UnifiProtectService.onlineCameras + "/" + UnifiProtectService.totalCameras + " cameras online";
    }
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Refresh",
            icon: "arrow-counterclockwise.svg",
            action: () => UnifiProtectService.refresh()
        },
        {
            label: "Open UniFi Protect Menu",
            icon: "brands/unifi-protect-symbolic.svg",
            action: () => root.triggerRequested(root)
        }
    ]

    Row {
        spacing: Appearance.spacingS * root.iconScale

        SharedWidgets.SvgIcon {
            source: "brands/unifi-protect-symbolic.svg"
            color: UnifiProtectService.status === "ready" ? Colors.primary : Colors.textDisabled
            size: Appearance.fontSizeIcon * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical) && UnifiProtectService.status === "ready"
            text: UnifiProtectService.onlineCameras + "/" + UnifiProtectService.totalCameras
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
