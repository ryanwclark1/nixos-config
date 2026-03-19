import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../services"
import "../../../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: cpuColumn.implicitHeight + root.pad * 2

    property var cpuHistory: []
    property string loadAverage: "--"

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
        onTextChanged: {
            var parts = String(this.text || "").trim().split(/\s+/);
            root.loadAverage = parts.length >= 3 ? parts.slice(0, 3).join(" ") : "--";
        }
    }

    Timer {
        interval: 5000; running: root.visible; repeat: true
        onTriggered: _loadAvgFile.reload()
    }

    readonly property color usageColor: SystemStatus.cpuPercent >= 0.9 ? Colors.error
        : (SystemStatus.cpuPercent >= 0.7 ? Colors.warning : Colors.primary)

    ColumnLayout {
        id: cpuColumn
        Layout.fillWidth: true
        spacing: Colors.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "CPU"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                visible: SystemStatus.cpuTemp !== "--"
                icon: ""
                iconColor: SystemStatus.cpuTempNum > 80 ? Colors.error : Colors.textSecondary
                text: SystemStatus.cpuTemp
                textColor: SystemStatus.cpuTempNum > 80 ? Colors.error : Colors.textSecondary
            }
        }

        // Gauge + stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingL

            ResourceGauge {
                value: SystemStatus.cpuPercent
                color: root.usageColor
                icon: ""
                label: SystemStatus.cpuUsage
            }

            // Stats column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXS

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

        SparklineSection {
            id: cpuSparkline
            history: root.cpuHistory
            accentColor: root.usageColor
            currentText: root.cpuHistory.length > 0
                ? Math.round((root.cpuHistory[root.cpuHistory.length - 1] || 0) * 100) + "%" : ""
        }
    }
}
