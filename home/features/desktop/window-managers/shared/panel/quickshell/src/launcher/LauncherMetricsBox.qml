import QtQuick
import QtQuick.Layouts
import "../services"
import "LauncherModeData.js" as ModeData

Rectangle {
    id: root

    required property var metrics
    required property string mode
    required property bool tightMode
    required property string filesBackendLabel
    required property string filesCacheStatsLabel
    required property var modeMetricFn
    property color accentColor: Colors.primary

    signal resetRequested()

    Layout.fillWidth: true
    visible: Config.launcherShowRuntimeMetrics && !root.tightMode
    color: Colors.withAlpha(Colors.surface, 0.76)
    radius: Colors.radiusLarge
    border.color: Colors.withAlpha(root.accentColor, 0.18)
    border.width: 1
    implicitHeight: metricsLayout.implicitHeight + (Colors.spacingM * 2)

    RowLayout {
        id: metricsLayout
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingM

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXXS

            Text {
                text: "Launcher Metrics"
                color: root.accentColor
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.Black
            }

            Text {
                Layout.fillWidth: true
                text: "opens " + root.metrics.opens + " • cache " + root.metrics.cacheHits + "/" + root.metrics.cacheMisses + " • failures " + root.metrics.commandFailures + " • filter avg " + (root.metrics.avgFilterMs || 0) + "ms" + " / last " + (root.metrics.lastFilterMs || 0) + "ms" + (root.mode === "files" ? (" • backend " + root.filesBackendLabel + " • fd/find " + (root.metrics.filesFdLoads || 0) + "/" + (root.metrics.filesFindLoads || 0) + " • fd " + (root.metrics.filesFdAvgMs || 0) + "/" + (root.metrics.filesFdLastMs || 0) + "ms" + " • find " + (root.metrics.filesFindAvgMs || 0) + "/" + (root.metrics.filesFindLastMs || 0) + "ms" + " • resolve " + (root.metrics.filesResolveAvgMs || 0) + "/" + (root.metrics.filesResolveLastMs || 0) + "ms") : "")
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                wrapMode: Text.WordWrap
            }

            Text {
                readonly property var modeStats: root.modeMetricFn(root.mode)
                Layout.fillWidth: true
                text: ModeData.modeInfo(root.mode).label + ": avg " + modeStats.avgLoadMs + "ms" + " • last " + modeStats.lastLoadMs + "ms" + " • failures " + modeStats.failures + (root.mode === "files" ? (" • cache " + root.filesCacheStatsLabel) : "")
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            radius: Colors.radiusPill
            color: Colors.withAlpha(root.accentColor, 0.12)
            border.color: Colors.withAlpha(root.accentColor, 0.3)
            border.width: 1
            implicitHeight: 28
            implicitWidth: metricResetText.implicitWidth + 18

            Text {
                id: metricResetText
                anchors.centerIn: parent
                text: "Reset"
                color: root.accentColor
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.DemiBold
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetRequested()
            }
        }
    }
}
