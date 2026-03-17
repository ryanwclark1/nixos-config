import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: summaryColumn.implicitHeight + root.pad * 2

    property string uptimeText: "--"
    property string loadAverage: "--"
    property string swapUsage: "--"
    property int _clockTick: 0

    SharedWidgets.Ref { service: SystemStatus }
    SharedWidgets.Ref { service: NetworkService }
    SharedWidgets.Ref { service: SystemIoTelemetryService }

    function formatRate(bytes) {
        var value = Number(bytes || 0);
        if (value < 1024)
            return Math.round(value) + " B/s";
        if (value < 1048576)
            return (value / 1024).toFixed(1) + " KB/s";
        if (value < 1073741824)
            return (value / 1048576).toFixed(1) + " MB/s";
        return (value / 1073741824).toFixed(2) + " GB/s";
    }

    function formatAge(timestampMs) {
        _clockTick;
        var value = Number(timestampMs || 0);
        if (value <= 0)
            return "waiting";
        var seconds = Math.max(0, Math.round((Date.now() - value) / 1000));
        if (seconds < 1)
            return "now";
        if (seconds < 60)
            return String(seconds) + "s ago";
        var minutes = Math.floor(seconds / 60);
        var remainder = seconds % 60;
        return String(minutes) + "m " + String(remainder) + "s ago";
    }

    SharedWidgets.CommandPoll {
        id: hostPoll
        interval: 5000
        running: root.visible
        command: [
            "sh",
            "-c",
            "printf '%s\\n%s\\n%s\\n' "
            + "\"$(uptime -p 2>/dev/null | sed 's/^up //;s/ hours/h/;s/ hour/h/;s/ minutes/m/;s/ minute/m/')\" "
            + "\"$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)\" "
            + "\"$(free -h 2>/dev/null | awk '/^Swap:/ {print $3 \" / \" $2}')\""
        ]
        parse: function(out) {
            var lines = String(out || "").trim().split("\n");
            return {
                uptime: String(lines[0] || "--").trim() || "--",
                loadAverage: String(lines[1] || "--").trim() || "--",
                swapUsage: String(lines[2] || "--").trim() || "--"
            };
        }
        onUpdated: {
            var next = hostPoll.value || {};
            root.uptimeText = String(next.uptime || "--");
            root.loadAverage = String(next.loadAverage || "--");
            root.swapUsage = String(next.swapUsage || "--");
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        onTriggered: root._clockTick = root._clockTick + 1
    }

    ColumnLayout {
        id: summaryColumn
        Layout.fillWidth: true
        spacing: Colors.spacingM

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "SYSTEM OVERVIEW"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
                font.capitalization: Font.AllUppercase
            }

            Item {
                Layout.fillWidth: true
            }

            SharedWidgets.Chip {
                icon: "󰥔"
                iconColor: Colors.secondary
                text: root.uptimeText
                textColor: Colors.secondary
            }

            SharedWidgets.Chip {
                icon: SystemStatus.isCritical ? "󰀦" : "󰄬"
                iconColor: SystemStatus.isCritical ? Colors.error : Colors.success
                text: SystemStatus.isCritical ? "Attention" : "Healthy"
                textColor: SystemStatus.isCritical ? Colors.error : Colors.success
            }

            SharedWidgets.Chip {
                icon: SystemIoTelemetryService.telemetryStatus === "degraded" ? "󰀦" : "󰄬"
                iconColor: SystemIoTelemetryService.telemetryStatus === "degraded" ? Colors.warning : Colors.textSecondary
                text: "I/O " + SystemIoTelemetryService.telemetryStatus.toUpperCase()
                textColor: SystemIoTelemetryService.telemetryStatus === "degraded" ? Colors.warning : Colors.textSecondary
            }
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            SharedWidgets.Chip {
                icon: ""
                iconColor: Colors.primary
                text: "CPU " + SystemStatus.cpuUsage + "  " + SystemStatus.cpuTemp
                textColor: Colors.primary
            }

            SharedWidgets.Chip {
                icon: "󰍛"
                iconColor: Colors.accent
                text: "RAM " + SystemStatus.ramUsage
                textColor: Colors.accent
            }

            SharedWidgets.Chip {
                icon: "󰢮"
                iconColor: Colors.secondary
                text: "GPU " + SystemStatus.gpuUsage + "  " + SystemStatus.gpuTemp
                textColor: Colors.secondary
            }

            SharedWidgets.Chip {
                icon: NetworkService.networkIcon()
                iconColor: Colors.warning
                text: NetworkService.activePrimaryName
                textColor: Colors.warning
            }

            SharedWidgets.Chip {
                visible: SystemIoTelemetryService.selectedInterface !== ""
                icon: SystemIoTelemetryService.networkHotspot ? "󰀦" : "󰈀"
                iconColor: SystemIoTelemetryService.networkHotspot ? Colors.warning : Colors.primary
                text: "NET PEAK " + root.formatRate(Math.max(SystemIoTelemetryService.peakNetworkDown, SystemIoTelemetryService.peakNetworkUp))
                textColor: SystemIoTelemetryService.networkHotspot ? Colors.warning : Colors.primary
            }

            SharedWidgets.Chip {
                visible: SystemIoTelemetryService.selectedDiskDevice !== ""
                icon: SystemIoTelemetryService.diskHotspot ? "󰀦" : "󰋊"
                iconColor: SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.secondary
                text: "DISK PEAK " + root.formatRate(Math.max(SystemIoTelemetryService.peakDiskRead, SystemIoTelemetryService.peakDiskWrite))
                textColor: SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.secondary
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Colors.spacingM
            rowSpacing: Colors.spacingS

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "CPU"
                    value: SystemStatus.cpuUsage
                }

                SharedWidgets.MiniProgressBar {
                    value: SystemStatus.cpuPercent
                    barColor: Colors.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Memory"
                    value: SystemStatus.ramUsage
                }

                SharedWidgets.MiniProgressBar {
                    value: SystemStatus.ramPercent
                    barColor: Colors.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "GPU"
                    value: SystemStatus.gpuUsage
                }

                SharedWidgets.MiniProgressBar {
                    value: SystemStatus.gpuPercent
                    barColor: Colors.secondary
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Colors.spacingL
            rowSpacing: Colors.spacingS

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Load Avg"
                value: root.loadAverage
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Swap"
                value: root.swapUsage
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Primary Net"
                value: NetworkService.detailValue(NetworkService.primaryDevice, NetworkService.activePrimaryName)
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Connectivity"
                value: NetworkService.connectivityStatus
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "RX Total"
                value: NetworkService.detailValue(NetworkService.totalReceived, "Unavailable")
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "TX Total"
                value: NetworkService.detailValue(NetworkService.totalSent, "Unavailable")
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Tracked Iface"
                value: SystemIoTelemetryService.selectedInterface !== "" ? SystemIoTelemetryService.selectedInterface : "Unavailable"
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Tracked Disk"
                value: SystemIoTelemetryService.selectedDiskDevice !== "" ? SystemIoTelemetryService.selectedDiskDevice : "Unavailable"
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Net Peak"
                value: root.formatRate(Math.max(SystemIoTelemetryService.peakNetworkDown, SystemIoTelemetryService.peakNetworkUp))
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Disk Peak"
                value: root.formatRate(Math.max(SystemIoTelemetryService.peakDiskRead, SystemIoTelemetryService.peakDiskWrite))
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Net Age"
                value: root.formatAge(SystemIoTelemetryService.networkLastSampleMs)
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Disk Age"
                value: root.formatAge(SystemIoTelemetryService.diskLastSampleMs)
            }
        }
    }
}
