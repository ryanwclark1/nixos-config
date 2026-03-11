import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris

pragma Singleton

QtObject {
  id: root

  property string cpuTemp: "--"
  property string gpuTemp: "--"
  property string cpuUsage: "0%"
  property string ramUsage: "0GB"
  property string gpuUsage: "0%"
  property real cpuPercent: 0.0
  property real ramPercent: 0.0
  property real gpuPercent: 0.0
  property real brightness: 0.0

  property int pollIntervalMs: 2000

  // Subscriber-based polling: only runs when at least one consumer is active.
  // Consumers should increment on visible and decrement on hidden.
  property int subscriberCount: 0

  function subscribe() { subscriberCount++; }
  function unsubscribe() { subscriberCount = Math.max(0, subscriberCount - 1); }

  function formatTemp(rawValue) {
    var parsed = parseFloat(rawValue);
    return isNaN(parsed) ? "--" : Math.round(parsed) + "°C";
  }

  property Process statsProc: Process {
    command: [
      "sh",
      "-c",
      "cpu_temp=$(sensors 2>/dev/null | awk '/Tctl:/ {gsub(/[+°C]/, \"\", $2); print $2; exit}'); "
      + "gpu_temp=$(sensors 2>/dev/null | awk '/edge:/ {gsub(/[+°C]/, \"\", $2); print $2; exit}'); "
      + "cpu_usage=$(top -bn1 | awk '/Cpu\\\\(s\\\\):/ {printf \"%d\", 100 - $8}'); "
      + "gpu_card=$(for c in /sys/class/drm/card[0-9]*/device/mem_info_vram_total; do "
      + "echo \"$(cat \"$c\" 2>/dev/null || echo 0) $(dirname \"$(dirname \"$c\")\")\" ; done 2>/dev/null "
      + "| sort -rn | head -1 | awk '{print $2}'); "
      + "gpu_usage=$(cat \"$gpu_card/device/gpu_busy_percent\" 2>/dev/null || echo 0); "
      + "ram_usage=$(free -h | awk '/^Mem:/ {print $3}' | sed 's/Gi/GB/;s/Mi/MB/'); "
      + "ram_pct=$(free | awk '/^Mem:/ {printf \"%.4f\", $3/$2}'); "
      + "brightness_curr=$(brightnessctl g 2>/dev/null || echo 0); "
      + "brightness_max=$(brightnessctl m 2>/dev/null || echo 100); "
      + "printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' "
      + "\"$cpu_temp\" \"$gpu_temp\" \"$cpu_usage\" \"$gpu_usage\" \"$ram_usage\" \"$ram_pct\" \"$brightness_curr\" \"$brightness_max\""
    ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        if (lines.length >= 8) {
          root.cpuTemp = root.formatTemp(lines[0]);
          root.gpuTemp = root.formatTemp(lines[1]);

          var cpuVal = parseInt(lines[2]) || 0;
          root.cpuUsage = cpuVal + "%";
          root.cpuPercent = Colors.clamp01(cpuVal / 100);

          var gpuVal = parseInt(lines[3]) || 0;
          root.gpuUsage = gpuVal + "%";
          root.gpuPercent = Colors.clamp01(gpuVal / 100);

          root.ramUsage = lines[4] || "0GB";

          var ramVal = parseFloat(lines[5]) || 0;
          root.ramPercent = Colors.clamp01(ramVal);

          var curr = parseFloat(lines[6]) || 0;
          var max = parseFloat(lines[7]) || 100;
          root.brightness = max > 0 ? Colors.clamp01(curr / max) : 0;
        }
      }
    }
  }


  function setBrightness(value) {
    root.brightness = value;
    Quickshell.execDetached(["brightnessctl", "s", Math.round(value * 100) + "%"]);
  }

  property Timer refreshTimer: Timer {
    interval: root.pollIntervalMs
    running: root.subscriberCount > 0
    repeat: true
    onTriggered: statsProc.running = true
  }

  Component.onCompleted: statsProc.running = true

  // ── MPRIS players ────────────────────────────
  readonly property var activeMprisPlayers: {
    var players = [];
    for (var i = 0; i < Mpris.players.length; i++) {
      var p = Mpris.players[i];
      if (p.playbackState !== Mpris.Stopped) players.push(p);
    }
    return players;
  }
  readonly property bool hasActivePlayer: activeMprisPlayers.length > 0

  // Recording state is now in RecordingService singleton.
  // This alias preserves backward compatibility for existing consumers.
  readonly property bool isRecording: RecordingService.isRecording
}
