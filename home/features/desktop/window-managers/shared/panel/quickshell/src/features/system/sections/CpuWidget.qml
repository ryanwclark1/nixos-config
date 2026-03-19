import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/GraphUtils.js" as GU

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
            cpuCanvas.requestPaint();
        }
    }

    readonly property int _loadPollMs: 5000

    CommandPoll {
        interval: root._loadPollMs
        running: root.visible
        command: ["sh", "-c", "cut -d' ' -f1-3 /proc/loadavg 2>/dev/null"]
        onUpdated: root.loadAverage = String(this.value || "--").trim()
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

            // Circular gauge
            Item {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72

                CircularGauge {
                    anchors.fill: parent
                    value: SystemStatus.cpuPercent
                    color: root.usageColor
                    thickness: 4
                    icon: ""
                    width: 72
                    height: 72
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    text: SystemStatus.cpuUsage
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

        // Sparkline graph
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
                    visible: root.cpuHistory.length > 0
                    text: Math.round((root.cpuHistory[root.cpuHistory.length - 1] || 0) * 100) + "%"
                    color: root.usageColor
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                    font.family: Colors.fontMono
                }
            }

            Canvas {
                id: cpuCanvas
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                renderTarget: Canvas.FramebufferObject
                renderStrategy: Canvas.Threaded
                onPaint: GU.paintLineGraph(cpuCanvas, root.cpuHistory, root.usageColor, Colors.withAlpha, { yScale: 0.9 })
            }
        }
    }
}
