import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../models/GraphUtils.js" as GU

Rectangle {
    id: root

    property string label: ""
    property color accentColor: Colors.primary
    property string currentFormatted: ""
    property string peakFormatted: ""
    property string maxFormatted: ""
    property var normalizedData: []
    property bool hotspot: false
    property real gridWidth: 0
    property int gridColumns: 1

    readonly property real valueWidth: Math.max(72, (gridWidth / Math.max(1, gridColumns)) * 0.42)

    Layout.fillWidth: true
    radius: Colors.radiusSmall
    color: Colors.cardSurface
    border.color: root.accentColor
    border.width: root.hotspot ? 2 : 1
    implicitHeight: cardColumn.implicitHeight + Colors.spacingS * 2

    onNormalizedDataChanged: graphCanvas.requestPaint()

    ColumnLayout {
        id: cardColumn
        anchors.fill: parent
        anchors.margins: Colors.spacingS
        spacing: Colors.spacingXS

        RowLayout {
            Layout.fillWidth: true
            Text { text: root.label; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
            Item { Layout.fillWidth: true }
            Text { text: root.currentFormatted; color: root.accentColor; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.family: Colors.fontMono; Layout.maximumWidth: root.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Peak"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
            Item { Layout.fillWidth: true }
            Text { text: root.peakFormatted; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: root.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Max Seen"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
            Item { Layout.fillWidth: true }
            Text { text: root.maxFormatted; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.family: Colors.fontMono; Layout.maximumWidth: root.valueWidth; horizontalAlignment: Text.AlignRight; elide: Text.ElideLeft }
        }

        Canvas {
            id: graphCanvas
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Threaded
            onPaint: GU.paintLineGraph(graphCanvas, root.normalizedData, root.accentColor, Colors.withAlpha, { fillAlphaTop: 0.28, fillAlphaBot: 0.04 })
        }
    }
}
