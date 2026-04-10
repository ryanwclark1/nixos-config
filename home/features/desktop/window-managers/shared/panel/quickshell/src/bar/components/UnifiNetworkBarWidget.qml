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
        if (UnifiNetworkService.status === "unconfigured") return "UniFi Network — not configured";
        if (UnifiNetworkService.status === "error") return "UniFi Network — " + UnifiNetworkService.errorMessage;
        return "UniFi Network — " + UnifiNetworkService.onlineDevices + "/" + UnifiNetworkService.totalDevices + " devices online";
    }
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Refresh",
            icon: "arrow-counterclockwise.svg",
            action: () => UnifiNetworkService.refresh()
        },
        {
            label: "Open UniFi Network Menu",
            icon: "brands/ubiquiti-symbolic.svg",
            action: () => root.triggerRequested(root)
        }
    ]

    Row {
        spacing: Appearance.spacingS

        SharedWidgets.SvgIcon {
            source: "brands/ubiquiti-symbolic.svg"
            color: UnifiNetworkService.status === "ready" ? Colors.text : Colors.textDisabled
            size: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical) && UnifiNetworkService.status === "ready"
            text: UnifiNetworkService.onlineDevices + "/" + UnifiNetworkService.totalDevices
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
