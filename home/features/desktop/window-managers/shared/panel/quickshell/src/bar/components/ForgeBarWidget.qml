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
    readonly property bool hasUnread: ForgeService.hasUnread
    readonly property int totalCount: ForgeService.totalUnread

    readonly property color accentColor: hasUnread ? Colors.primary : Colors.textDisabled

    tooltipText: {
        var lines = ["Forge Notifications"];
        if (Config.githubToken !== "") lines.push("GitHub: " + ForgeService.githubUnreadCount + " unread");
        if (Config.gitlabToken !== "") lines.push("GitLab: " + ForgeService.gitlabUnreadCount + " unread");
        if (Config.githubToken === "" && Config.gitlabToken === "") lines.push("No tokens configured");
        return lines.join("\n");
    }

    activeColor: Colors.withAlpha(accentColor, 0.16)
    normalColor: Colors.withAlpha(accentColor, 0.12)
    hoverColor: Colors.withAlpha(accentColor, 0.18)

    onClicked: {
        ForgeService.refresh();
    }

    contextActions: [
        {
            label: "Refresh notifications",
            icon: "arrow-clockwise.svg",
            action: () => ForgeService.refresh()
        },
        {
            separator: true
        },
        {
            label: "Open GitHub",
            icon: "brands/github-symbolic.svg",
            visible: Config.githubToken !== "",
            action: () => Quickshell.execDetached(["xdg-open", "https://github.com/notifications"])
        },
        {
            label: "Open GitLab",
            icon: "brands/gitlab.svg",
            visible: Config.gitlabToken !== "",
            action: () => Quickshell.execDetached(["xdg-open", "https://" + Config.gitlabHost + "/dashboard/todos"])
        }
    ]

    Component.onCompleted: {
        ForgeService.subscriberCount++;
    }
    Component.onDestruction: {
        ForgeService.subscriberCount--;
    }

    Row {
        spacing: Appearance.spacingXS * root.iconScale

        SharedWidgets.SvgIcon {
            source: "brands/github-symbolic.svg"
            color: root.accentColor
            size: Appearance.fontSizeMedium * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly && root.hasUnread
            text: root.totalCount
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall * root.fontScale
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
