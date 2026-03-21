import QtQuick
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

SharedWidgets.BarPill {
    id: root

    property var widgetInstance: null
    property bool vertical: false
    signal triggerRequested(var triggerItem)

    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)
    readonly property string badgeStyle: PanelHelpers.widgetStringSetting(widgetInstance, "badgeStyle", "count", ["count", "dot", "off"])

    visible: PrinterService.hasPrinters
    tooltipText: PrinterService.activeJobs > 0 ? PrinterService.activeJobs + " print job" + (PrinterService.activeJobs !== 1 ? "s" : "") + " active" : (PrinterService.defaultPrinter ? PrinterService.defaultPrinter : "Printers")
    onClicked: root.triggerRequested(this)
    contextActions: [
        {
            label: "Open Printer Menu",
            icon: "print.svg",
            action: () => root.triggerRequested(root)
        }
    ]

    Behavior on width {
        Anim {}
    }

    Item {
        width: 0
        height: 0
        visible: false
        SharedWidgets.Ref {
            service: PrinterService
        }
    }

    Row {
        spacing: Appearance.spacingXS

        SharedWidgets.SvgIcon {
            source: "print.svg"
            color: PrinterService.activeJobs > 0 ? Colors.warning : Colors.text
            size: Appearance.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color {
                enabled: !Colors.isTransitioning
                ColorAnimation {
                    duration: Appearance.durationNormal
                }
            }
        }

        Rectangle {
            visible: PrinterService.activeJobs > 0 && !root.iconOnly && root.badgeStyle !== "off"
            width: root.badgeStyle === "count" ? printerJobsBadge.contentWidth + 8 : 8
            height: 16
            radius: root.badgeStyle === "count" ? Appearance.radiusXS : 4
            color: Colors.withAlpha(Colors.warning, 0.20)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: printerJobsBadge
                anchors.centerIn: parent
                text: PrinterService.activeJobs
                color: Colors.warning
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Bold
                visible: root.badgeStyle === "count"
            }
        }
    }
}
