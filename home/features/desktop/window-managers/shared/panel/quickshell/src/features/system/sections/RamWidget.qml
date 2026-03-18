import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/GraphUtils.js" as GU

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: ramColumn.implicitHeight + root.pad * 2

    property var ramHistory: []
    property string swapUsage: "--"
    property string ramDetail: "--"

    SharedWidgets.Ref { service: SystemStatus }

    Component.onCompleted: ramHistory = SystemStatus.ramHistory.slice(-30)

    Connections {
        target: SystemStatus
        function onRamHistoryChanged() {
            root.ramHistory = SystemStatus.ramHistory.slice(-30);
            ramCanvas.requestPaint();
        }
    }

    readonly property int _memPollMs: 5000

    CommandPoll {
        interval: root._memPollMs
        running: root.visible
        command: ["sh", "-c",
            "free -h 2>/dev/null | awk '/^Mem:/ {print $3 \" / \" $2} /^Swap:/ {print $3 \" / \" $2}'"
        ]
        onUpdated: {
            var lines = String(this.value || "").trim().split("\n");
            root.ramDetail = String(lines[0] || "--").trim();
            root.swapUsage = String(lines[1] || "--").trim();
        }
    }

    readonly property color usageColor: SystemStatus.ramPercent >= 0.9 ? Colors.error
        : (SystemStatus.ramPercent >= 0.75 ? Colors.warning : Colors.accent)

    ColumnLayout {
        id: ramColumn
        Layout.fillWidth: true
        spacing: Colors.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "MEMORY"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                icon: "󰍛"
                iconColor: root.usageColor
                text: SystemStatus.ramUsage
                textColor: root.usageColor
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
                    value: SystemStatus.ramPercent
                    color: root.usageColor
                    thickness: 4
                    icon: "󰍛"
                    width: 72
                    height: 72
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    text: Math.round(SystemStatus.ramPercent * 100) + "%"
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
                    label: "Used / Total"
                    value: root.ramDetail
                    valueColor: root.usageColor
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Usage"
                    value: SystemStatus.ramUsage
                    valueColor: root.usageColor
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Swap"
                    value: root.swapUsage
                }

                SharedWidgets.MiniProgressBar {
                    value: SystemStatus.ramPercent
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
                    visible: root.ramHistory.length > 0
                    text: Math.round((root.ramHistory[root.ramHistory.length - 1] || 0) * 100) + "%"
                    color: root.usageColor
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Bold
                    font.family: Colors.fontMono
                }
            }

            Canvas {
                id: ramCanvas
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                renderTarget: Canvas.FramebufferObject
                renderStrategy: Canvas.Threaded
                onPaint: GU.paintLineGraph(ramCanvas, root.ramHistory, root.usageColor, Colors.withAlpha, { yScale: 0.9 })
            }
        }
    }
}
