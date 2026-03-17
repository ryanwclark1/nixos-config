import QtQuick
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
    readonly property string tooltipTextValue: vpnWidgetLoader.status === Loader.Ready && vpnWidgetLoader.item && vpnWidgetLoader.item.tooltipText ? vpnWidgetLoader.item.tooltipText : "VPN"

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
        spacing: Colors.spacingS
        Loader {
            id: vpnWidgetLoader
            source: Qt.resolvedUrl("../../features/network/components/VpnWidget.qml")
            asynchronous: false
        }

        Binding {
            when: vpnWidgetLoader.status === Loader.Ready && !!vpnWidgetLoader.item
            target: vpnWidgetLoader.item
            property: "iconOnly"
            value: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
        }

        Binding {
            when: vpnWidgetLoader.status === Loader.Ready && !!vpnWidgetLoader.item
            target: vpnWidgetLoader.item
            property: "labelMode"
            value: root.labelMode
        }

        Binding {
            when: vpnWidgetLoader.status === Loader.Ready && !!vpnWidgetLoader.item
            target: vpnWidgetLoader.item
            property: "showOtherVpnCount"
            value: root.showOtherVpnCount
        }

        Row {
            visible: vpnWidgetLoader.status === Loader.Error
            spacing: Colors.spacingS

            Text {
                text: "󰖂"
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeLarge
                font.family: Colors.fontMono
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: !PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
                text: "VPN"
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
