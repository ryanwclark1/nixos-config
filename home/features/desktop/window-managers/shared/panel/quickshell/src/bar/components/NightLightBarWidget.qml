import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
    id: root

    property var widgetInstance: null
    property var anchorWindow: null
    property bool vertical: false

    visible: NightLightService.active
    tooltipText: "Night Light — " + NightLightService.temperature + "K"

    normalColor: Colors.withAlpha(Colors.warning, 0.12)
    hoverColor: Colors.withAlpha(Colors.warning, 0.2)

    onClicked: NightLightService.toggle()
    contextActions: [
        {
            label: "Disable Night Light",
            icon: "lightbulb.svg",
            action: () => NightLightService.toggle()
        }
    ]
    SharedWidgets.SvgIcon {
        anchors.centerIn: parent
        color: Colors.warning
        size: Appearance.fontSizeLarge
        source: "weather-moon.svg"
    }
}
