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

    readonly property string displayMode: PanelHelpers.widgetStringSetting(widgetInstance, "displayMode", "auto", ["auto", "full", "icon"])
    readonly property bool iconOnly: displayMode === "icon" ? true : (displayMode === "full" ? false : vertical)
    readonly property bool showPulseDot: PanelHelpers.widgetSettings(widgetInstance).showPulseDot !== false

    visible: SystemStatus.isRecording
    isActive: root.isActive
    anchorWindow: root.anchorWindow
    activeColor: Colors.withAlpha(Colors.error, 0.22)
    normalColor: Colors.withAlpha(Colors.error, 0.15)
    hoverColor: Colors.withAlpha(Colors.error, 0.25)
    tooltipText: "Screen recording in progress"
    onClicked: root.clicked(this)
    contextActions: [
        {
            label: "Stop Recording",
            icon: "󰙧",
            danger: true,
            action: () => RecordingService.stopRecording()
        }
    ]
    onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

    Row {
        spacing: Colors.spacingS

        Rectangle {
            visible: root.showPulseDot
            width: 8
            height: 8
            radius: 4
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
