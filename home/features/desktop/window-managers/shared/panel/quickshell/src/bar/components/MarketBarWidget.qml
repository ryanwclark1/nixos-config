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
            icon: "arrow-counterclockwise.svg",
            action: () => MarketService.refresh()
        },
        {
            label: "Open Markets Menu",
            icon: "data-trending.svg",
            action: () => root.triggerRequested(root)
        }
    ]

    Row {
        spacing: Appearance.spacingS * root.iconScale

        SharedWidgets.SvgIcon {
            source: "data-trending.svg"
            color: Colors.accent
            size: Appearance.fontSizeLarge * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical) && !!firstSymbol
            text: firstSymbol ? firstSymbol.close : "--"
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
