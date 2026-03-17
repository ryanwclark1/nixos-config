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

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property int maxTextWidth: PanelHelpers.widgetIntegerSetting(widgetInstance, "maxTextWidth", 100, 60, 220)

    visible: SystemStatus.hasActivePlayer
    isActive: root.isActive
    anchorWindow: root.anchorWindow
    tooltipText: {
        var players = SystemStatus.activeMprisPlayers;
        if (!players || players.length === 0)
            return "Music controls";
        var p = players[0];
        return (p.trackTitle || "Music") + (p.trackArtist ? " - " + p.trackArtist : "");
    }
    onClicked: root.clicked(this)
    contextActions: [
        {
            label: "Play / Pause",
            icon: "󰐊",
            action: () => {
                var p = SystemStatus.activeMprisPlayers;
                if (p && p.length > 0 && p[0].player)
                    p[0].player.playPause();
            }
        },
        {
            label: "Next Track",
            icon: "󰒭",
            action: () => {
                var p = SystemStatus.activeMprisPlayers;
                if (p && p.length > 0 && p[0].player)
                    p[0].player.next();
            }
        },
        {
            separator: true
        },
        {
            label: "Open Music Menu",
            icon: "󰝚",
            action: () => root.clicked(root)
        }
    ]
    onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

    Behavior on width {
        NumberAnimation {
            duration: Colors.durationSlow
            easing.type: Easing.OutCubic
        }
    }

    Row {
        spacing: Colors.spacingS

        Text {
            text: "󰝚"
            color: Colors.primary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            visible: !root.iconOnly
            width: visible ? Math.min(musicTitleText.contentWidth, root.maxTextWidth) : 0
            height: 20
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: musicTitleText
                text: SystemStatus.activeMprisPlayers.length > 0 ? (SystemStatus.activeMprisPlayers[0].trackTitle || "") : ""
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
