import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: summaryColumn.implicitHeight + root.pad * 2

    property string uptimeText: "--"
    property string loadAverage: "--"
    property int _clockTick: 0

    SharedWidgets.Ref { service: SystemStatus }
    SharedWidgets.Ref { service: NetworkService }
    SharedWidgets.Ref { service: SystemIoTelemetryService }

    readonly property int _hostInfoPollMs: 5000

    CommandPoll {
        id: hostPoll
        interval: root._hostInfoPollMs
        running: root.visible
        command: [
            "sh",
            "-c",
            "printf '%s\\n%s\\n' "
            + "\"$(cat /proc/uptime 2>/dev/null | cut -d' ' -f1)\" "
            + "\"$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)\""
        ]
        parse: function(out) {
            var lines = String(out || "").trim().split("\n");
            var uptimeSecs = parseFloat(lines[0] || "0");
            var uptimeText = "--";
            if (!isNaN(uptimeSecs)) {
                var d = Math.floor(uptimeSecs / 86400);
                var h = Math.floor((uptimeSecs % 86400) / 3600);
                var m = Math.floor((uptimeSecs % 3600) / 60);
                uptimeText = "";
                if (d > 0) uptimeText += d + "d ";
                if (h > 0) uptimeText += h + "h ";
                uptimeText += m + "m";
            }
            return {
                uptime: String(uptimeText || "--").trim() || "--",
                loadAverage: String(lines[1] || "--").trim() || "--"
            };
        }
        onUpdated: {
            var next = hostPoll.value || {};
            root.uptimeText = String(next.uptime || "--");
            root.loadAverage = String(next.loadAverage || "--");
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
        spacing: Appearance.spacingM

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "SYSTEM OVERVIEW"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
                font.capitalization: Font.AllUppercase
            }

            Item {
                Layout.fillWidth: true
            }

            SharedWidgets.Chip {
                icon: "clock.svg"
                iconColor: Colors.secondary
                text: root.uptimeText
                textColor: Colors.secondary
            }

            SharedWidgets.Chip {
                icon: IconHelpers.healthStatusIcon(SystemStatus.isCritical)
                iconColor: SystemStatus.isCritical ? Colors.error : Colors.success
                text: SystemStatus.isCritical ? "Attention" : "Healthy"
                textColor: SystemStatus.isCritical ? Colors.error : Colors.success
            }

            SharedWidgets.Chip {
                icon: IconHelpers.healthStatusIcon(SystemIoTelemetryService.telemetryStatus === "degraded")
                iconColor: SystemIoTelemetryService.telemetryStatus === "degraded" ? Colors.warning : Colors.textSecondary
                text: "I/O " + SystemIoTelemetryService.telemetryStatus.toUpperCase()
                textColor: SystemIoTelemetryService.telemetryStatus === "degraded" ? Colors.warning : Colors.textSecondary
            }
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            SharedWidgets.Chip {
                icon: "developer-board.svg"
                iconColor: Colors.primary
                text: "CPU " + SystemStatus.cpuUsage + "  " + SystemStatus.cpuTemp
                textColor: Colors.primary
            }

            SharedWidgets.Chip {
                icon: "memory.svg"
                iconColor: Colors.accent
                text: "RAM " + SystemStatus.ramUsage
                textColor: Colors.accent
            }

            SharedWidgets.Chip {
                icon: "board.svg"
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
                icon: IconHelpers.degradedStatusIcon(SystemIoTelemetryService.networkHotspot, "ethernet.svg")
                iconColor: SystemIoTelemetryService.networkHotspot ? Colors.warning : Colors.primary
                text: "NET PEAK " + MU.formatRate(Math.max(SystemIoTelemetryService.peakNetworkDown, SystemIoTelemetryService.peakNetworkUp))
                textColor: SystemIoTelemetryService.networkHotspot ? Colors.warning : Colors.primary
            }

            SharedWidgets.Chip {
                visible: SystemIoTelemetryService.selectedDiskDevice !== ""
                icon: IconHelpers.degradedStatusIcon(SystemIoTelemetryService.diskHotspot, "hard-drive.svg")
                iconColor: SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.info
                text: "DISK PEAK " + MU.formatRate(Math.max(SystemIoTelemetryService.peakDiskRead, SystemIoTelemetryService.peakDiskWrite))
                textColor: SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.info
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Appearance.spacingM
            rowSpacing: Appearance.spacingS

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXS

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
                spacing: Appearance.spacingXS

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
                spacing: Appearance.spacingXS

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
            columnSpacing: Appearance.spacingL
            rowSpacing: Appearance.spacingS

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Load Avg"
                value: root.loadAverage
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Swap"
                value: SystemStatus.swapUsage
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
                value: MU.formatRate(Math.max(SystemIoTelemetryService.peakNetworkDown, SystemIoTelemetryService.peakNetworkUp))
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Disk Peak"
                value: MU.formatRate(Math.max(SystemIoTelemetryService.peakDiskRead, SystemIoTelemetryService.peakDiskWrite))
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Net Age"
                value: MU.formatAge(SystemIoTelemetryService.networkLastSampleMs, root._clockTick)
            }

            SharedWidgets.InfoRow {
                Layout.fillWidth: true
                label: "Disk Age"
                value: MU.formatAge(SystemIoTelemetryService.diskLastSampleMs, root._clockTick)
            }
        }
    }
}
