import QtQuick
import Quickshell.Services.Pipewire
import "../modules"
import "../services"

Row {
  id: root
  spacing: 6

  property var sink: Pipewire.defaultAudioSink
  property real volume: (sink && sink.audio && !isNaN(sink.audio.volume)) ? sink.audio.volume : 0
  property bool muted: (sink && sink.audio) ? sink.audio.muted : false

  CircularGauge {
    value: muted ? 0 : root.volume
    color: muted ? Colors.error : Colors.fgMain
    icon: muted ? "󰝟" : (root.volume > 0.6 ? "󰕾" : (root.volume > 0.3 ? "󰖀" : "󰕿"))
    thickness: 3
    width: 22; height: 22
  }

  Text {
    id: volumeText
    text: {
        if (muted) return "Muted";
        var v = root.volume;
        if (isNaN(v)) return "0%";
        return Math.round(v * 100) + "%";
    }
    color: Colors.fgMain
    font.pixelSize: 13
    font.weight: Font.Bold
    anchors.verticalCenter: parent.verticalCenter
  }
}
