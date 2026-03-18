import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU
import "../models/GraphUtils.js" as GU

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

    function paintGraph(canvas, values, strokeColor) {
        GU.paintLineGraph(canvas, values, strokeColor, Colors.withAlpha, { fillAlphaTop: 0.28, fillAlphaBot: 0.04 });
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
        spacing: Colors.spacingM

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "I/O HISTORY"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingWide
                font.capitalization: Font.AllUppercase
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            SharedWidgets.Chip {
                icon: SystemIoTelemetryService.networkHotspot ? "󰀦" : "󰄬"
                iconColor: SystemIoTelemetryService.networkHotspot || SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.success
                text: SystemIoTelemetryService.telemetryStatus.toUpperCase()
                textColor: SystemIoTelemetryService.networkHotspot || SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.success
            }

            SharedWidgets.Chip {
                icon: "󰥔"
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
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

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
            spacing: Colors.spacingS

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
            columnSpacing: Colors.spacingM
            rowSpacing: Colors.spacingM

            Rectangle {
                id: netDownCard
                readonly property real valueWidth: Math.max(72, (metricsGrid.width / Math.max(1, metricsGrid.columns)) * 0.42)
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.primary
                border.width: SystemIoTelemetryService.networkHotspot ? 2 : 1
                implicitHeight: netDownColumn.implicitHeight + Colors.spacingS * 2

                ColumnLayout {
                    id: netDownColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingXS

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "NET DOWN"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(SystemIoTelemetryService.currentNetworkDown); color: Colors.primary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono; Layout.maximumWidth: netDownCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Peak"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(SystemIoTelemetryService.peakNetworkDown); color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: netDownCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Max Label"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(MU.arrayMax(SystemIoTelemetryService.networkHistoryDown)); color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: netDownCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    Canvas {
                        id: downCanvas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Threaded
                        onPaint: root.paintGraph(downCanvas, root.normalizedHistory(SystemIoTelemetryService.networkHistoryDown), Colors.primary)
                    }
                }
            }

            Rectangle {
                id: netUpCard
                readonly property real valueWidth: Math.max(72, (metricsGrid.width / Math.max(1, metricsGrid.columns)) * 0.42)
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.accent
                border.width: SystemIoTelemetryService.networkHotspot ? 2 : 1
                implicitHeight: netUpColumn.implicitHeight + Colors.spacingS * 2

                ColumnLayout {
                    id: netUpColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingXS

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "NET UP"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(SystemIoTelemetryService.currentNetworkUp); color: Colors.accent; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono; Layout.maximumWidth: netUpCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Peak"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(SystemIoTelemetryService.peakNetworkUp); color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: netUpCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Max Label"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(MU.arrayMax(SystemIoTelemetryService.networkHistoryUp)); color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: netUpCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    Canvas {
                        id: upCanvas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Threaded
                        onPaint: root.paintGraph(upCanvas, root.normalizedHistory(SystemIoTelemetryService.networkHistoryUp), Colors.accent)
                    }
                }
            }

            Rectangle {
                id: diskReadCard
                readonly property real valueWidth: Math.max(72, (metricsGrid.width / Math.max(1, metricsGrid.columns)) * 0.42)
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.secondary
                border.width: SystemIoTelemetryService.diskHotspot ? 2 : 1
                implicitHeight: diskReadColumn.implicitHeight + Colors.spacingS * 2

                ColumnLayout {
                    id: diskReadColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingXS

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "DISK READ"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(SystemIoTelemetryService.currentDiskRead); color: Colors.secondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono; Layout.maximumWidth: diskReadCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Peak"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(SystemIoTelemetryService.peakDiskRead); color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: diskReadCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Max Label"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(MU.arrayMax(SystemIoTelemetryService.diskHistoryRead)); color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: diskReadCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    Canvas {
                        id: readCanvas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Threaded
                        onPaint: root.paintGraph(readCanvas, root.normalizedHistory(SystemIoTelemetryService.diskHistoryRead), Colors.secondary)
                    }
                }
            }

            Rectangle {
                id: diskWriteCard
                readonly property real valueWidth: Math.max(72, (metricsGrid.width / Math.max(1, metricsGrid.columns)) * 0.42)
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.warning
                border.width: SystemIoTelemetryService.diskHotspot ? 2 : 1
                implicitHeight: diskWriteColumn.implicitHeight + Colors.spacingS * 2

                ColumnLayout {
                    id: diskWriteColumn
                    anchors.fill: parent
                    anchors.margins: Colors.spacingS
                    spacing: Colors.spacingXS

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "DISK WRITE"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(SystemIoTelemetryService.currentDiskWrite); color: Colors.warning; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono; Layout.maximumWidth: diskWriteCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Peak"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(SystemIoTelemetryService.peakDiskWrite); color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: diskWriteCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Max Label"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillWidth: true }
                        Text { text: MU.formatRate(MU.arrayMax(SystemIoTelemetryService.diskHistoryWrite)); color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: diskWriteCard.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
                    }

                    Canvas {
                        id: writeCanvas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Threaded
                        onPaint: root.paintGraph(writeCanvas, root.normalizedHistory(SystemIoTelemetryService.diskHistoryWrite), Colors.warning)
                    }
                }
            }
        }
    }

    Connections {
        target: SystemIoTelemetryService

        function onNetworkHistoryDownChanged() {
            downCanvas.requestPaint();
        }

        function onNetworkHistoryUpChanged() {
            upCanvas.requestPaint();
        }

        function onDiskHistoryReadChanged() {
            readCanvas.requestPaint();
        }

        function onDiskHistoryWriteChanged() {
            writeCanvas.requestPaint();
        }
    }
}
