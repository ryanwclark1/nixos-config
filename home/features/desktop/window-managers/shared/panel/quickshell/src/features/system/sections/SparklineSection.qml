import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../models/GraphUtils.js" as GU

ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: Colors.spacingXS

    property string label: "HISTORY"
    property string currentText: ""
    property var history: []
    property color accentColor: Colors.primary
    property int canvasHeight: 52
    property var graphOptions: ({ yScale: 0.9 })

    signal repaintRequested()

    function requestRepaint() { _canvas.requestPaint(); }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: root.label
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Bold
            font.letterSpacing: Colors.letterSpacingWide
            Layout.fillWidth: true
        }
        Text {
            visible: root.currentText !== ""
            text: root.currentText
            color: root.accentColor
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Bold
            font.family: Colors.fontMono
        }
    }

    Canvas {
        id: _canvas
        Layout.fillWidth: true
        Layout.preferredHeight: root.canvasHeight
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Threaded
        onPaint: GU.paintLineGraph(_canvas, root.history, root.accentColor, Colors.withAlpha, root.graphOptions)
    }
}
