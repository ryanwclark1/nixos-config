import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false

    visible: GameModeService.active
    tooltipText: "Game Mode active — performance profile, idle inhibit, effects disabled"

    normalColor: Colors.withAlpha(Colors.warning, 0.15)
    hoverColor: Colors.withAlpha(Colors.warning, 0.22)

    onClicked: GameModeService.toggle()
    contextActions: [
        {
            label: "Deactivate Game Mode",
            icon: "󰊴",
            danger: true,
            action: () => GameModeService.deactivate()
        }
    ]

    SharedWidgets.SvgIcon {
        anchors.centerIn: parent
        color: Colors.warning
        size: Appearance.fontSizeLarge
        source: "games.svg"
    }
}
