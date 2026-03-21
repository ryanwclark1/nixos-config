import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/SystemCardStyle.js" as SystemCardStyle

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
    readonly property color usageColor: SystemCardStyle.usageTierColor(
        primaryPercent, Colors.info, Colors.warning, Colors.error, 0.75, 0.9)

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
            diskSparkline.requestRepaint();
        }
    }

    ColumnLayout {
        id: diskColumn
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SystemSectionTitle {
                title: "DISK"
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                visible: root._primaryDrive !== null
                icon: "hard-drive.svg"
                iconColor: root.usageColor
                text: root._primaryDrive ? root._primaryDrive.percent : "--"
                textColor: root.usageColor
            }
        }

        // Gauge + stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingL

            ResourceGauge {
                value: root.primaryPercent
                color: root.usageColor
                icon: "hard-drive.svg"
                label: root._primaryDrive ? root._primaryDrive.percent : "--"
            }

            // Stats column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXS

                Repeater {
                    model: root.drives
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingXS

                        SharedWidgets.InfoRow {
                            Layout.fillWidth: true
                            label: modelData.mount === "/" ? "Root (/)" : modelData.mount
                            value: modelData.used + " / " + modelData.total
                            valueColor: SystemCardStyle.usageTierColor(
                                (parseInt(modelData.percent, 10) || 0) / 100.0,
                                Colors.text, Colors.warning, Colors.error, 0.75, 0.9)
                        }

                        SharedWidgets.MiniProgressBar {
                            value: Math.min(100, parseInt(modelData.percent, 10) || 0) / 100.0
                            barColor: SystemCardStyle.usageTierColor(
                                (parseInt(modelData.percent, 10) || 0) / 100.0,
                                Colors.info, Colors.warning, Colors.error, 0.75, 0.9)
                        }
                    }
                }
            }
        }

        SparklineSection {
            id: diskSparkline
            label: "HISTORY (ROOT)"
            history: root.diskHistory
            accentColor: root.usageColor
            currentText: root.diskHistory.length > 0
                ? Math.round((root.diskHistory[root.diskHistory.length - 1] || 0) * 100) + "%" : ""
        }
    }
}
