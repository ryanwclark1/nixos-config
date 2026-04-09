import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/SystemCardStyle.js" as SystemCardStyle

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: cpuColumn.implicitHeight + root.pad * 2

    property var cpuHistory: []
    property string loadAverage: "--"
    property var cpuInfo: ({
        vendor: "--",
        model: "--",
        architecture: "--",
        cores: "--",
        threads: "--",
        threadsPerCore: "--",
        sockets: "--",
        currentClock: "--",
        maxClock: "--",
        minClock: "--",
        boost: "--"
    })

    readonly property bool hasCpuInfo: root.cpuInfo.model !== "--" || root.cpuInfo.vendor !== "--"
    readonly property int _cpuInfoPollMs: 300000
    readonly property string _cpuInfoScript:
        "LC_ALL=C; "
        + "lscpu_out=$(lscpu 2>/dev/null || true); "
        + "field() { printf '%s\\n' \"$lscpu_out\" | awk -F: -v key=\"$1\" '$1 == key { sub(/^[[:space:]]+/, \"\", $2); print $2; exit }'; }; "
        + "fallback() { if [ -n \"$1\" ]; then printf '%s' \"$1\"; else printf -- '--'; fi; }; "
        + "format_clock() { awk -v mhz=\"$1\" 'BEGIN { value = mhz + 0; if (value >= 1000) printf \"%.2f GHz\", value / 1000; else if (value > 0) printf \"%.0f MHz\", value; else printf \"--\"; }'; }; "
        + "vendor=$(field 'Vendor ID'); "
        + "case \"$vendor\" in AuthenticAMD) vendor='AMD' ;; GenuineIntel) vendor='Intel' ;; esac; "
        + "model=$(field 'Model name'); "
        + "arch=$(field 'Architecture'); "
        + "threads=$(field 'CPU(s)'); "
        + "threads_per_core=$(field 'Thread(s) per core'); "
        + "cores_per_socket=$(field 'Core(s) per socket'); "
        + "sockets=$(field 'Socket(s)'); "
        + "max_mhz=$(field 'CPU max MHz'); "
        + "min_mhz=$(field 'CPU min MHz'); "
        + "boost=$(field 'Frequency boost'); "
        + "avg_mhz=$(awk -F: '/cpu MHz/ { sum += $2; count += 1 } END { if (count > 0) printf \"%.0f\", sum / count }' /proc/cpuinfo 2>/dev/null); "
        + "if [ -z \"$vendor\" ] && [ -r /proc/cpuinfo ]; then vendor=$(awk -F: '/vendor_id/ { sub(/^[[:space:]]+/, \"\", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null); fi; "
        + "case \"$vendor\" in AuthenticAMD) vendor='AMD' ;; GenuineIntel) vendor='Intel' ;; esac; "
        + "if [ -z \"$model\" ] && [ -r /proc/cpuinfo ]; then model=$(awk -F: '/model name/ { sub(/^[[:space:]]+/, \"\", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null); fi; "
        + "if [ -z \"$arch\" ]; then arch=$(uname -m 2>/dev/null); fi; "
        + "if [ -z \"$threads\" ] && [ -r /proc/cpuinfo ]; then threads=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null); fi; "
        + "if [ -z \"$threads_per_core\" ] && [ -r /proc/cpuinfo ]; then threads_per_core=$(awk -F: '/siblings/ { siblings = $2 + 0 } /cpu cores/ { cores = $2 + 0 } END { if (siblings > 0 && cores > 0) printf \"%d\", siblings / cores }' /proc/cpuinfo 2>/dev/null); fi; "
        + "if [ -z \"$cores_per_socket\" ] && [ -r /proc/cpuinfo ]; then cores_per_socket=$(awk -F: '/cpu cores/ { sub(/^[[:space:]]+/, \"\", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null); fi; "
        + "if [ -z \"$sockets\" ]; then sockets=1; fi; "
        + "cores_total=''; "
        + "if [ -n \"$cores_per_socket\" ] && [ -n \"$sockets\" ]; then cores_total=$(awk -v cores=\"$cores_per_socket\" -v sockets=\"$sockets\" 'BEGIN { if (cores + 0 > 0 && sockets + 0 > 0) printf \"%d\", cores * sockets }'); fi; "
        + "printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' "
        + "\"$(fallback \"$vendor\")\" "
        + "\"$(fallback \"$model\")\" "
        + "\"$(fallback \"$arch\")\" "
        + "\"$(fallback \"$cores_total\")\" "
        + "\"$(fallback \"$threads\")\" "
        + "\"$(fallback \"$threads_per_core\")\" "
        + "\"$(fallback \"$sockets\")\" "
        + "\"$(format_clock \"$avg_mhz\")\" "
        + "\"$(format_clock \"$max_mhz\")\" "
        + "\"$(format_clock \"$min_mhz\")\" "
        + "\"$(fallback \"$boost\")\""

    SharedWidgets.Ref { service: SystemStatus }

    Component.onCompleted: cpuHistory = SystemStatus.cpuHistory.slice(-30)

    Connections {
        target: SystemStatus
        function onCpuHistoryChanged() {
            root.cpuHistory = SystemStatus.cpuHistory.slice(-30);
            cpuSparkline.requestRepaint();
        }
    }

    FileView {
        id: _loadAvgFile
        path: "/proc/loadavg"
        printErrors: false
        onLoaded: {
            var parts = String(this.text() || "").trim().split(/\s+/);
            root.loadAverage = parts.length >= 3 ? parts.slice(0, 3).join(" ") : "--";
        }
        onFileChanged: this.reload()
    }

    Timer {
        interval: 5000; running: root.visible; repeat: true
        onTriggered: _loadAvgFile.reload()
    }

    CommandPoll {
        id: cpuInfoPoll
        interval: root._cpuInfoPollMs
        running: root.visible
        command: ["sh", "-c", root._cpuInfoScript]
        parse: function(out) {
            var lines = String(out || "").replace(/\r/g, "").trim().split("\n");
            return {
                vendor: String(lines[0] || "--").trim() || "--",
                model: String(lines[1] || "--").trim() || "--",
                architecture: String(lines[2] || "--").trim() || "--",
                cores: String(lines[3] || "--").trim() || "--",
                threads: String(lines[4] || "--").trim() || "--",
                threadsPerCore: String(lines[5] || "--").trim() || "--",
                sockets: String(lines[6] || "--").trim() || "--",
                currentClock: String(lines[7] || "--").trim() || "--",
                maxClock: String(lines[8] || "--").trim() || "--",
                minClock: String(lines[9] || "--").trim() || "--",
                boost: String(lines[10] || "--").trim() || "--"
            };
        }
        onUpdated: root.cpuInfo = cpuInfoPoll.value || root.cpuInfo
    }

    readonly property color usageColor: SystemCardStyle.usageTierColor(
        SystemStatus.cpuPercent, Colors.primary, Colors.warning, Colors.error, 0.7, 0.9)

    ColumnLayout {
        id: cpuColumn
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SystemSectionTitle {
                title: "CPU"
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                visible: SystemStatus.cpuTemp !== "--"
                icon: "temperature.svg"
                iconColor: SystemStatus.cpuTempNum > 80 ? Colors.error : Colors.textSecondary
                text: SystemStatus.cpuTemp
                textColor: SystemStatus.cpuTempNum > 80 ? Colors.error : Colors.textSecondary
            }
        }

        // Gauge + stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingL

            ResourceGauge {
                value: SystemStatus.cpuPercent
                color: root.usageColor
                icon: "developer-board.svg"
                label: SystemStatus.cpuUsage
            }

            // Stats column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Usage"
                    value: SystemStatus.cpuUsage
                    valueColor: root.usageColor
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Temperature"
                    value: SystemStatus.cpuTemp
                    valueColor: SystemStatus.cpuTempNum > 80 ? Colors.error : Colors.text
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Load Average"
                    value: root.loadAverage
                }

                SharedWidgets.MiniProgressBar {
                    value: SystemStatus.cpuPercent
                    barColor: root.usageColor
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS
            visible: root.hasCpuInfo

            Text {
                text: "PROCESSOR INFO"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
                font.capitalization: Font.AllUppercase
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.cpuInfo.model !== "--"
                radius: Appearance.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.withAlpha(Colors.border, 0.75)
                border.width: 1
                implicitHeight: modelColumn.implicitHeight + Appearance.spacingS * 2

                ColumnLayout {
                    id: modelColumn
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS
                    spacing: Appearance.spacingXS

                    Text {
                        text: "MODEL"
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.Black
                        font.letterSpacing: Appearance.letterSpacingWide
                        font.capitalization: Font.AllUppercase
                    }

                    Text {
                        text: root.cpuInfo.model
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: cpuColumn.width >= 460 ? 2 : 1
                columnSpacing: Appearance.spacingM
                rowSpacing: Appearance.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Vendor"
                    value: root.cpuInfo.vendor
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Architecture"
                    value: root.cpuInfo.architecture
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Cores"
                    value: root.cpuInfo.cores
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Threads"
                    value: root.cpuInfo.threads
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Threads/Core"
                    value: root.cpuInfo.threadsPerCore
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Sockets"
                    value: root.cpuInfo.sockets
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Current Clock"
                    value: root.cpuInfo.currentClock
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Max Clock"
                    value: root.cpuInfo.maxClock
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Min Clock"
                    value: root.cpuInfo.minClock
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Boost"
                    value: root.cpuInfo.boost
                }
            }
        }

        SparklineSection {
            id: cpuSparkline
            history: root.cpuHistory
            accentColor: root.usageColor
            currentText: root.cpuHistory.length > 0
                ? Math.round((root.cpuHistory[root.cpuHistory.length - 1] || 0) * 100) + "%" : ""
        }
    }
}
