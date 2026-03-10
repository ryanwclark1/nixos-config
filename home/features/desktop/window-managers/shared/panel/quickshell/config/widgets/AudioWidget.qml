import QtQuick
import Quickshell.Io
import "../modules"
import "../services"

Row {
  id: root
  spacing: 6

  property real volume: 0
  property bool muted: false
  readonly property string tooltipText: {
    if (root.muted) return "Audio muted";
    return "Output volume " + Math.round(root.volume * 100) + "%";
  }

  Process {
    id: volumeProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var text = (this.text || "").trim();
        var match = text.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
        if (!match) {
          root.volume = 0;
          root.muted = false;
          return;
        }

        var parsed = parseFloat(match[1]);
        root.volume = isNaN(parsed) ? 0 : Colors.clamp01(parsed);
        root.muted = text.indexOf("[MUTED]") !== -1;
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: volumeProc.running = true
  }

  CircularGauge {
    value: root.muted ? 0 : root.volume
    color: root.muted ? Colors.error : Colors.fgMain
    icon: root.muted ? "󰝟" : (root.volume > 0.6 ? "󰕾" : (root.volume > 0.3 ? "󰖀" : "󰕿"))
    thickness: 3
    width: 22; height: 22
  }

  Text {
    id: volumeText
    text: {
        if (root.muted) return "Muted";
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
