import QtQuick
import Quickshell
import "../widgets" as SharedWidgets

pragma Singleton

QtObject {
  id: service

  property string temp: "--"
  property string condition: ""
  property string location: "Local"

  property SharedWidgets.CommandPoll poll: SharedWidgets.CommandPoll {
    interval: 1800000
    running: true
    command: ["sh", "-c", "curl -s --max-time 10 'wttr.in?format=%l:%t:%C' || echo 'Unknown:--:Error'"]
    parse: function(out) { return String(out || "").trim(); }
    onUpdated: {
      var raw = poll.value || "";
      var p = raw.split(":");
      service.location = p[0] || "Unknown";
      service.temp = p[1] || "--";
      service.condition = p.slice(2).join(":") || "Unknown";
    }
  }
}
