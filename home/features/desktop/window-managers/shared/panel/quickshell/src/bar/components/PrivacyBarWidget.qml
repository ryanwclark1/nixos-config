import QtQuick
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root

    property var widgetInstance: null
    property bool vertical: false
    signal triggerRequested(var triggerItem)

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property bool showPulseDot: PanelHelpers.widgetSettings(widgetInstance).showPulseDot !== false

    visible: PrivacyService.anyActive
    activeColor: Colors.withAlpha(Colors.warning, 0.22)
    normalColor: Colors.withAlpha(Colors.warning, 0.15)
    hoverColor: Colors.withAlpha(Colors.warning, 0.28)
    tooltipText: PrivacyService.activeLabel || "Privacy"
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Open Privacy Menu",
            icon: "shield.svg",
            action: () => root.triggerRequested(root)
        }
    ]

    Behavior on width {
        Anim {}
    }

    Item {
        width: 0
        height: 0
        visible: false
        SharedWidgets.Ref {
            service: PrivacyService
        }
    }

    Row {
        spacing: Appearance.spacingXS

        Rectangle {
            visible: root.showPulseDot
            width: 7
            height: 7
            radius: width / 2
            color: Colors.warning
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
                running: PrivacyService.anyActive
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 0.25
                    duration: Appearance.durationPulse
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 0.25
                    to: 1.0
                    duration: Appearance.durationPulse
                    easing.type: Easing.InOutSine
                }
            }
        }

        SharedWidgets.SvgIcon {
            source: PrivacyService.activeIcon
            color: Colors.warning
            size: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly
            text: PrivacyService.activeLabel || "Privacy"
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
