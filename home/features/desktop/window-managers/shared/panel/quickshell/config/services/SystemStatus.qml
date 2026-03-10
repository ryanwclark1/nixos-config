import Quickshell
import QtQuick
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  property string cpuTemp: "--"
  property string gpuTemp: "--"
  property string cpuUsage: "0%"
  property string ramUsage: "0GB"
  property real cpuPercent: 0.0
  property real ramPercent: 0.0
  property real brightness: 0.0

  property int pollIntervalMs: 2000

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
      + "ram_usage=$(free -h | awk '/^Mem:/ {print $3}' | sed 's/Gi/GB/;s/Mi/MB/'); "
      + "ram_pct=$(free | awk '/^Mem:/ {printf \"%.4f\", $3/$2}'); "
      + "brightness_curr=$(brightnessctl g 2>/dev/null || echo 0); "
      + "brightness_max=$(brightnessctl m 2>/dev/null || echo 100); "
      + "printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' "
      + "\"$cpu_temp\" \"$gpu_temp\" \"$cpu_usage\" \"$ram_usage\" \"$ram_pct\" \"$brightness_curr\" \"$brightness_max\""
    ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        if (lines.length >= 7) {
          root.cpuTemp = root.formatTemp(lines[0]);
          root.gpuTemp = root.formatTemp(lines[1]);

          var cpuVal = parseInt(lines[2]) || 0;
          root.cpuUsage = cpuVal + "%";
          root.cpuPercent = Math.max(0, Math.min(1, cpuVal / 100));

          root.ramUsage = lines[3] || "0GB";

          var ramVal = parseFloat(lines[4]) || 0;
          root.ramPercent = Math.max(0, Math.min(1, ramVal));

          var curr = parseFloat(lines[5]) || 0;
          var max = parseFloat(lines[6]) || 100;
          root.brightness = max > 0 ? Math.max(0, Math.min(1, curr / max)) : 0;
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
    running: true
    repeat: true
    onTriggered: statsProc.running = true
  }

  Component.onCompleted: statsProc.running = true
}
