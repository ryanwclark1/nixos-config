import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/GraphUtils.js" as GU

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: gpuColumn.implicitHeight + root.pad * 2

    property string vramUsage: "0 / 0 MB"
    property real vramPercent: 0.0
    property var gpuHistory: []

    SharedWidgets.Ref { service: SystemStatus }

    Component.onCompleted: gpuHistory = SystemStatus.gpuHistory.slice(-30)

    Connections {
        target: SystemStatus
        function onGpuHistoryChanged() {
            root.gpuHistory = SystemStatus.gpuHistory.slice(-30);
            gpuCanvas.requestPaint();
        }
    }

    readonly property int _vramPollMs: 5000

    CommandPoll {
        id: vramPoll
        interval: root._vramPollMs
        running: root.visible
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
                text: "GPU"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                visible: SystemStatus.gpuTemp !== "--"
                icon: "󰢮"
                iconColor: SystemStatus.gpuTempNum > 85 ? Colors.error : Colors.textSecondary
                text: SystemStatus.gpuTemp
                textColor: SystemStatus.gpuTempNum > 85 ? Colors.error : Colors.textSecondary
            }
        }

        // Gauge + stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingL

            // Circular gauge
            Item {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72

                CircularGauge {
                    anchors.fill: parent
                    value: SystemStatus.gpuPercent
                    color: root.usageColor
                    thickness: 4
                    icon: "󰢮"
                    width: 72
                    height: 72
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    text: SystemStatus.gpuUsage
                    color: root.usageColor
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                    font.family: Colors.fontMono
                }
            }

            // Stats column
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
                    label: "Temperature"
                    value: SystemStatus.gpuTemp
                    valueColor: SystemStatus.gpuTempNum > 85 ? Colors.error : Colors.text
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "VRAM"
                    value: root.vramUsage
                }

                SharedWidgets.MiniProgressBar {
                    value: root.vramPercent
                    barColor: Colors.primary
                }
            }
        }

        // GPU history graph
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "HISTORY"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                    font.letterSpacing: Colors.letterSpacingWide
                    Layout.fillWidth: true
                }
                Text {
                    visible: root.gpuHistory.length > 0
                    text: Math.round((root.gpuHistory[root.gpuHistory.length - 1] || 0) * 100) + "%"
                    color: root.usageColor
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                    font.family: Colors.fontMono
                }
            }

            Canvas {
                id: gpuCanvas
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                renderTarget: Canvas.FramebufferObject
                renderStrategy: Canvas.Threaded
                onPaint: GU.paintLineGraph(gpuCanvas, root.gpuHistory, root.usageColor, Colors.withAlpha, { yScale: 0.9 })
            }
        }
    }
}
