import QtQuick
import "../../system/sections"
import "../../../services"
import "../../../shared"
import "../../../services/IconHelpers.js" as IconHelpers

Row {
  id: root
  spacing: Appearance.spacingSM * iconScale
  property bool iconOnly: false
  property real iconScale: 1.0
  property real fontScale: 1.0

  readonly property string tooltipText: {
    if (AudioService.outputMuted) return "Audio muted";
    return "Output volume " + Math.round(AudioService.outputVolume * 100) + "%";
  }

  Ref { service: AudioService }

    CircularGauge {
      value: AudioService.outputMuted ? 0 : AudioService.outputVolume
      color: AudioService.outputMuted ? Colors.error : Colors.text
      icon: IconHelpers.audioOutputIcon(AudioService.outputVolume, AudioService.outputMuted, AudioService.outputDeviceType)
      thickness: 3
      width: 22 * root.iconScale; height: 22 * root.iconScale
      iconScale: root.iconScale
    }

  Text {
    id: volumeText
    visible: !root.iconOnly
    text: {
        if (AudioService.outputMuted) return "Muted";
        var v = AudioService.outputVolume;
        if (isNaN(v)) return "0%";
        return Math.round(v * 100) + "%";
    }
    color: Colors.text
    font.pixelSize: Appearance.fontSizeSmall * root.fontScale
    font.weight: Font.DemiBold
    anchors.verticalCenter: parent.verticalCenter
  }
}
