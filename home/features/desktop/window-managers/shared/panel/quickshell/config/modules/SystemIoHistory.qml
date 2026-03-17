import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    property var downHistory: new Array(40).fill(0)
    property var upHistory: new Array(40).fill(0)
    property var readHistory: new Array(40).fill(0)
    property var writeHistory: new Array(40).fill(0)

    property real lastRx: 0
    property real lastTx: 0
    property real lastReadSectors: 0
    property real lastWriteSectors: 0

    property real maxDown: 1048576
    property real maxUp: 1048576
    property real maxRead: 1048576
    property real maxWrite: 1048576

    property string activeInterface: "offline"
    property string diskDevice: "disk"
    property string currentDown: "0 KB/s"
    property string currentUp: "0 KB/s"
    property string currentRead: "0 KB/s"
    property string currentWrite: "0 KB/s"

    Layout.fillWidth: true
    Layout.preferredHeight: ioColumn.implicitHeight + root.pad * 2

    function pushHistory(history, value) {
        var next = history.slice();
        next.shift();
        next.push(value);
        return next;
    }

    function formatSpeed(bytes) {
        if (bytes < 1024)
            return Math.round(bytes) + " B/s";
        if (bytes < 1048576)
            return (bytes / 1024).toFixed(1) + " KB/s";
        if (bytes < 1073741824)
            return (bytes / 1048576).toFixed(1) + " MB/s";
        return (bytes / 1073741824).toFixed(2) + " GB/s";
    }

    function paintGraph(canvas, data, strokeColor) {
        if (!data.length || canvas.width <= 0 || canvas.height <= 0)
            return;

        var ctx = canvas.getContext("2d");
        ctx.reset();
        var w = data.length > 1 ? canvas.width / (data.length - 1) : canvas.width;

        var grad = ctx.createLinearGradient(0, 0, 0, canvas.height);
        grad.addColorStop(0, Colors.withAlpha(strokeColor, 0.25));
        grad.addColorStop(1, Colors.withAlpha(strokeColor, 0.02));

        ctx.beginPath();
        ctx.moveTo(0, canvas.height);
        for (var i = 0; i < data.length; ++i)
            ctx.lineTo(i * w, canvas.height - (data[i] * canvas.height));
        ctx.lineTo(canvas.width, canvas.height);
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.beginPath();
        for (var j = 0; j < data.length; ++j) {
            var x = j * w;
            var y = canvas.height - (data[j] * canvas.height);
            if (j === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 2;
        ctx.stroke();
    }

    SharedWidgets.CommandPoll {
        id: ioPoll
        interval: 1000
        running: root.visible
        command: [
            "sh",
            "-c",
            "iface=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}'); "
            + "if [ -z \"$iface\" ]; then iface=$(ip -o link show up 2>/dev/null | awk -F': ' '$2 != \"lo\" {print $2; exit}'); fi; "
            + "rx=0; tx=0; "
            + "if [ -n \"$iface\" ]; then "
            + "rx=$(cat \"/sys/class/net/$iface/statistics/rx_bytes\" 2>/dev/null || echo 0); "
            + "tx=$(cat \"/sys/class/net/$iface/statistics/tx_bytes\" 2>/dev/null || echo 0); "
            + "fi; "
            + "root_src=$(df / --output=source 2>/dev/null | tail -n 1 | sed 's|^/dev/||'); "
            + "root_base=$(printf '%s' \"$root_src\" | sed 's/[0-9]\\+$//' | sed 's/p$//'); "
            + "if [ -z \"$root_base\" ]; then root_base=$(lsblk -no pkname / 2>/dev/null | head -n1); fi; "
            + "if [ -z \"$root_base\" ]; then root_base=\"$root_src\"; fi; "
            + "read_sec=0; write_sec=0; "
            + "if [ -n \"$root_base\" ]; then "
            + "disk_line=$(awk '$3 == \"" + "\"' /proc/diskstats 2>/dev/null); "
            + "fi; "
            + "disk_line=$(awk -v dev=\"$root_base\" '$3 == dev {print; exit}' /proc/diskstats 2>/dev/null); "
            + "if [ -n \"$disk_line\" ]; then "
            + "read_sec=$(printf '%s\\n' \"$disk_line\" | awk '{print $6}'); "
            + "write_sec=$(printf '%s\\n' \"$disk_line\" | awk '{print $10}'); "
            + "fi; "
            + "printf 'IFACE=%s\\nRX=%s\\nTX=%s\\nDISK=%s\\nREAD_SEC=%s\\nWRITE_SEC=%s\\n' \"$iface\" \"$rx\" \"$tx\" \"$root_base\" \"$read_sec\" \"$write_sec\""
        ]
        parse: function(out) {
            var lines = String(out || "").trim().split("\n");
            var data = {};
            for (var i = 0; i < lines.length; ++i) {
                var line = String(lines[i] || "");
                var idx = line.indexOf("=");
                if (idx === -1)
                    continue;
                data[line.substring(0, idx)] = line.substring(idx + 1);
            }
            return data;
        }
        onUpdated: {
            var data = ioPoll.value || {};
            root.activeInterface = String(data.IFACE || "offline");
            root.diskDevice = String(data.DISK || "disk");

            var rx = parseFloat(data.RX || 0) || 0;
            var tx = parseFloat(data.TX || 0) || 0;
            var readSectors = parseFloat(data.READ_SEC || 0) || 0;
            var writeSectors = parseFloat(data.WRITE_SEC || 0) || 0;

            if (root.lastRx > 0) {
                var diffRx = Math.max(0, rx - root.lastRx);
                var diffTx = Math.max(0, tx - root.lastTx);
                root.currentDown = root.formatSpeed(diffRx);
                root.currentUp = root.formatSpeed(diffTx);
                root.maxDown = diffRx > root.maxDown ? diffRx : Math.max(1048576, root.maxDown * 0.99);
                root.maxUp = diffTx > root.maxUp ? diffTx : Math.max(1048576, root.maxUp * 0.99);
                root.downHistory = root.pushHistory(root.downHistory, Math.min(1, diffRx / root.maxDown));
                root.upHistory = root.pushHistory(root.upHistory, Math.min(1, diffTx / root.maxUp));
                downCanvas.requestPaint();
                upCanvas.requestPaint();
            }

            if (root.lastReadSectors > 0) {
                var diffRead = Math.max(0, readSectors - root.lastReadSectors) * 512;
                var diffWrite = Math.max(0, writeSectors - root.lastWriteSectors) * 512;
                root.currentRead = root.formatSpeed(diffRead);
                root.currentWrite = root.formatSpeed(diffWrite);
                root.maxRead = diffRead > root.maxRead ? diffRead : Math.max(1048576, root.maxRead * 0.99);
                root.maxWrite = diffWrite > root.maxWrite ? diffWrite : Math.max(1048576, root.maxWrite * 0.99);
                root.readHistory = root.pushHistory(root.readHistory, Math.min(1, diffRead / root.maxRead));
                root.writeHistory = root.pushHistory(root.writeHistory, Math.min(1, diffWrite / root.maxWrite));
                readCanvas.requestPaint();
                writeCanvas.requestPaint();
            }

            root.lastRx = rx;
            root.lastTx = tx;
            root.lastReadSectors = readSectors;
            root.lastWriteSectors = writeSectors;
        }
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
                icon: NetworkService.networkIcon()
                iconColor: Colors.primary
                text: root.activeInterface !== "" ? root.activeInterface.toUpperCase() : "OFFLINE"
                textColor: Colors.primary
            }

            SharedWidgets.Chip {
                icon: "󰋊"
                iconColor: Colors.secondary
                text: root.diskDevice !== "" ? root.diskDevice.toUpperCase() : "DISK"
                textColor: Colors.secondary
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
                border.color: Colors.border
                border.width: 1
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
                        Text { text: root.currentDown; color: Colors.primary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono }
                    }

                    Canvas {
                        id: downCanvas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Threaded
                        onPaint: root.paintGraph(downCanvas, root.downHistory, Colors.primary)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.45)
                border.color: Colors.border
                border.width: 1
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
                        Text { text: root.currentUp; color: Colors.accent; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono }
                    }

                    Canvas {
                        id: upCanvas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Threaded
                        onPaint: root.paintGraph(upCanvas, root.upHistory, Colors.accent)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.45)
                border.color: Colors.border
                border.width: 1
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
                        Text { text: root.currentRead; color: Colors.secondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono }
                    }

                    Canvas {
                        id: readCanvas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Threaded
                        onPaint: root.paintGraph(readCanvas, root.readHistory, Colors.secondary)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: Colors.radiusSmall
                color: Colors.withAlpha(Colors.surface, 0.45)
                border.color: Colors.border
                border.width: 1
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
                        Text { text: root.currentWrite; color: Colors.warning; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono }
                    }

                    Canvas {
                        id: writeCanvas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Threaded
                        onPaint: root.paintGraph(writeCanvas, root.writeHistory, Colors.warning)
                    }
                }
            }
        }
    }
}
