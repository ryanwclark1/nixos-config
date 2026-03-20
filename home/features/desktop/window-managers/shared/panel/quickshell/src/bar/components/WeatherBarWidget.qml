import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false
    signal triggerRequested(var triggerItem)

    SharedWidgets.Ref { service: WeatherService }

    tooltipText: (WeatherService.condition || "Weather") + (WeatherService.aqi !== "--" ? " · AQI " + WeatherService.aqi : "")
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Refresh Now",
            icon: "󰑓",
            action: () => WeatherService.refresh()
        },
        {
            label: "Open Weather Menu",
            icon: "󰖐",
            action: () => root.triggerRequested(root)
        }
    ]

    Row {
        spacing: Appearance.spacingS

        Text {
            text: Appearance.weatherIcon(WeatherService.condition)
            color: Colors.accent
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical)
            text: WeatherService.temp
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
