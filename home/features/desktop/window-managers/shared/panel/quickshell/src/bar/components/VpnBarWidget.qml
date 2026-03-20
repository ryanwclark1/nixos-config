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
    signal networkClicked(var triggerItem)

    readonly property string labelMode: PanelHelpers.widgetStringSetting(widgetInstance, "labelMode", "status", ["status", "ip"])
    readonly property bool showOtherVpnCount: PanelHelpers.widgetBooleanSetting(widgetInstance, "showOtherVpnCount", true)
    readonly property string tooltipTextValue: vpnWidgetLoader.item && vpnWidgetLoader.item.tooltipText ? vpnWidgetLoader.item.tooltipText : "VPN"

    tooltipText: tooltipTextValue
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Open VPN Hub",
            icon: "󰖂",
            action: () => root.triggerRequested(root)
        },
        {
            label: "Open Network Menu",
            icon: "󰖩",
            action: () => root.networkClicked(root)
        }
    ]
    Row {
        spacing: Appearance.spacingS
        BoundComponent {
            id: vpnWidgetLoader
            source: Qt.resolvedUrl("../../features/network/components/VpnWidget.qml")
            property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
            property string labelMode: root.labelMode
            property bool showOtherVpnCount: root.showOtherVpnCount
        }

        Row {
            visible: !vpnWidgetLoader.item
            spacing: Appearance.spacingS

            Text {
                text: "󰖂"
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeLarge
                font.family: Appearance.fontMono
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: !PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
                text: "VPN"
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
