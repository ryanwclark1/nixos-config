import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: ioColumn.implicitHeight + root.pad * 2
    property int _clockTick: 0

    SharedWidgets.Ref {
        service: SystemIoTelemetryService
    }

    function normalizedHistory(values) {
        var raw = values || [];
        var maxValue = Math.max(1, MU.arrayMax(raw));
        var normalized = [];
        for (var i = 0; i < raw.length; ++i)
            normalized.push(Number(raw[i] || 0) / maxValue);
        return normalized;
    }

    onVisibleChanged: {
        if (visible)
            SystemIoTelemetryService.refreshMetadata();
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        onTriggered: root._clockTick = root._clockTick + 1
    }

    ColumnLayout {
        id: ioColumn
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "I/O HISTORY"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
                font.capitalization: Font.AllUppercase
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            SharedWidgets.Chip {
                icon: SystemIoTelemetryService.networkHotspot ? "󰀦" : "󰄬"
                iconColor: SystemIoTelemetryService.networkHotspot || SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.success
                text: SystemIoTelemetryService.telemetryStatus.toUpperCase()
                textColor: SystemIoTelemetryService.networkHotspot || SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.success
            }

            SharedWidgets.Chip {
                icon: "clock.svg"
                iconColor: Colors.textSecondary
                text: "Meta " + MU.formatAge(SystemIoTelemetryService.metadataLastRefreshMs, root._clockTick)
                textColor: Colors.textSecondary
            }
        }

        Text {
            Layout.fillWidth: true
            visible: SystemIoTelemetryService.telemetryMessage !== ""
            text: SystemIoTelemetryService.telemetryMessage
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            SharedWidgets.Chip {
                visible: SystemIoTelemetryService.selectedInterface !== ""
                icon: SystemIoTelemetryService.networkDegraded ? "󰀦" : "󰈀"
                iconColor: SystemIoTelemetryService.networkDegraded ? Colors.warning : Colors.primary
                text: String(SystemIoTelemetryService.selectedInterface || "").toUpperCase() + "  " + MU.formatAge(SystemIoTelemetryService.networkLastSampleMs, root._clockTick)
                textColor: SystemIoTelemetryService.networkDegraded ? Colors.warning : Colors.primary
            }

            SharedWidgets.Chip {
                visible: SystemIoTelemetryService.selectedDiskDevice !== ""
                icon: SystemIoTelemetryService.diskDegraded ? "󰀦" : "󰋊"
                iconColor: SystemIoTelemetryService.diskDegraded ? Colors.warning : Colors.secondary
                text: String(SystemIoTelemetryService.selectedDiskDevice || "").toUpperCase() + "  " + MU.formatAge(SystemIoTelemetryService.diskLastSampleMs, root._clockTick)
                textColor: SystemIoTelemetryService.diskDegraded ? Colors.warning : Colors.secondary
            }

            Repeater {
                model: SystemIoTelemetryService.interfaces || []

                delegate: SharedWidgets.FilterChip {
                    required property var modelData
                    label: String(modelData || "").toUpperCase()
                    selected: SystemIoTelemetryService.selectedInterface === String(modelData || "")
                    onClicked: SystemIoTelemetryService.setSelectedInterface(String(modelData || ""))
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Appearance.spacingS

            Repeater {
                model: SystemIoTelemetryService.diskDevices || []

                delegate: SharedWidgets.FilterChip {
                    required property var modelData
                    label: String(modelData || "").toUpperCase()
                    selected: SystemIoTelemetryService.selectedDiskDevice === String(modelData || "")
                    onClicked: SystemIoTelemetryService.setSelectedDiskDevice(String(modelData || ""))
                }
            }
        }

        GridLayout {
            id: metricsGrid
            Layout.fillWidth: true
            columns: width >= 420 ? 2 : 1
            columnSpacing: Appearance.spacingM
            rowSpacing: Appearance.spacingM

            IoMetricCard {
                label: "NET DOWN"
                accentColor: Colors.primary
                currentFormatted: MU.formatRate(SystemIoTelemetryService.currentNetworkDown)
                peakFormatted: MU.formatRate(SystemIoTelemetryService.peakNetworkDown)
                maxFormatted: MU.formatRate(MU.arrayMax(SystemIoTelemetryService.networkHistoryDown))
                normalizedData: root.normalizedHistory(SystemIoTelemetryService.networkHistoryDown)
                hotspot: SystemIoTelemetryService.networkHotspot
                gridWidth: metricsGrid.width
                gridColumns: metricsGrid.columns
            }

            IoMetricCard {
                label: "NET UP"
                accentColor: Colors.accent
                currentFormatted: MU.formatRate(SystemIoTelemetryService.currentNetworkUp)
                peakFormatted: MU.formatRate(SystemIoTelemetryService.peakNetworkUp)
                maxFormatted: MU.formatRate(MU.arrayMax(SystemIoTelemetryService.networkHistoryUp))
                normalizedData: root.normalizedHistory(SystemIoTelemetryService.networkHistoryUp)
                hotspot: SystemIoTelemetryService.networkHotspot
                gridWidth: metricsGrid.width
                gridColumns: metricsGrid.columns
            }

            IoMetricCard {
                label: "DISK READ"
                accentColor: Colors.secondary
                currentFormatted: MU.formatRate(SystemIoTelemetryService.currentDiskRead)
                peakFormatted: MU.formatRate(SystemIoTelemetryService.peakDiskRead)
                maxFormatted: MU.formatRate(MU.arrayMax(SystemIoTelemetryService.diskHistoryRead))
                normalizedData: root.normalizedHistory(SystemIoTelemetryService.diskHistoryRead)
                hotspot: SystemIoTelemetryService.diskHotspot
                gridWidth: metricsGrid.width
                gridColumns: metricsGrid.columns
            }

            IoMetricCard {
                label: "DISK WRITE"
                accentColor: Colors.warning
                currentFormatted: MU.formatRate(SystemIoTelemetryService.currentDiskWrite)
                peakFormatted: MU.formatRate(SystemIoTelemetryService.peakDiskWrite)
                maxFormatted: MU.formatRate(MU.arrayMax(SystemIoTelemetryService.diskHistoryWrite))
                normalizedData: root.normalizedHistory(SystemIoTelemetryService.diskHistoryWrite)
                hotspot: SystemIoTelemetryService.diskHotspot
                gridWidth: metricsGrid.width
                gridColumns: metricsGrid.columns
            }
        }
    }

}
