import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

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
            ramSparkline.requestRepaint();
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
        spacing: Appearance.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Text {
                text: "MEMORY"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                icon: "board.svg"
                iconColor: root.usageColor
                text: SystemStatus.ramUsage
                textColor: root.usageColor
            }
        }

        // Gauge + stats row
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingL

            ResourceGauge {
                value: SystemStatus.ramPercent
                color: root.usageColor
                icon: "board.svg"
                label: Math.round(SystemStatus.ramPercent * 100) + "%"
            }

            // Stats column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXS

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

        SparklineSection {
            id: ramSparkline
            history: root.ramHistory
            accentColor: root.usageColor
            currentText: root.ramHistory.length > 0
                ? Math.round((root.ramHistory[root.ramHistory.length - 1] || 0) * 100) + "%" : ""
        }
    }
}
