import QtQuick
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

Item {
    id: root
    property var widgetInstance: null
    required property var anchorWindow
    property bool vertical: false
    property bool isActive: false
    property real fontScale: 1.0
    property real iconScale: 1.0
    signal clicked(var triggerItem)
    signal contextMenuRequested(var actions, rect triggerRect)

    implicitWidth: dateTimePill.width
    implicitHeight: dateTimePill.height

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property bool showDate: PanelHelpers.widgetSettings(widgetInstance).showDate !== false

    SystemClock {
        id: centerClock
        precision: Config.timeShowSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    SharedWidgets.BarPill {
        id: dateTimePill
        anchors.centerIn: parent
        isActive: root.isActive
        anchorWindow: root.anchorWindow
        tooltipText: Qt.formatDateTime(centerClock.date, "dddd, MMMM d yyyy")
        fontScale: root.fontScale
        iconScale: root.iconScale
        onClicked: root.clicked(this)
        contextActions: [
            {
                label: "Copy Time",
                icon: "copy.svg",
                action: () => Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", Qt.formatDateTime(centerClock.date, "HH:mm:ss")])
            },
            {
                label: "Copy Date",
                icon: "calendar-add.svg",
                action: () => Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", Qt.formatDateTime(centerClock.date, "yyyy-MM-dd")])
            }
        ]
        onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

        SharedWidgets.SvgIcon {
            visible: root.iconOnly
            source: "clock.svg"
            color: Colors.text
            size: Appearance.fontSizeLarge * root.iconScale
        }

        Row {
            visible: !root.iconOnly
            spacing: Appearance.spacingXS * root.iconScale
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1 * root.iconScale

            Text {
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium * root.fontScale
                font.weight: Font.Bold
                text: Qt.formatDateTime(centerClock.date, Config.timeUse24Hour ? (Config.timeShowSeconds ? "HH:mm:ss" : "HH:mm") : (Config.timeShowSeconds ? "hh:mm:ss AP" : "hh:mm AP"))
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: root.showDate && Config.timeShowBarDate
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeSmall * root.fontScale
                font.weight: Font.Medium
                text: {
                    if (Config.timeBarDateStyle === "month_day")
                        return Qt.formatDateTime(centerClock.date, "MMM d");
                    if (Config.timeBarDateStyle === "weekday_month_day")
                        return Qt.formatDateTime(centerClock.date, "ddd MMM d");
                    return Qt.formatDateTime(centerClock.date, "ddd d");
                }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
