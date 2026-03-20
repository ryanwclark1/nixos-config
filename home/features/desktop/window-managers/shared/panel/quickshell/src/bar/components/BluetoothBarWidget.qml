import QtQuick
import Quickshell.Bluetooth
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false
    signal triggerRequested(var triggerItem)

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property int connectedCount: {
        if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled)
            return 0;
        var count = 0;
        for (var i = 0; i < Bluetooth.devices.values.length; i++) {
            if (Bluetooth.devices.values[i].connected)
                count++;
        }
        return count;
    }

    tooltipText: {
        if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled)
            return "Bluetooth off";
        return connectedCount > 0 ? connectedCount + " device" + (connectedCount > 1 ? "s" : "") + " connected" : "Bluetooth";
    }
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? "Disable Bluetooth" : "Enable Bluetooth",
            icon: "󰂯",
            action: () => {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
            }
        },
        {
            separator: true
        },
        {
            label: "Open Bluetooth Menu",
            icon: "󰂯",
            action: () => root.triggerRequested(root)
        }
    ]

    Row {
        spacing: Appearance.spacingS

        Text {
            text: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? "󰂯" : "󰂲"
            color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Colors.primary : Colors.textDisabled
            font.family: Appearance.fontMono
            font.pixelSize: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly
            text: {
                if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled)
                    return "Off";
                return root.connectedCount > 0 ? String(root.connectedCount) : "On";
            }
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
