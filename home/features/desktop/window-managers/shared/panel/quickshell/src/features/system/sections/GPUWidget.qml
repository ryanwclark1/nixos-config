import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU
import "../models/SystemCardStyle.js" as SystemCardStyle

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: gpuColumn.implicitHeight + root.pad * 2
    property bool showSystemMonitorLauncher: false

    property string vramUsage: "0 / 0 MB"
    property real vramPercent: 0.0
    /// No mem_info_vram_* sysfs (typical Intel iGPU unified memory) — not "missing VRAM".
    property bool vramIsUnified: false
    property var gpuHistory: []
    property bool showProcesses: false

    SharedWidgets.Ref { service: SystemStatus }
    SharedWidgets.Ref { service: AMDGPUService }

    Component.onCompleted: gpuHistory = SystemStatus.gpuHistory.slice(-30)

    Connections {
        target: SystemStatus
        function onGpuHistoryChanged() {
            root.gpuHistory = SystemStatus.gpuHistory.slice(-30);
            gpuSparkline.requestRepaint();
        }
    }

    readonly property int _vramPollMs: 5000

    CommandPoll {
        id: vramPoll
        interval: root._vramPollMs
        running: root.visible && !AMDGPUService.available && SystemStatus.gpuCardName !== ""
        command: ["sh", "-c",
            "gpu_card=\"$1\"; "
            + "[ -z \"$gpu_card\" ] && exit 0; "
            + "gpu_path=\"/sys/class/drm/$gpu_card/device\"; "
            + "[ -r \"$gpu_path/mem_info_vram_used\" ] && [ -r \"$gpu_path/mem_info_vram_total\" ] "
            + "&& cat \"$gpu_path/mem_info_vram_used\" \"$gpu_path/mem_info_vram_total\" 2>/dev/null | awk '{print $1}'",
            "qs-gpu-vram",
            SystemStatus.gpuCardName
        ]
        parse: function(out) {
            var lines = String(out || "").trim().split("\n");
            if (lines.length >= 2) {
                var used = (parseInt(lines[0], 10) || 0) / 1024 / 1024;
                var total = (parseInt(lines[1], 10) || 0) / 1024 / 1024;
                if (total > 0) {
                    return {
                        usage: Math.round(used) + " / " + Math.round(total) + " MB",
                        percent: used / total,
                        unified: false
                    };
                }
            }
            return { usage: root.vramUsage, percent: 0, unified: true };
        }
        onUpdated: {
            root.vramIsUnified = vramPoll.value.unified;
            if (!vramPoll.value.unified) {
                root.vramUsage = vramPoll.value.usage;
                root.vramPercent = vramPoll.value.percent;
            }
        }
    }

    readonly property color usageColor: SystemCardStyle.usageTierColor(
        SystemStatus.gpuPercent, Colors.secondary, Colors.warning, Colors.error, 0.7, 0.9)

    ColumnLayout {
        id: gpuColumn
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SystemSectionTitle {
                title: AMDGPUService.available ? "AMD GPU" : "GPU"
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                visible: AMDGPUService.available ? AMDGPUService.powerWatts > 0 : false
                icon: "flash-on.svg"
                text: AMDGPUService.powerWatts + "W"
                textColor: Colors.textSecondary
            }

            SharedWidgets.Chip {
                visible: SystemStatus.gpuTemp !== "--"
                icon: "board.svg"
                iconColor: SystemStatus.gpuTempNum > 85 ? Colors.error : Colors.textSecondary
                text: SystemStatus.gpuTemp
                textColor: SystemStatus.gpuTempNum > 85 ? Colors.error : Colors.textSecondary
            }

            SharedWidgets.IconButton {
                visible: AMDGPUService.available
                icon: IconHelpers.gpuProcessToggleIcon(root.showProcesses)
                size: Appearance.iconSizeSmall
                iconSize: Appearance.fontSizeSmall
                tooltipText: root.showProcesses ? "Hide GPU processes" : "Show GPU processes"
                onClicked: root.showProcesses = !root.showProcesses
            }

            SystemMonitorLaunchButton {
                visible: root.showSystemMonitorLauncher
            }
        }

        // Main stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingL

            ResourceGauge {
                value: SystemStatus.gpuPercent
                color: root.usageColor
                icon: "board.svg"
                label: SystemStatus.gpuUsage
            }

            // Core stats column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Core Load"
                    value: SystemStatus.gpuUsage
                    valueColor: root.usageColor
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "VRAM"
                    value: AMDGPUService.available
                        ? (MU.formatBytes(AMDGPUService.vramUsageBytes) + " / " + MU.formatBytes(AMDGPUService.vramTotalBytes))
                        : (root.vramIsUnified ? "Unified with system RAM" : root.vramUsage)
                }

                SharedWidgets.MiniProgressBar {
                    visible: AMDGPUService.available || !root.vramIsUnified
                    value: AMDGPUService.available ? AMDGPUService.vramPercent : root.vramPercent
                    barColor: Colors.primary
                }
            }
        }

        // Advanced AMD Stats
        GridLayout {
            visible: AMDGPUService.available
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Appearance.spacingM
            rowSpacing: Appearance.spacingXS
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXXS
                Text { text: "Graphics Engine"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXXS; font.weight: Font.Bold }
                SharedWidgets.MiniProgressBar { value: AMDGPUService.gfxUsage; barColor: Colors.secondary }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXXS
                Text { text: "Memory Controller"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXXS; font.weight: Font.Bold }
                SharedWidgets.MiniProgressBar { value: AMDGPUService.memUsage; barColor: Colors.accent }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXXS
                Text { text: "Media Engine"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXXS; font.weight: Font.Bold }
                SharedWidgets.MiniProgressBar { value: AMDGPUService.mediaUsage; barColor: Colors.success }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS
                SharedWidgets.InfoRow { label: "Fan"; value: AMDGPUService.fanRpm + " RPM"; Layout.fillWidth: true }
            }
        }

        SparklineSection {
            id: gpuSparkline
            history: root.gpuHistory
            accentColor: root.usageColor
            canvasHeight: 40
            currentText: root.gpuHistory.length > 0
                ? Math.round((root.gpuHistory[root.gpuHistory.length - 1] || 0) * 100) + "%" : ""
        }
        
        // GPU Processes list (Top 3)
        ColumnLayout {
            visible: root.showProcesses && AMDGPUService.available
            Layout.fillWidth: true
            spacing: Appearance.spacingXS
            
            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.3 }
            
            Text {
                text: "TOP GPU PROCESSES"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Bold
                font.letterSpacing: Appearance.letterSpacingWide
            }
            
            Repeater {
                model: {
                    var items = [];
                    for (var pid in AMDGPUService.processGpuUsage) {
                        var p = AMDGPUService.processGpuUsage[pid];
                        if (p.gfx > 0 || p.vram > 1024*1024) {
                            items.push({ pid: pid, name: p.name, gfx: p.gfx, vram: p.vram });
                        }
                    }
                    items.sort((a, b) => b.gfx - a.gfx || b.vram - a.vram);
                    return items.slice(0, 3);
                }
                
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    
                    Text {
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: modelData.gfx + "%"
                        color: Colors.secondary
                        font.pixelSize: Appearance.fontSizeSmall
                        font.family: Appearance.fontMono
                        font.weight: Font.Bold
                    }
                    
                    Text {
                        text: MU.formatBytes(modelData.vram)
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXXS
                        font.family: Appearance.fontMono
                    }
                }
            }
            
            Text {
                visible: Object.keys(AMDGPUService.processGpuUsage).length === 0
                text: "No GPU activity detected"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
                font.italic: true
            }
        }
    }
}
