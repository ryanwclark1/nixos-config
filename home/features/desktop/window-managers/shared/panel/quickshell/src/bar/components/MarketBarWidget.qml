import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false
    signal triggerRequested(var triggerItem)

    SharedWidgets.Ref { service: MarketService }

    readonly property var firstSymbol: (MarketService.marketData && MarketService.marketData.length > 0) ? MarketService.marketData[0] : null
    
    tooltipText: firstSymbol ? (firstSymbol.symbol + ": " + firstSymbol.close) : "Markets"
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Refresh Now",
            icon: "󰑓",
            action: () => MarketService.refresh()
        },
        {
            label: "Open Markets Menu",
            icon: "󱓗",
            action: () => root.triggerRequested(root)
        }
    ]

    Row {
        spacing: Appearance.spacingS

        Text {
            text: "󱓗"
            color: Colors.accent
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical) && !!firstSymbol
            text: firstSymbol ? firstSymbol.close : "--"
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
