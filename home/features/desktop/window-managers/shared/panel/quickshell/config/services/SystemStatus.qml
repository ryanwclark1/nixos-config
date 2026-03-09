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
  property real brightness: 0.0
  
  property int pollIntervalMs: 5000

  property Process statsProc: Process {
    command: ["sh", "-c", "echo \"$(sensors | grep -E 'Tctl|edge' | awk '{print $2}' | sed 's/+//;s/°C//')\"; echo \"$(top -bn1 | awk '/Cpu\\(s\\):/ {printf \"%d\", 100 - $8}')\"; echo \"$(free -h | awk '/^Mem:/ {print $3}' | sed 's/Gi/GB/')\"; echo \"$(brightnessctl g 2>/dev/null || echo 0)\"; echo \"$(brightnessctl m 2>/dev/null || echo 100)\""]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        if (lines.length >= 5) {
          root.cpuTemp = Math.round(parseFloat(lines[0])) + "°C";
          root.gpuTemp = Math.round(parseFloat(lines[1])) + "°C";
          root.cpuUsage = lines[2] + "%";
          root.ramUsage = lines[3];
          
          var curr = parseFloat(lines[4]) || 0;
          var max = parseFloat(lines[5]) || 100;
          root.brightness = curr / max;
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
