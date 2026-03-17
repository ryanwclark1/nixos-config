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

    readonly property string displayMode: PanelHelpers.widgetStringSetting(widgetInstance, "displayMode", "auto", ["auto", "full", "icon"])
    readonly property string badgeStyle: PanelHelpers.widgetStringSetting(widgetInstance, "badgeStyle", "count", ["count", "dot", "off"])
    readonly property bool iconOnly: displayMode === "icon" ? true : (displayMode === "full" ? false : vertical)

    visible: PrinterService.hasPrinters
    isActive: root.isActive
    anchorWindow: root.anchorWindow
    tooltipText: PrinterService.activeJobs > 0 ? PrinterService.activeJobs + " print job" + (PrinterService.activeJobs !== 1 ? "s" : "") + " active" : (PrinterService.defaultPrinter ? PrinterService.defaultPrinter : "Printers")
    onClicked: root.clicked(this)
    contextActions: [
        {
            label: "Open Printer Menu",
            icon: "󰐪",
            action: () => root.clicked(root)
        }
    ]
    onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)

    Behavior on width {
        NumberAnimation {
            duration: Colors.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    Row {
        spacing: Colors.spacingXS

        Text {
            text: "󰐪"
            color: PrinterService.activeJobs > 0 ? Colors.warning : Colors.text
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color {
                ColorAnimation {
                    duration: Colors.durationNormal
                }
            }
        }

        Rectangle {
            visible: PrinterService.activeJobs > 0 && !root.iconOnly && root.badgeStyle !== "off"
            width: root.badgeStyle === "count" ? printerJobsBadge.contentWidth + 8 : 8
            height: 16
            radius: root.badgeStyle === "count" ? Colors.radiusXS : 4
            color: Colors.withAlpha(Colors.warning, 0.20)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: printerJobsBadge
                anchors.centerIn: parent
                text: PrinterService.activeJobs
                color: Colors.warning
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Bold
                visible: root.badgeStyle === "count"
            }
        }
    }
}
