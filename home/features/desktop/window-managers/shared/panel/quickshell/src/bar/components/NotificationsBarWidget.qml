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
    property var manager: null
    signal clicked(var triggerItem)
    signal contextMenuRequested(var actions, rect triggerRect)

    readonly property bool hasDnd: !!(manager && manager.dndEnabled)
    readonly property bool hasUnread: !!(manager && manager.notifications && manager.notifications.count > 0)
    readonly property int unreadCount: (manager && manager.notifications) ? Math.max(0, Number(manager.notifications.count) || 0) : 0
    readonly property string displayMode: PanelHelpers.widgetStringSetting(widgetInstance, "displayMode", "auto", ["auto", "full", "icon"])
    readonly property string badgeStyle: PanelHelpers.widgetStringSetting(widgetInstance, "badgeStyle", "dot", ["dot", "count", "off"])
    readonly property bool iconOnly: displayMode === "icon" ? true : (displayMode === "full" ? false : vertical)

    isActive: root.isActive
    anchorWindow: root.anchorWindow
    tooltipText: manager && manager.dndEnabled ? "Notifications paused" : "Notifications"
    onClicked: root.clicked(this)
    contextActions: [
        {
            label: (manager && manager.dndEnabled) ? "Disable DND" : "Enable DND",
            icon: "󰂛",
            action: () => {
                if (manager)
                    manager.dndEnabled = !manager.dndEnabled;
            }
        },
        {
            label: "Clear All",
            icon: "󰎟",
            action: () => {
                if (manager && manager.notifications)
                    manager.notifications.clear();
            }
        },
        {
            separator: true
        },
        {
            label: "Open Notifications",
            icon: "󰂚",
            action: () => root.clicked(root)
        }
    ]
    onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

    Row {
        spacing: Colors.spacingXS

        Text {
            color: Colors.text
            font.pixelSize: Colors.fontSizeXL
            font.family: Colors.fontMono
            text: root.hasDnd ? "󰂛" : "󰂚"
        }

        Text {
            visible: !root.iconOnly && root.hasDnd
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            text: "DND"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !root.iconOnly && !root.hasDnd && root.hasUnread && root.badgeStyle === "count"
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            text: String(root.unreadCount)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Rectangle {
        parent: root
        width: root.badgeStyle === "count" ? Math.max(14, unreadBadgeText.implicitWidth + 8) : 8
        height: 8
        radius: 4
        color: Colors.error
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        visible: root.hasUnread && !root.hasDnd && root.badgeStyle !== "off" && root.iconOnly
        z: 10

        Text {
            id: unreadBadgeText
            anchors.centerIn: parent
            visible: root.badgeStyle === "count"
            text: String(root.unreadCount)
            color: Colors.text
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
        }
    }
}
