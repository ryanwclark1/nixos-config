import QtQuick
import "../services"
import "../widgets" as SharedWidgets

Item {
    id: root
    property real fontScale: 1.0
    property real iconScale: 1.0
    implicitWidth: 32 * iconScale
    implicitHeight: 32 * iconScale

    property var widgetInstance: null
    readonly property var settings: (widgetInstance && widgetInstance.settings) || {}
    readonly property string reactionMode: settings.reactionMode || Config.personalityGifReactionMode

    readonly property bool isMediaMode: reactionMode === "media"
    readonly property bool isCpuMode: reactionMode === "cpu"
    readonly property bool isBeatMode: reactionMode === "beat"

    readonly property bool isCritical: SystemStatus.isCritical
    readonly property real volumeLevel: {
        if (!isBeatMode || SpectrumService.isIdle) return 0.0;
        var sum = 0;
        var vals = SpectrumService.values;
        for (var i = 0; i < vals.length; i++) sum += vals[i];
        return sum / vals.length;
    }

    readonly property bool shouldPlay: {
        if (!Config.personalityGifEnabled) return false;
        if (isCritical) return true; // Panic mode
        if (isMediaMode) return MediaService.isPlaying;
        if (isCpuMode) return SystemStatus.cpuPercent > 0.1;
        if (isBeatMode) return !SpectrumService.isIdle;
        return true;
    }

    readonly property real speedMult: {
        if (isCritical) return 2.5; // High speed when system is struggling
        if (isCpuMode) return 0.5 + (SystemStatus.cpuPercent * 1.5);
        if (isBeatMode) return 0.8 + (root.volumeLevel * 1.2);
        return 1.0;
    }

    Rectangle {
        id: healthIndicator
        anchors.fill: parent
        radius: width / 2
        color: Colors.error
        opacity: root.isCritical ? 0.3 : 0.0
        visible: opacity > 0

        Behavior on opacity { Anim { duration: 500 } }

        SequentialAnimation on opacity {
            running: root.isCritical
            loops: Animation.Infinite
            NumberAnimation { from: 0.1; to: 0.4; duration: 800; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.4; to: 0.1; duration: 800; easing.type: Easing.InOutQuad }
        }
    }

    AnimatedImage {
        id: img
        anchors.fill: parent
        source: Config.personalityGifPath ? "file://" + Config.personalityGifPath : ""
        playing: root.shouldPlay
        speed: root.speedMult
        fillMode: Image.PreserveAspectFit
        opacity: root.shouldPlay ? 1.0 : 0.4

        Behavior on opacity { Anim {} }

        // Panic shake when critical
        NumberAnimation on x {
            running: root.isCritical
            loops: Animation.Infinite
            from: -1; to: 1; duration: 50
        }

        // Placeholder if no path set
        SharedWidgets.SvgIcon {
            visible: !img.source
            anchors.centerIn: parent
            source: root.isCritical ? "alert.svg" : "chat.svg"
            size: 20
            color: root.isCritical ? Colors.error : (root.shouldPlay ? Colors.primary : Colors.textDisabled)
        }
    }
}
