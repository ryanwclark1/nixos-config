import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
    id: root

    property var widgetInstance: null
    property var anchorWindow: null
    property bool vertical: false

    signal contextMenuRequested(var actions, var triggerRect)

    visible: NightLightService.active
    tooltipText: "Night Light — " + NightLightService.temperature + "K"

    normalColor: Colors.withAlpha(Colors.warning, 0.12)
    hoverColor: Colors.withAlpha(Colors.warning, 0.2)

    onClicked: NightLightService.toggle()
    contextActions: [
        {
            label: "Disable Night Light",
            icon: "󰌵",
            action: () => NightLightService.toggle()
        }
    ]
    onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

    Text {
        anchors.centerIn: parent
        color: Colors.warning
        font.pixelSize: Colors.fontSizeLarge
        font.family: Colors.fontMono
        text: "󰌵"
    }
}
