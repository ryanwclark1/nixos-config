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

  function triggerPoll() {
    if (!root.running || root.busy) return;
    if (!root.proc) return;
    if (!root.command || root.command.length === 0) return;
    root.busy = true;
    root.proc.running = true;
  }

  function poll() {
    triggerPoll();
  }

  property Process proc: Process {
    command: root.command
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.text = this.text ?? "";
        var parsed = root.parse(root.text);
        var changed = (typeof parsed === "object")
          ? JSON.stringify(parsed) !== JSON.stringify(root.value)
          : parsed !== root.value;
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
    onTriggered: root.triggerPoll()
  }
}
