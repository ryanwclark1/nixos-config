import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false
    signal triggerRequested(var triggerItem)

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property bool showPulseDot: PanelHelpers.widgetSettings(widgetInstance).showPulseDot !== false

    visible: SystemStatus.isRecording
    activeColor: Colors.withAlpha(Colors.error, 0.22)
    normalColor: Colors.errorLight
    hoverColor: Colors.withAlpha(Colors.error, 0.25)
    tooltipText: "Screen recording in progress"
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Stop Recording",
            icon: "󰙧",
            danger: true,
            action: () => RecordingService.stopRecording()
        }
    ]
    Row {
        spacing: Colors.spacingS

        Rectangle {
            visible: root.showPulseDot
            width: 8
            height: 8
            radius: width / 2
            color: Colors.error
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
                running: SystemStatus.isRecording
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 0.3
                    duration: Colors.durationPulse
                }
                NumberAnimation {
                    from: 0.3
                    to: 1.0
                    duration: Colors.durationPulse
                }
            }
        }

        Text {
            visible: !root.iconOnly
            text: "REC"
            color: Colors.error
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
