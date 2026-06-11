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
            icon: "arrow-counterclockwise.svg",
            action: () => WeatherService.refresh()
        },
        {
            label: "Open Weather Menu",
            icon: "weather-sunny.svg",
            action: () => root.triggerRequested(root)
        }
    ]

    Row {
        spacing: Appearance.spacingS * root.iconScale

        SharedWidgets.AnimatedWeatherIcon {
            condition: WeatherService.condition
            color: Colors.accent
            size: Appearance.fontSizeLarge * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical)
            text: WeatherService.temp
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
