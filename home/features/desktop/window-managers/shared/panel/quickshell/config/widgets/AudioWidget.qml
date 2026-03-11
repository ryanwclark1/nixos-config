import QtQuick
import "../modules"
import "../services"

Row {
  id: root
  spacing: 6

  readonly property string tooltipText: {
    if (AudioService.outputMuted) return "Audio muted";
    return "Output volume " + Math.round(AudioService.outputVolume * 100) + "%";
  }

  Component.onCompleted: AudioService.subscribe()
  Component.onDestruction: AudioService.unsubscribe()

  CircularGauge {
    value: AudioService.outputMuted ? 0 : AudioService.outputVolume
    color: AudioService.outputMuted ? Colors.error : Colors.fgMain
    icon: AudioService.outputMuted ? "󰝟" : (AudioService.outputVolume > 0.6 ? "󰕾" : (AudioService.outputVolume > 0.3 ? "󰖀" : "󰕿"))
    thickness: 3
    width: 22; height: 22
  }

  Text {
    id: volumeText
    text: {
        if (AudioService.outputMuted) return "Muted";
        var v = AudioService.outputVolume;
        if (isNaN(v)) return "0%";
        return Math.round(v * 100) + "%";
    }
    color: Colors.fgMain
    font.pixelSize: 13
    font.weight: Font.Bold
    anchors.verticalCenter: parent.verticalCenter
  }
}
