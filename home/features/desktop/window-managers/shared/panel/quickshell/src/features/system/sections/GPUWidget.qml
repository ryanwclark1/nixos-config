import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: gpuColumn.implicitHeight + root.pad * 2

    property string vramUsage: "0 / 0 MB"
    property real vramPercent: 0.0
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
        running: root.visible && !AMDGPUService.available
        command: ["sh", "-c",
            "gpu_card=$(for c in /sys/class/drm/card[0-9]*/device/mem_info_vram_total; do "
            + "echo \"$(cat \"$c\" 2>/dev/null || echo 0) $(dirname \"$(dirname \"$c\")\")\" ; done 2>/dev/null "
            + "| sort -rn | head -1 | awk '{print $2}'); "
            + "[ -n \"$gpu_card\" ] && cat \"$gpu_card/device/mem_info_vram_used\" \"$gpu_card/device/mem_info_vram_total\" 2>/dev/null | awk '{print $1}'"
        ]
        parse: function(out) {
            var lines = String(out || "").trim().split("\n");
            if (lines.length >= 2) {
                var used = (parseInt(lines[0], 10) || 0) / 1024 / 1024;
                var total = (parseInt(lines[1], 10) || 0) / 1024 / 1024;
                return { usage: Math.round(used) + " / " + Math.round(total) + " MB", percent: total > 0 ? (used / total) : 0 };
            }
            return { usage: root.vramUsage, percent: root.vramPercent };
        }
        onUpdated: {
            root.vramUsage = vramPoll.value.usage;
            root.vramPercent = vramPoll.value.percent;
        }
    }

    readonly property color usageColor: SystemStatus.gpuPercent >= 0.9 ? Colors.error
        : (SystemStatus.gpuPercent >= 0.7 ? Colors.warning : Colors.secondary)

    ColumnLayout {
        id: gpuColumn
        Layout.fillWidth: true
        spacing: Colors.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: AMDGPUService.available ? "AMD GPU" : "GPU"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                visible: AMDGPUService.available ? AMDGPUService.powerWatts > 0 : false
                icon: "󱐋"
                text: AMDGPUService.powerWatts + "W"
                textColor: Colors.textSecondary
            }

            SharedWidgets.Chip {
                visible: SystemStatus.gpuTemp !== "--"
                icon: "developer-board.svg"
                iconColor: SystemStatus.gpuTempNum > 85 ? Colors.error : Colors.textSecondary
                text: SystemStatus.gpuTemp
                textColor: SystemStatus.gpuTempNum > 85 ? Colors.error : Colors.textSecondary
            }
            
            SharedWidgets.IconButton {
                visible: AMDGPUService.available
                icon: root.showProcesses ? "󱗼" : "󱗻"
                size: 24
                iconSize: Colors.fontSizeSmall
                tooltipText: root.showProcesses ? "Hide GPU processes" : "Show GPU processes"
                onClicked: root.showProcesses = !root.showProcesses
            }
        }

        // Main stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingL

            ResourceGauge {
                value: SystemStatus.gpuPercent
                color: root.usageColor
                icon: "developer-board.svg"
                label: SystemStatus.gpuUsage
            }

            // Core stats column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Core Load"
                    value: SystemStatus.gpuUsage
                    valueColor: root.usageColor
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "VRAM"
                    value: AMDGPUService.available ? (MU.formatBytes(AMDGPUService.vramUsageBytes) + " / " + MU.formatBytes(AMDGPUService.vramTotalBytes)) : root.vramUsage
                }

                SharedWidgets.MiniProgressBar {
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
            columnSpacing: Colors.spacingM
            rowSpacing: Colors.spacingXS
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXXS
                Text { text: "Graphics Engine"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXXS; font.weight: Font.Bold }
                SharedWidgets.MiniProgressBar { value: AMDGPUService.gfxUsage; barColor: Colors.secondary }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXXS
                Text { text: "Memory Controller"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXXS; font.weight: Font.Bold }
                SharedWidgets.MiniProgressBar { value: AMDGPUService.memUsage; barColor: Colors.accent }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXXS
                Text { text: "Media Engine"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXXS; font.weight: Font.Bold }
                SharedWidgets.MiniProgressBar { value: AMDGPUService.mediaUsage; barColor: Colors.success }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS
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
            spacing: Colors.spacingXS
            
            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.3 }
            
            Text {
                text: "TOP GPU PROCESSES"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXXS
                font.weight: Font.Bold
                font.letterSpacing: Colors.letterSpacingWide
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
                    spacing: Colors.spacingS
                    
                    Text {
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: modelData.gfx + "%"
                        color: Colors.secondary
                        font.pixelSize: Colors.fontSizeSmall
                        font.family: Colors.fontMono
                        font.weight: Font.Bold
                    }
                    
                    Text {
                        text: MU.formatBytes(modelData.vram)
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXXS
                        font.family: Colors.fontMono
                    }
                }
            }
            
            Text {
                visible: Object.keys(AMDGPUService.processGpuUsage).length === 0
                text: "No GPU activity detected"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXXS
                font.italic: true
            }
        }
    }
}
