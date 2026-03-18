import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU
import "../models/GraphUtils.js" as GU

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

                    downCanvas.requestPaint();
                    upCanvas.requestPaint();
                }

                root.lastRx = rx;
                root.lastTx = tx;
            }
        }
    }

    ColumnLayout {
        id: netColumn
        Layout.fillWidth: true
        spacing: Colors.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "NETWORK"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                icon: root.activeInterface === "offline" ? "󰤭" : "󰛳"
                iconColor: root.activeInterface === "offline" ? Colors.error : Colors.primary
                text: root.activeInterface.toUpperCase()
                textColor: root.activeInterface === "offline" ? Colors.error : Colors.textSecondary
            }
        }

        // Gauge + stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingL

            // Circular gauge — combined throughput
            Item {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72

                CircularGauge {
                    anchors.fill: parent
                    value: root.throughputPercent
                    color: root.throughputColor
                    thickness: 4
                    icon: "󰛳"
                    width: 72
                    height: 72
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    text: root.activeInterface === "offline" ? "OFF" : "ON"
                    color: root.activeInterface === "offline" ? Colors.error : root.throughputColor
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

        // Dual sparkline graphs
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingL

            // Download history
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "DOWNLOAD"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXXS
                        font.weight: Font.Bold
                        font.letterSpacing: Colors.letterSpacingWide
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.currentDown
                        color: Colors.primary
                        font.pixelSize: Colors.fontSizeXXS
                        font.weight: Font.Bold
                        font.family: Colors.fontMono
                    }
                }

                Canvas {
                    id: downCanvas
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    renderTarget: Canvas.FramebufferObject
                    renderStrategy: Canvas.Threaded
                    onPaint: GU.paintLineGraph(downCanvas, root.downHistory, Colors.primary, Colors.withAlpha, { fill: false })
                }
            }

            // Upload history
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "UPLOAD"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXXS
                        font.weight: Font.Bold
                        font.letterSpacing: Colors.letterSpacingWide
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.currentUp
                        color: Colors.accent
                        font.pixelSize: Colors.fontSizeXXS
                        font.weight: Font.Bold
                        font.family: Colors.fontMono
                    }
                }

                Canvas {
                    id: upCanvas
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    renderTarget: Canvas.FramebufferObject
                    renderStrategy: Canvas.Threaded
                    onPaint: GU.paintLineGraph(upCanvas, root.upHistory, Colors.accent, Colors.withAlpha, { fill: false })
                }
            }
        }
    }
}
