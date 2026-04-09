import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/SystemCardStyle.js" as SystemCardStyle

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: ramColumn.implicitHeight + root.pad * 2

    property var ramHistory: []
    SharedWidgets.Ref { service: SystemStatus }

    Component.onCompleted: ramHistory = SystemStatus.ramHistory.slice(-30)

    Connections {
        target: SystemStatus
        function onRamHistoryChanged() {
            root.ramHistory = SystemStatus.ramHistory.slice(-30);
            ramSparkline.requestRepaint();
        }
    }

    readonly property color usageColor: SystemCardStyle.usageTierColor(
        SystemStatus.ramPercent, Colors.accent, Colors.warning, Colors.error, 0.75, 0.9)

    ColumnLayout {
        id: ramColumn
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SystemSectionTitle {
                title: "MEMORY"
            }

            Item { Layout.fillWidth: true }

            SharedWidgets.Chip {
                icon: "memory.svg"
                iconColor: root.usageColor
                text: SystemStatus.ramPercentText
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
                icon: "memory.svg"
                label: SystemStatus.ramPercentText
            }

            // Stats column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXS

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Used / Total"
                    value: SystemStatus.ramUsedTotalText
                    valueColor: root.usageColor
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Usage"
                    value: SystemStatus.ramPercentText
                    valueColor: root.usageColor
                }

                SharedWidgets.InfoRow {
                    Layout.fillWidth: true
                    label: "Swap"
                    value: SystemStatus.swapUsage
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
