import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

Item {
    id: root
    property var widgetInstance: null
    required property var anchorWindow
    property bool vertical: false

    property string updatesIcon: "󰚰"
    property string updatesCount: "0"
    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)

    visible: updatesCount !== "0" && updatesCount !== ""
    implicitWidth: visible ? updatesPill.width : 0
    implicitHeight: visible ? updatesPill.height : 0

    readonly property int _cacheReadIntervalMs: 600000  // 10 min

    CommandPoll {
        id: updatePoll
        interval: root._cacheReadIntervalMs
        running: true
        command: ["sh", "-c", "nix=$(cat \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updates/nixos\" 2>/dev/null || echo 0); " + "flat=$(cat \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updates/flatpak\" 2>/dev/null || echo 0); " + "total=$(( (nix > 0 ? nix : 0) + (flat > 0 ? flat : 0) )); " + "echo $total"]
        parse: function (out) {
            return parseInt(String(out || "").trim(), 10) || 0;
        }
        onUpdated: {
            var count = updatePoll.value || 0;
            root.updatesCount = count > 0 ? count.toString() : "0";
            root.updatesIcon = count > 0 ? "󰮯" : "󰚰";
        }
    }

    SharedWidgets.BarPill {
        id: updatesPill
        visible: root.visible
        anchors.centerIn: parent
        anchorWindow: root.anchorWindow
        tooltipText: "System updates"

        Row {
            spacing: Colors.spacingXS
            Text {
                text: root.updatesIcon
                color: Colors.accent
                font.pixelSize: Colors.fontSizeXL
                font.family: Colors.fontMono
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: !root.iconOnly
                text: root.updatesCount
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
