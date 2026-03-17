import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    required property var anchorWindow
    property bool vertical: false
    property bool isActive: false
    signal clicked(var triggerItem)
    signal contextMenuRequested(var actions, rect triggerRect)

    isActive: root.isActive
    anchorWindow: root.anchorWindow
    tooltipText: WeatherService.condition || "Weather"
    onClicked: root.clicked(this)
    contextActions: [
        {
            label: "Refresh Now",
            icon: "󰑓",
            action: () => WeatherService.refresh()
        },
        {
            label: "Open Weather Menu",
            icon: "󰖐",
            action: () => root.clicked(root)
        }
    ]
    onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

    Row {
        spacing: Colors.spacingS

        Text {
            text: Colors.weatherIcon(WeatherService.condition)
            color: Colors.accent
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PanelHelpers.isSummaryWidgetFull(widgetInstance, vertical)
            text: WeatherService.temp
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
