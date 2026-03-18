import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../menu"
import "../sections"
import "../../../services"
import "../../../widgets" as SharedWidgets

BasePopupMenu {
    id: root
    popupMinWidth: 360
    popupMaxWidth: 460
    compactThreshold: 420
    implicitHeight: compactMode ? 620 : 580
    title: "System"
    subtitle: compactMode ? "Actions first" : "Processes, services, and live telemetry"
    focusOnOpen: true

    headerExtras: SharedWidgets.IconButton {
        icon: "󰄨"
        size: 30
        iconSize: Colors.fontSizeLarge
        iconColor: Colors.primary
        onClicked: {
            root.closeRequested();
            Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "systemMonitor"]);
        }
    }

    Loader {
        active: root.visible
        sourceComponent: SharedWidgets.Ref {
            service: SystemStatus
        }
    }
    Loader {
        active: root.visible
        sourceComponent: SharedWidgets.Ref {
            service: ProcessService
        }
    }
    Loader {
        active: root.visible
        sourceComponent: SharedWidgets.Ref {
            service: ServiceUnitService
        }
    }

    // Scrollable module area
    SharedWidgets.ScrollableContent {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: Colors.paddingSmall

        SharedWidgets.SectionLabel {
            label: "ACTIONS"
        }

        ProcessWidget {
            compactMode: root.compactMode
        }
        ServiceUnitWidget {
            compactMode: root.compactMode
        }

        SharedWidgets.SectionLabel {
            label: "TELEMETRY"
        }

        CpuWidget {}
        RamWidget {}
        GPUWidget {}
        DiskWidget {}
        NetworkGraphs {}
    }
}
