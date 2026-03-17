import QtQuick
import Quickshell.Bluetooth
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

    isActive: root.isActive
    anchorWindow: root.anchorWindow
    tooltipText: {
        if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled)
            return "Bluetooth off";
        return connectedCount > 0 ? connectedCount + " device" + (connectedCount > 1 ? "s" : "") + " connected" : "Bluetooth";
    }
    onClicked: root.clicked(this)
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
            action: () => root.clicked(root)
        }
    ]
    onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

    Row {
        spacing: Colors.spacingS

        Text {
            text: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? "󰂯" : "󰂲"
            color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Colors.primary : Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
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
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
