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
    readonly property int maxTextWidth: PanelHelpers.widgetIntegerSetting(widgetInstance, "maxTextWidth", 100, 60, 220)

    visible: MediaService.currentPlayer !== null
    tooltipText: {
        if (!MediaService.trackTitle)
            return "Music controls";
        return MediaService.trackTitle + (MediaService.trackArtist ? " - " + MediaService.trackArtist : "");
    }
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Play / Pause",
            icon: "play.svg",
            action: () => MediaService.playPause()
        },
        {
            label: "Next Track",
            icon: "arrow-right.svg",
            action: () => MediaService.next()
        },
        {
            separator: true
        },
        {
            label: "Open Music Menu",
            icon: "music-note-2.svg",
            action: () => root.triggerRequested(root)
        }
    ]

    Behavior on width {
        NumberAnimation {
            duration: Appearance.durationSlow
            easing.type: Easing.OutCubic
        }
    }

    Item {
        width: 0
        height: 0
        visible: false
        SharedWidgets.Ref {
            service: MediaService
        }
    }

    Row {
        spacing: Appearance.spacingS * root.iconScale

        SharedWidgets.SvgIcon {
            source: "music-note-2.svg"
            color: Colors.primary
            size: Appearance.fontSizeLarge * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            visible: !root.iconOnly
            width: visible ? Math.min(musicTitleText.contentWidth, root.maxTextWidth * root.fontScale) : 0
            height: 20 * root.iconScale
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: musicTitleText
                text: MediaService.trackTitle || ""
                color: Colors.text
                font.pixelSize: Appearance.fontSizeSmall * root.fontScale
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
