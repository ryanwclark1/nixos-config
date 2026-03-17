import QtQuick
import "../system/sections"
import "../services"

Row {
  id: root
  spacing: Colors.spacingSM
  property bool iconOnly: false

  readonly property string tooltipText: {
    if (AudioService.outputMuted) return "Audio muted";
    return "Output volume " + Math.round(AudioService.outputVolume * 100) + "%";
  }

  Ref { service: AudioService }

  CircularGauge {
    value: AudioService.outputMuted ? 0 : AudioService.outputVolume
    color: AudioService.outputMuted ? Colors.error : Colors.text
    icon: {
      if (AudioService.outputMuted) return "󰝟";
      if (AudioService.outputDeviceType === "bluetooth") return "󰂯";
      if (AudioService.outputDeviceType === "headphone") return "󰋋";
      return AudioService.outputVolume > 0.6 ? "󰕾" : (AudioService.outputVolume > 0.3 ? "󰖀" : "󰕿");
    }
    thickness: 3
    width: 22; height: 22
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
    font.pixelSize: Colors.fontSizeSmall
    font.weight: Font.DemiBold
    anchors.verticalCenter: parent.verticalCenter
  }
}
