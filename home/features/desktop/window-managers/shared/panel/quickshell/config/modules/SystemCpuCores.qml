import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    property var coreUsages: []
    property var _previousTotals: ({})
    property var _previousIdles: ({})

    Layout.fillWidth: true
    Layout.preferredHeight: coreColumn.implicitHeight + root.pad * 2

    function parseSnapshot(out) {
        var lines = String(out || "").trim().split("\n");
        var nextCoreUsages = [];
        var nextTotals = Object.assign({}, _previousTotals || {});
        var nextIdles = Object.assign({}, _previousIdles || {});

        for (var i = 0; i < lines.length; ++i) {
            var line = String(lines[i] || "").trim();
            if (line === "")
                continue;

            var parts = line.split(/\s+/);
            if (parts.length < 6)
                continue;

            var name = parts[0];
            var user = parseInt(parts[1], 10) || 0;
            var nice = parseInt(parts[2], 10) || 0;
            var system = parseInt(parts[3], 10) || 0;
            var idle = parseInt(parts[4], 10) || 0;
            var iowait = parseInt(parts[5], 10) || 0;
            var irq = parseInt(parts[6], 10) || 0;
            var softirq = parseInt(parts[7], 10) || 0;
            var steal = parseInt(parts[8], 10) || 0;

            var idleTotal = idle + iowait;
            var total = user + nice + system + idle + iowait + irq + softirq + steal;
            var previousTotal = Number(nextTotals[name] || 0);
            var previousIdle = Number(nextIdles[name] || 0);
            var diffTotal = total - previousTotal;
            var diffIdle = idleTotal - previousIdle;
            var usage = diffTotal > 0 ? (1 - (diffIdle / diffTotal)) : 0;

            nextTotals[name] = total;
            nextIdles[name] = idleTotal;

            nextCoreUsages.push({
                name: name.toUpperCase(),
                shortName: name.replace("cpu", "C"),
                usage: Colors.clamp01(usage)
            });
        }

        _previousTotals = nextTotals;
        _previousIdles = nextIdles;
        coreUsages = nextCoreUsages;
    }

    CommandPoll {
        id: statPoll
        interval: 1500
        running: root.visible
        command: ["sh", "-c", "grep '^cpu[0-9][0-9]* ' /proc/stat 2>/dev/null"]
        parse: function(out) {
            return String(out || "");
        }
        onUpdated: root.parseSnapshot(statPoll.value)
    }

    ColumnLayout {
        id: coreColumn
        Layout.fillWidth: true
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "CPU CORES"
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
                icon: ""
                iconColor: Colors.primary
                text: String(coreUsages.length) + " cores"
                textColor: Colors.primary
            }
        }

        GridLayout {
            id: coreGrid
            Layout.fillWidth: true
            columns: width >= 420 ? (coreUsages.length >= 12 ? 4 : 3) : (width >= 280 ? 2 : 1)
            columnSpacing: Colors.spacingM
            rowSpacing: Colors.spacingS

            Repeater {
                model: root.coreUsages

                delegate: Rectangle {
                    required property var modelData
                    id: coreCell
                    readonly property real valueWidth: Math.max(34, (coreGrid.width / Math.max(1, coreGrid.columns)) * 0.34)
                    Layout.fillWidth: true
                    radius: Colors.radiusSmall
                    color: Colors.cardSurface
                    border.color: Colors.withAlpha(Colors.border, 0.75)
                    border.width: 1
                    implicitHeight: coreInner.implicitHeight + Colors.spacingS * 2

                    ColumnLayout {
                        id: coreInner
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: Colors.spacingXS

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: modelData.shortName
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Bold
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Math.round(modelData.usage * 100) + "%"
                                color: modelData.usage >= 0.8 ? Colors.error : (modelData.usage >= 0.5 ? Colors.warning : Colors.primary)
                                font.pixelSize: Colors.fontSizeXS
                                font.family: Colors.fontMono
                                Layout.maximumWidth: coreCell.valueWidth
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                            }
                        }

                        SharedWidgets.MiniProgressBar {
                            value: modelData.usage
                            barColor: modelData.usage >= 0.8 ? Colors.error : (modelData.usage >= 0.5 ? Colors.warning : Colors.primary)
                        }
                    }
                }
            }
        }
    }
}
