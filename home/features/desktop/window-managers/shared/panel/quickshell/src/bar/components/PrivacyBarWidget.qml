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

    visible: PrivacyService.anyActive
    isActive: root.isActive
    anchorWindow: root.anchorWindow
    activeColor: Colors.withAlpha(Colors.warning, 0.22)
    normalColor: Colors.withAlpha(Colors.warning, 0.15)
    hoverColor: Colors.withAlpha(Colors.warning, 0.28)
    tooltipText: PrivacyService.activeLabel || "Privacy"
    onClicked: root.clicked(this)
    contextActions: [
        {
            label: "Open Privacy Menu",
            icon: "󰒃",
            action: () => root.clicked(root)
        }
    ]
    onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

    Behavior on width {
        NumberAnimation {
            duration: Colors.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    Row {
        spacing: Colors.spacingXS

        Rectangle {
            visible: root.showPulseDot
            width: 7
            height: 7
            radius: 3.5
            color: Colors.warning
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
                running: PrivacyService.anyActive
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 0.25
                    duration: Colors.durationPulse
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 0.25
                    to: 1.0
                    duration: Colors.durationPulse
                    easing.type: Easing.InOutSine
                }
            }
        }

        Text {
            text: PrivacyService.activeIcon
            color: Colors.warning
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly
            text: PrivacyService.activeLabel || "Privacy"
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
