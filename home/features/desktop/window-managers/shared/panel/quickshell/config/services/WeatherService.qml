import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: service

  property string temp: "--"
  property string condition: ""
  property string location: "Local"

  // Deferred activation flag — ensures Timer starts via a false→true transition
  // after the event loop is ready (avoids silent failure of `running: true` at creation)
  property bool _ready: false
  Component.onCompleted: _ready = true

  property Process weatherProc: Process {
    command: ["sh", "-c", "curl -s --max-time 10 'wttr.in/?format=%l:%t:%C' || echo 'Unknown:--:Error'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = String(this.text || "").trim();
        if (raw) {
          var p = raw.split(":");
          service.location = p[0] || "Unknown";
          service.temp = p[1] || "--";
          service.condition = p.slice(2).join(":") || "Unknown";
        }
      }
    }
  }

  property Timer weatherTimer: Timer {
    interval: 1800000
    running: service._ready
    repeat: true
    triggeredOnStart: true
    onTriggered: { if (!weatherProc.running) weatherProc.running = true; }
  }
}
