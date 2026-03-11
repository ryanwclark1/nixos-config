import Quickshell
import QtQuick
import Quickshell.Io
import "../widgets" as SharedWidgets

pragma Singleton

QtObject {
  id: root

  property bool isRecording: false
  property real recordingStartTime: 0
  property string elapsedText: "00:00"

  // ── Subscriber-based polling ─────────────────
  property int subscriberCount: 0
  function subscribe() { subscriberCount++; }
  function unsubscribe() { subscriberCount = Math.max(0, subscriberCount - 1); }

  // ── Recording detection ──────────────────────
  property SharedWidgets.CommandPoll recDetectPoll: SharedWidgets.CommandPoll {
    interval: 2000
    running: root.subscriberCount > 0
    command: ["sh", "-c", "pgrep -x wl-screenrec || pgrep -x wf-recorder || pgrep -f '^gpu-screen-recorder'"]
    parse: function(out) { return String(out || "").trim().length > 0 }
    onUpdated: root.isRecording = recDetectPoll.value
  }

  // ── Elapsed time tracking ────────────────────
  onIsRecordingChanged: {
    if (isRecording && recordingStartTime === 0) {
      recordingStartTime = Date.now();
    } else if (!isRecording) {
      elapsedText = "00:00";
      recordingStartTime = 0;
    }
  }

  property Timer elapsedTimer: Timer {
    interval: 1000
    running: root.isRecording && root.recordingStartTime > 0
    repeat: true
    onTriggered: root.elapsedText = root.formatElapsed(Date.now() - root.recordingStartTime)
  }

  function formatElapsed(ms) {
    var totalSec = Math.floor(ms / 1000);
    var min = Math.floor(totalSec / 60);
    var sec = totalSec % 60;
    return (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec;
  }

  // ── Actions ──────────────────────────────────
  function startRecording(mode) {
    Quickshell.execDetached(["screenrecord", mode]);
  }

  function stopRecording() {
    Quickshell.execDetached(["screenrecord-stop"]);
    elapsedText = "00:00";
    recordingStartTime = 0;
  }
}
