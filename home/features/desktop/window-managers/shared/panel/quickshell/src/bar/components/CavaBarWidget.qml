import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

Item {
    id: root
    property var widgetInstance: null
    required property var anchorWindow
    property bool vertical: false
    property bool isActive: false
    signal clicked(var triggerItem)

    readonly property string fullCavaData: {
        var vals = (SpectrumService && SpectrumService.values) ? SpectrumService.values : [];
        var blocks = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"];
        var s = "";
        for (var i = 0; i < vals.length; ++i) {
            var idx = Math.min(7, Math.floor(vals[i] * 8));
            s += blocks[Math.max(0, idx)];
        }
        return s;
    }
    readonly property string cavaBarText: {
        var full = root.fullCavaData || "";
        var barCount = PanelHelpers.widgetIntegerSetting(widgetInstance, "barCount", 8, 4, 20);
        var fallback = "▁▂▃▄▅▆▇█";
        var source = full.length > 0 ? full : fallback;
        return source.length >= barCount ? source.substring(0, barCount) : source;
    }

    visible: !vertical && MediaService.currentPlayer !== null && MediaService.isPlaying
    implicitWidth: cavaPill.width
    implicitHeight: cavaPill.height

    SharedWidgets.Ref {
        service: SpectrumService
        active: root.visible
    }

    SharedWidgets.BarPill {
        id: cavaPill
        anchors.centerIn: parent
        isActive: root.isActive
        normalColor: "transparent"
        anchorWindow: root.anchorWindow
        tooltipText: "Audio visualizer"
        cursorShape: Qt.PointingHandCursor
        clip: true
        onClicked: root.clicked(this)

        Text {
            text: root.cavaBarText
            color: Colors.primary
            font.pixelSize: Colors.fontSizeMedium
        }
    }
}
