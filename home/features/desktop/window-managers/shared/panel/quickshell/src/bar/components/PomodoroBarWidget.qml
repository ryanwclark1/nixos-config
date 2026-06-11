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
            icon: PomodoroService.running ? "pause.svg" : "play.svg",
            action: () => PomodoroService.toggle()
        },
        {
            label: "Skip",
            icon: "next.svg",
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
        spacing: Appearance.spacingXS * root.iconScale

        SharedWidgets.SvgIcon {
            color: PomodoroService.isBreak ? Colors.success : Colors.primary
            size: Appearance.fontSizeLarge * root.iconScale
            source: PomodoroService.running ? "timer.svg" : "timer-off.svg"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: PomodoroService.running && !root.vertical
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            font.family: Appearance.fontMono
            text: PomodoroService.timeDisplay
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
