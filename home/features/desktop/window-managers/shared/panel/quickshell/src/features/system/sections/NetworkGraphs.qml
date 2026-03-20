import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: netColumn.implicitHeight + root.pad * 2

    property var downHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    property var upHistory: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    readonly property real _minScaleFloor: 1048576  // 1 MB/s
    property real lastRx: 0
    property real lastTx: 0
    property real maxDown: _minScaleFloor
    property real maxUp: _minScaleFloor
    property string activeInterface: "offline"
    property string currentDown: "0 KB/s"
    property string currentUp: "0 KB/s"
    property real currentDownBytes: 0
    property real currentUpBytes: 0

    // Combined throughput as 0..1 for the gauge (relative to max observed)
    readonly property real throughputPercent: {
        var total = currentDownBytes + currentUpBytes;
        var scale = Math.max(_minScaleFloor, maxDown + maxUp);
        return Math.min(1.0, total / scale);
    }
    readonly property color throughputColor: throughputPercent >= 0.9 ? Colors.warning
        : (throughputPercent >= 0.6 ? Colors.accent : Colors.primary)

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: { if (!netProc.running) netProc.running = true; }
    }

    Process {
        id: netProc
        command: [
            "sh",
            "-c",
            "iface=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}'); "
            + "if [ -z \"$iface\" ]; then iface=$(ip -o link show up 2>/dev/null | awk -F': ' '$2 != \"lo\" {print $2; exit}'); fi; "
            + "if [ -n \"$iface\" ] && [ -r \"/sys/class/net/$iface/statistics/rx_bytes\" ] && [ -r \"/sys/class/net/$iface/statistics/tx_bytes\" ]; then "
            + "printf '%s\\n%s\\n%s\\n' \"$iface\" \"$(cat /sys/class/net/$iface/statistics/rx_bytes)\" \"$(cat /sys/class/net/$iface/statistics/tx_bytes)\"; "
            + "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (this.text || "").trim().split("\n");
                if (lines.length < 3) return;
                root.activeInterface = lines[0] || "offline";
                var rx = parseInt(lines[1], 10) || 0;
                var tx = parseInt(lines[2], 10) || 0;

                if (root.lastRx > 0) {
                    var diffRx = Math.max(0, rx - root.lastRx);
                    var diffTx = Math.max(0, tx - root.lastTx);

                    root.currentDown = MU.formatRate(diffRx);
                    root.currentUp = MU.formatRate(diffTx);
                    root.currentDownBytes = diffRx;
                    root.currentUpBytes = diffTx;

                    // Adaptive scaling: grow instantly, decay slowly
                    if (diffRx > root.maxDown) root.maxDown = diffRx;
                    else root.maxDown = Math.max(root._minScaleFloor, root.maxDown * 0.995);

                    if (diffTx > root.maxUp) root.maxUp = diffTx;
                    else root.maxUp = Math.max(root._minScaleFloor, root.maxUp * 0.995);

                    var dHist = root.downHistory;
                    dHist.shift();
                    dHist.push(Math.min(1.0, diffRx / root.maxDown));
                    root.downHistory = dHist;

                    var uHist = root.upHistory;
                    uHist.shift();
                    uHist.push(Math.min(1.0, diffTx / root.maxUp));
                    root.upHistory = uHist;

                    downSparkline.requestRepaint();
                    upSparkline.requestRepaint();
                }

                root.lastRx = rx;
                root.lastTx = tx;
            }
        }
    }

    ColumnLayout {
        id: netColumn
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Text {
                text: "NETWORK"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                icon: IconHelpers.degradedStatusIcon(root.activeInterface === "offline", "ethernet.svg")
                iconColor: root.activeInterface === "offline" ? Colors.error : Colors.primary
                text: root.activeInterface.toUpperCase()
                textColor: root.activeInterface === "offline" ? Colors.error : Colors.textSecondary
            }
        }

        // Gauge + stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingL

            ResourceGauge {
                value: root.throughputPercent
                color: root.activeInterface === "offline" ? Colors.error : root.throughputColor
                icon: "ethernet.svg"
                label: root.activeInterface === "offline" ? "OFF" : "ON"
            }

            // Stats column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Download"
                    value: root.currentDown
                    valueColor: Colors.primary
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Upload"
                    value: root.currentUp
                    valueColor: Colors.accent
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Interface"
                    value: root.activeInterface
                }

                SharedWidgets.MiniProgressBar {
                    value: root.throughputPercent
                    barColor: root.throughputColor
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingL

            SparklineSection {
                id: downSparkline
                Layout.fillWidth: true
                label: "DOWNLOAD"
                history: root.downHistory
                accentColor: Colors.primary
                currentText: root.currentDown
                graphOptions: ({ fill: false })
            }

            SparklineSection {
                id: upSparkline
                Layout.fillWidth: true
                label: "UPLOAD"
                history: root.upHistory
                accentColor: Colors.accent
                currentText: root.currentUp
                graphOptions: ({ fill: false })
            }
        }
    }
}
