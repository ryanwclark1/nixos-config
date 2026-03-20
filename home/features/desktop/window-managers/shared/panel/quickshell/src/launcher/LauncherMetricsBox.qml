import QtQuick
import QtQuick.Layouts
import "../services"
import "LauncherModeData.js" as ModeData

Rectangle {
    id: root

    required property var metrics
    required property string mode
    required property bool tightMode
    required property bool showMetrics
    required property string filesBackendLabel
    required property string filesCacheStatsLabel
    required property var modeMetricFn
    property color accentColor: Colors.primary

    signal resetRequested()

    Layout.fillWidth: true
    visible: root.showMetrics && !root.tightMode
    color: Colors.withAlpha(Colors.surface, 0.76)
    radius: Appearance.radiusLarge
    border.color: Colors.withAlpha(root.accentColor, 0.18)
    border.width: 1
    readonly property var modeStats: root.modeMetricFn(root.mode)
    readonly property string summaryText: {
        var parts = [
            "opens " + (root.metrics.opens || 0),
            ModeData.modeInfo(root.mode).label + " avg " + (modeStats.avgLoadMs || 0) + "ms",
            "filter avg " + (root.metrics.avgFilterMs || 0) + "ms",
            "failures " + (modeStats.failures || 0)
        ];
        if (root.mode === "files")
            parts.push("backend " + root.filesBackendLabel);
        return parts.join(" • ");
    }
    implicitHeight: metricsLayout.implicitHeight + (Appearance.spacingS * 2)

    RowLayout {
        id: metricsLayout
        anchors.fill: parent
        anchors.margins: Appearance.spacingS
        spacing: Appearance.spacingS

        Rectangle {
            radius: Appearance.radiusPill
            color: Colors.withAlpha(root.accentColor, 0.12)
            border.color: Colors.withAlpha(root.accentColor, 0.3)
            border.width: 1
            implicitHeight: 22
            implicitWidth: metricsTitle.implicitWidth + 14

            Text {
                id: metricsTitle
                anchors.centerIn: parent
                text: "Launcher Metrics"
                color: root.accentColor
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.summaryText
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Rectangle {
            radius: Appearance.radiusPill
            color: Colors.withAlpha(root.accentColor, 0.12)
            border.color: Colors.withAlpha(root.accentColor, 0.3)
            border.width: 1
            implicitHeight: 24
            implicitWidth: metricResetText.implicitWidth + 16

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetRequested()
            }

            Text {
                id: metricResetText
                anchors.centerIn: parent
                text: "Reset"
                color: root.accentColor
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.DemiBold
            }
        }
    }
}
