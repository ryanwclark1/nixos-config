import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/GraphUtils.js" as GU

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: diskColumn.implicitHeight + root.pad * 2

    property var drives: []
    property var diskHistory: []

    readonly property int _diskPollMs: 30000
    readonly property var _primaryDrive: {
        for (var i = 0; i < drives.length; i++) {
            if (drives[i].mount === "/") return drives[i];
        }
        return drives.length > 0 ? drives[0] : null;
    }
    readonly property real primaryPercent: _primaryDrive ? (Math.min(100, parseInt(_primaryDrive.percent, 10) || 0) / 100.0) : 0
    readonly property color usageColor: primaryPercent >= 0.9 ? Colors.error
        : (primaryPercent >= 0.75 ? Colors.warning : Colors.secondary)

    CommandPoll {
        interval: root._diskPollMs
        running: root.visible
        command: ["sh", "-c", "df -h / /home 2>/dev/null | tail -n +2 | awk '{print $6 \":\" $5 \":\" $3 \":\" $2}' | sort -u"]
        parse: function(out) {
            var lines = String(out || "").trim().split("\n");
            var items = [];
            for (var i = 0; i < lines.length; i++) {
                var p = lines[i].split(":");
                if (p.length >= 4) items.push({ mount: p[0], percent: p[1], used: p[2], total: p[3] });
            }
            return items;
        }
        onUpdated: {
            root.drives = this.value || [];
            var hist = root.diskHistory;
            if (hist.length === 0) hist = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
            hist.shift();
            hist.push(root.primaryPercent);
            root.diskHistory = hist;
            diskCanvas.requestPaint();
        }
    }

    ColumnLayout {
        id: diskColumn
        Layout.fillWidth: true
        spacing: Colors.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "DISK"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                visible: root._primaryDrive !== null
                icon: "󰋊"
                iconColor: root.usageColor
                text: root._primaryDrive ? root._primaryDrive.percent : "--"
                textColor: root.usageColor
            }
        }

        // Gauge + stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingL

            // Circular gauge — primary mount
            Item {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72

                CircularGauge {
                    anchors.fill: parent
                    value: root.primaryPercent
                    color: root.usageColor
                    thickness: 4
                    icon: "󰋊"
                    width: 72
                    height: 72
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    text: root._primaryDrive ? root._primaryDrive.percent : "--"
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

                Repeater {
                    model: root.drives
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXS

                        SharedWidgets.InfoRow {
                            Layout.fillWidth: true
                            label: modelData.mount === "/" ? "Root (/)" : modelData.mount
                            value: modelData.used + " / " + modelData.total
                            valueColor: {
                                var pct = (parseInt(modelData.percent, 10) || 0) / 100.0;
                                return pct >= 0.9 ? Colors.error : (pct >= 0.75 ? Colors.warning : Colors.text);
                            }
                        }

                        SharedWidgets.MiniProgressBar {
                            value: Math.min(100, parseInt(modelData.percent, 10) || 0) / 100.0
                            barColor: {
                                var pct = (parseInt(modelData.percent, 10) || 0) / 100.0;
                                return pct >= 0.9 ? Colors.error : (pct >= 0.75 ? Colors.warning : Colors.secondary);
                            }
                        }
                    }
                }
            }
        }

        // Sparkline graph (primary mount history)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "HISTORY (ROOT)"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                    font.letterSpacing: Colors.letterSpacingWide
                    Layout.fillWidth: true
                }
                Text {
                    visible: root.diskHistory.length > 0
                    text: Math.round((root.diskHistory[root.diskHistory.length - 1] || 0) * 100) + "%"
                    color: root.usageColor
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                    font.family: Colors.fontMono
                }
            }

            Canvas {
                id: diskCanvas
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                renderTarget: Canvas.FramebufferObject
                renderStrategy: Canvas.Threaded
                onPaint: GU.paintLineGraph(diskCanvas, root.diskHistory, root.usageColor, Colors.withAlpha, { yScale: 0.9 })
            }
        }
    }
}
