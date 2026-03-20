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

    readonly property int barCount: PanelHelpers.widgetIntegerSetting(widgetInstance, "barCount", 8, 4, 32)
    readonly property var cavaValues: {
        var raw = (SpectrumService && SpectrumService.values) ? SpectrumService.values : [];
        if (raw.length === 0) return new Array(barCount).fill(0);
        if (raw.length === barCount) return raw;

        // Simple downsampling: pick indices evenly
        var result = [];
        for (var i = 0; i < barCount; i++) {
            var idx = Math.floor(i * raw.length / barCount);
            result.push(raw[idx]);
        }
        return result;
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

        Row {
            anchors.centerIn: parent
            spacing: Colors.spacingXXS
            height: 14

            Repeater {
                model: root.cavaValues
                delegate: Rectangle {
                    required property real modelData
                    width: 2
                    height: Math.max(2, modelData * parent.height)
                    radius: 1
                    color: Colors.primary
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on height {
                        NumberAnimation {
                            duration: Colors.durationFlash
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
