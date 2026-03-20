import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false

    visible: PomodoroService.running || PomodoroService.progress > 0
    tooltipText: PomodoroService.running
        ? (PomodoroService.isBreak ? "Break" : "Focus") + " — " + PomodoroService.timeDisplay
        : "Pomodoro timer"

    onClicked: PomodoroService.toggle()
    contextActions: [
        {
            label: PomodoroService.running ? "Pause" : "Start",
            icon: PomodoroService.running ? "󰏤" : "󰐊",
            action: () => PomodoroService.toggle()
        },
        {
            label: "Skip",
            icon: "󰒭",
            action: () => PomodoroService.skip()
        },
        { separator: true },
        {
            label: "Reset",
            icon: "arrow-clockwise.svg",
            action: () => PomodoroService.reset()
        }
    ]

    Row {
        spacing: Colors.spacingXS

        Text {
            color: PomodoroService.isBreak ? Colors.success : Colors.primary
            font.pixelSize: Colors.fontSizeLarge
            font.family: Colors.fontMono
            text: PomodoroService.running ? "󱎫" : "󰔟"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PomodoroService.running && !root.vertical
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            font.family: Colors.fontMono
            text: PomodoroService.timeDisplay
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
