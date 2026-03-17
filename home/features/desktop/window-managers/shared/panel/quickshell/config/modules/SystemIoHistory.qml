import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: ioColumn.implicitHeight + root.pad * 2

    SharedWidgets.Ref {
        service: SystemIoTelemetryService
    }

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

    function arrayMax(values) {
        var maxValue = 0;
        for (var i = 0; i < values.length; ++i)
            maxValue = Math.max(maxValue, Number(values[i] || 0));
        return maxValue;
    }

    function normalizedHistory(values) {
        var raw = values || [];
        var maxValue = Math.max(1, arrayMax(raw));
        var normalized = [];
        for (var i = 0; i < raw.length; ++i)
            normalized.push(Number(raw[i] || 0) / maxValue);
        return normalized;
    }

    function paintGraph(canvas, values, strokeColor) {
        if (!values.length || canvas.width <= 0 || canvas.height <= 0)
            return;

        var ctx = canvas.getContext("2d");
        ctx.reset();
        var w = values.length > 1 ? canvas.width / (values.length - 1) : canvas.width;

        var grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
        grad.addColorStop(0, Colors.withAlpha(strokeColor, 0.28));
        grad.addColorStop(1, Colors.withAlpha(strokeColor, 0.04));

        ctx.beginPath();
        ctx.moveTo(0, canvas.height);
        for (var i = 0; i < values.length; ++i)
            ctx.lineTo(i * w, canvas.height - (values[i] * canvas.height));
        ctx.lineTo(canvas.width, canvas.height);
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.beginPath();
        for (var j = 0; j < values.length; ++j) {
            var x = j * w;
            var y = canvas.height - (values[j] * canvas.height);
            if (j === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 2;
        ctx.stroke();
    }

    onVisibleChanged: {
        if (visible)
            SystemIoTelemetryService.refreshMetadata();
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

            SharedWidgets.Chip {
                icon: SystemIoTelemetryService.networkHotspot ? "󰀦" : "󰄬"
                iconColor: SystemIoTelemetryService.networkHotspot || SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.success
                text: SystemIoTelemetryService.telemetryStatus.toUpperCase()
                textColor: SystemIoTelemetryService.networkHotspot || SystemIoTelemetryService.diskHotspot ? Colors.warning : Colors.success
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
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Colors.spacingM
            rowSpacing: Colors.spacingM

            Rectangle {
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.45)
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
                        Text { text: "NET DOWN"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Text { text: root.formatRate(SystemIoTelemetryService.currentNetworkDown); color: Colors.primary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono }
                    }

                    Text {
                        text: "Peak " + root.formatRate(SystemIoTelemetryService.peakNetworkDown)
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        font.family: Colors.fontMono
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
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.45)
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
                        Text { text: "NET UP"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Text { text: root.formatRate(SystemIoTelemetryService.currentNetworkUp); color: Colors.accent; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono }
                    }

                    Text {
                        text: "Peak " + root.formatRate(SystemIoTelemetryService.peakNetworkUp)
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        font.family: Colors.fontMono
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
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.45)
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
                        Text { text: "DISK READ"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Text { text: root.formatRate(SystemIoTelemetryService.currentDiskRead); color: Colors.secondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono }
                    }

                    Text {
                        text: "Peak " + root.formatRate(SystemIoTelemetryService.peakDiskRead)
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        font.family: Colors.fontMono
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
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.45)
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
                        Text { text: "DISK WRITE"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Text { text: root.formatRate(SystemIoTelemetryService.currentDiskWrite); color: Colors.warning; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono }
                    }

                    Text {
                        text: "Peak " + root.formatRate(SystemIoTelemetryService.peakDiskWrite)
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                        font.family: Colors.fontMono
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
