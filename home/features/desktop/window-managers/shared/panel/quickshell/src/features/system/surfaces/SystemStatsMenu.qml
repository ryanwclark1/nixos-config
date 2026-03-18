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
    implicitHeight: {
        if (statKey === "gpuStatus") return compactMode ? 400 : 380;
        if (statKey === "diskStatus") return compactMode ? 420 : 400;
        if (statKey === "networkStatus") return compactMode ? 440 : 420;
        if (statKey === "cpuStatus" || statKey === "ramStatus") return compactMode ? 580 : 540;
        return compactMode ? 620 : 580;
    }
    focusOnOpen: true

    property var surfaceContext: null
    readonly property string statKey: (surfaceContext && surfaceContext.statKey) || ""
    readonly property bool showAll: statKey === ""

    title: {
        if (statKey === "cpuStatus") return "CPU";
        if (statKey === "ramStatus") return "Memory";
        if (statKey === "gpuStatus") return "GPU";
        if (statKey === "diskStatus") return "Disk";
        if (statKey === "networkStatus") return "Network";
        return "System";
    }
    subtitle: {
        if (statKey === "cpuStatus") return "Processor usage and processes";
        if (statKey === "ramStatus") return "Memory usage and processes";
        if (statKey === "gpuStatus") return "Graphics processor telemetry";
        if (statKey === "diskStatus") return "Storage usage and mount points";
        if (statKey === "networkStatus") return "Interface throughput and history";
        return compactMode ? "Actions first" : "Processes, services, and live telemetry";
    }

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
        active: root.visible && (root.showAll || root.statKey === "cpuStatus" || root.statKey === "ramStatus")
        sourceComponent: SharedWidgets.Ref {
            service: ProcessService
        }
    }
    Loader {
        active: root.visible && root.showAll
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
            visible: root.showAll || root.statKey === "cpuStatus" || root.statKey === "ramStatus"
        }

        ProcessWidget {
            visible: root.showAll || root.statKey === "cpuStatus" || root.statKey === "ramStatus"
            compactMode: root.compactMode
        }
        ServiceUnitWidget {
            visible: root.showAll
            compactMode: root.compactMode
        }

        SharedWidgets.SectionLabel {
            label: "TELEMETRY"
        }

        CpuWidget { visible: root.showAll || root.statKey === "cpuStatus" }
        RamWidget { visible: root.showAll || root.statKey === "ramStatus" }
        GPUWidget { visible: root.showAll || root.statKey === "gpuStatus" }
        DiskWidget { visible: root.showAll || root.statKey === "diskStatus" }
        NetworkGraphs { visible: root.showAll || root.statKey === "networkStatus" }
    }
}
