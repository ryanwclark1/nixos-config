import QtQuick
import Quickshell
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
  property bool brightnessAvailable: false
  property string brightnessStatus: "brightnessctl not detected"

  property int pollIntervalMs: 2000

  // Subscriber-based polling: only runs when at least one consumer is active.
  // Use Ref { service: SystemStatus } for automatic lifecycle management.
  property int subscriberCount: 0

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
      + "brightness_supported=0; brightness_reason='unavailable'; brightness_curr=0; brightness_max=100; "
      + "if command -v brightnessctl >/dev/null 2>&1; then "
      + "if brightnessctl -m 2>/dev/null | head -n1 | grep -q .; then "
      + "brightness_supported=1; brightness_reason='ready'; "
      + "brightness_curr=$(brightnessctl g 2>/dev/null || echo 0); "
      + "brightness_max=$(brightnessctl m 2>/dev/null || echo 100); "
      + "else brightness_reason='no_devices'; fi; "
      + "else brightness_reason='missing_brightnessctl'; fi; "
      + "printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' "
      + "\"$cpu_temp\" \"$gpu_temp\" \"$cpu_usage\" \"$gpu_usage\" \"$ram_usage\" \"$ram_pct\" \"$brightness_curr\" \"$brightness_max\" \"$brightness_supported\" \"$brightness_reason\""
    ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        if (lines.length >= 10) {
          root.cpuTemp = root.formatTemp(lines[0]);
          root.gpuTemp = root.formatTemp(lines[1]);

          var cpuVal = parseInt(lines[2], 10) || 0;
          root.cpuUsage = cpuVal + "%";
          root.cpuPercent = Colors.clamp01(cpuVal / 100);

          var gpuVal = parseInt(lines[3], 10) || 0;
          root.gpuUsage = gpuVal + "%";
          root.gpuPercent = Colors.clamp01(gpuVal / 100);

          root.ramUsage = lines[4] || "0GB";

          var ramVal = parseFloat(lines[5]) || 0;
          root.ramPercent = Colors.clamp01(ramVal);

          var curr = parseFloat(lines[6]) || 0;
          var max = parseFloat(lines[7]) || 100;
          root.brightness = max > 0 ? Colors.clamp01(curr / max) : 0;

          root.brightnessAvailable = (parseInt(lines[8], 10) || 0) === 1;
          var reason = (lines[9] || "unavailable").trim();
          if (root.brightnessAvailable) root.brightnessStatus = "Brightness control ready";
          else if (reason === "no_devices") root.brightnessStatus = "No brightness device detected";
          else if (reason === "missing_brightnessctl") root.brightnessStatus = "brightnessctl is not installed";
          else root.brightnessStatus = "Brightness control unavailable";
        }
      }
    }
  }


  function setBrightness(value) {
    if (!root.brightnessAvailable) return;
    root.brightness = value;
    Quickshell.execDetached(["brightnessctl", "s", Math.round(value * 100) + "%"]);
  }

  property Timer refreshTimer: Timer {
    interval: root.pollIntervalMs
    running: root.subscriberCount > 0
    repeat: true
    onTriggered: { if (!statsProc.running) statsProc.running = true; }
  }

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
