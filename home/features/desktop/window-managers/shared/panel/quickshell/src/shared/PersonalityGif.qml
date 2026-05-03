import QtQuick
import "../services"
import "../widgets" as SharedWidgets

Item {
    id: root
    implicitWidth: 32
    implicitHeight: 32

    property var widgetInstance: null
    readonly property var settings: (widgetInstance && widgetInstance.settings) || {}
    readonly property string reactionMode: settings.reactionMode || Config.personalityGifReactionMode

    readonly property bool isMediaMode: reactionMode === "media"
    readonly property bool isCpuMode: reactionMode === "cpu"
    readonly property bool isBeatMode: reactionMode === "beat"

    readonly property bool shouldPlay: {
        if (!Config.personalityGifEnabled) return false;
        if (isMediaMode) return MediaService.isPlaying;
        if (isCpuMode) return SystemStatus.cpuPercent > 0.1;
        if (isBeatMode) return !SpectrumService.isIdle;
        return true;
    }

    readonly property real speedMult: {
        if (isCpuMode) return 0.5 + (SystemStatus.cpuPercent * 1.5);
        if (isBeatMode) return 1.0; // could scale with volume
        return 1.0;
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

        // Placeholder if no path set
        SharedWidgets.SvgIcon {
            visible: !img.source
            anchors.centerIn: parent
            source: "chat.svg"
            size: 20
            color: root.shouldPlay ? Colors.primary : Colors.textDisabled
        }
    }
}
