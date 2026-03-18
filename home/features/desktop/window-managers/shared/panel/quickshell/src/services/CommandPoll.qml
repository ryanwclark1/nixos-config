import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property int interval: 1000
  property var command: []
  property var parse: function(out) { return String(out ?? "").trim() }
  property bool running: true
  property var value: null
  property string text: ""
  property bool busy: false

  signal updated()

  property var triggerPoll: function() {
    if (!root.running || root.busy) return;
    if (!root.proc) return;
    if (!root.command || root.command.length === 0) return;
    root.busy = true;
    root.proc.running = true;
  }

  property var poll: function() {
    root.triggerPoll();
  }

  property Process proc: Process {
    command: root.command
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.text = this.text ?? "";
        var parsed = root.parse(root.text);
        var changed;
        if (typeof parsed !== "object" || parsed === null) {
          changed = parsed !== root.value;
        } else {
          var prev = root.value;
          if (typeof prev !== "object" || prev === null) {
            changed = true;
          } else {
            var ka = Object.keys(parsed), kb = Object.keys(prev);
            changed = ka.length !== kb.length;
            if (!changed) {
              for (var i = 0; i < ka.length; ++i) {
                if (parsed[ka[i]] !== prev[ka[i]]) { changed = true; break; }
              }
            }
          }
        }
        if (changed) {
          root.value = parsed;
          root.updated();
        }
        root.busy = false;
      }
    }
    onExited: root.busy = false
  }

  property Timer timer: Timer {
    interval: Math.max(50, root.interval)
    repeat: true
    running: root.running
    triggeredOnStart: true
    onTriggered: {
      if (!root.running || root.busy) return;
      if (!root.proc) return;
      if (!root.command || root.command.length === 0) return;
      root.busy = true;
      root.proc.running = true;
    }
  }
}
