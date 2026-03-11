import QtQuick
import Quickshell
import "../widgets" as SharedWidgets

pragma Singleton

QtObject {
  id: service

  readonly property string temp: internal.temp
  readonly property string condition: internal.condition
  readonly property string location: internal.location

  property QtObject internal: QtObject {
    id: internal
    property string temp: "--"
    property string condition: ""
    property string location: "Local"
  }

  property SharedWidgets.CommandPoll poll: SharedWidgets.CommandPoll {
    interval: 1800000
    running: true
    command: ["sh", "-c", "curl -s --max-time 10 'wttr.in?format=%l:%t:%C' || echo 'Unknown:--:Error'"]
    parse: function(out) {
      var p = String(out || "").trim().split(":");
      return { location: p[0] || "Unknown", temp: p[1] || "--", condition: p.slice(2).join(":") || "Unknown" };
    }
    onUpdated: {
      if (!poll.value) return;
      internal.temp = poll.value.temp;
      internal.condition = poll.value.condition;
      internal.location = poll.value.location;
    }
  }
}
