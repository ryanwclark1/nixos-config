import QtQuick
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property string serviceName: PanelHelpers.widgetStringSetting(widgetInstance, "serviceName", "syncthing.service")
    readonly property string scope: PanelHelpers.widgetStringSetting(widgetInstance, "scope", "user", ["user", "system"])
    readonly property string customLabel: PanelHelpers.widgetStringSetting(widgetInstance, "label", "")
    readonly property string customIcon: PanelHelpers.widgetStringSetting(widgetInstance, "icon", "settings.svg")

    readonly property var unit: {
        var units = scope === "system" ? ServiceUnitService.systemUnits : ServiceUnitService.userUnits;
        for (var i = 0; i < units.length; i++) {
            if (units[i].name === serviceName) return units[i];
        }
        return null;
    }

    readonly property string activeState: unit ? unit.active : "inactive"
    readonly property string subState: unit ? unit.sub : "dead"
    readonly property bool isRunning: activeState === "active"
    readonly property bool isFailed: activeState === "failed" || subState === "failed"

    readonly property color accentColor: {
        if (isFailed) return Colors.error;
        if (isRunning) return Colors.success;
        return Colors.textDisabled;
    }

    tooltipText: "Service: " + serviceName + "\nStatus: " + activeState + " (" + subState + ")"
    activeColor: Colors.withAlpha(accentColor, 0.16)
    normalColor: Colors.withAlpha(accentColor, 0.12)
    hoverColor: Colors.withAlpha(accentColor, 0.18)

    onClicked: {
        if (isRunning) ServiceUnitService.restartUnit(scope, serviceName);
        else ServiceUnitService.startUnit(scope, serviceName);
    }

    contextActions: [
        {
            label: isRunning ? "Restart " + serviceName : "Start " + serviceName,
            icon: isRunning ? "arrow-clockwise.svg" : "play.svg",
            action: () => {
                if (isRunning) ServiceUnitService.restartUnit(scope, serviceName);
                else ServiceUnitService.startUnit(scope, serviceName);
            }
        },
        {
            label: "Stop " + serviceName,
            icon: "stop.svg",
            visible: isRunning,
            action: () => ServiceUnitService.stopUnit(scope, serviceName)
        },
        {
            separator: true
        },
        {
            label: "View logs",
            icon: "list.svg",
            action: () => ServiceUnitService.openUnitLogsInTerminal(scope, serviceName)
        }
    ]

    Component.onCompleted: {
        ServiceUnitService.subscriberCount++;
    }
    Component.onDestruction: {
        ServiceUnitService.subscriberCount--;
    }

    Row {
        spacing: Appearance.spacingXS * root.iconScale

        SharedWidgets.SvgIcon {
            source: root.customIcon
            color: root.accentColor
            size: Appearance.fontSizeMedium * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly
            text: root.customLabel !== "" ? root.customLabel : serviceName.replace(".service", "")
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
