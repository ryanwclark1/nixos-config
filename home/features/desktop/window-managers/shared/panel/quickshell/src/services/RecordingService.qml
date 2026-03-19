pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property bool isRecording: false
  property real recordingStartTime: 0
  property string elapsedText: "00:00"

  // ── Subscriber-based polling ─────────────────
  // Use Ref { service: RecordingService } for automatic lifecycle management.
  property int subscriberCount: 0

  // ── Primary detection: file-based (reactive, zero polling cost) ──────────
  // os-cmd-screenrecord writes /tmp/os-screenrecord-filename on start and
  // removes it on stop, making FileView the ideal zero-cost detector for the
  // gpu-screen-recorder path.
  readonly property string _lockFile: "/tmp/os-screenrecord-filename"

  property FileView _lockFileView: FileView {
    path: root._lockFile
    watchChanges: true
    printErrors: false
    onTextChanged: root._updateRecordingState()
    onLoaded: root._updateRecordingState()
  }

  function _updateRecordingState() {
    var fileActive = String(_lockFileView.text() ?? "").trim().length > 0;
    root.isRecording = fileActive || _legacyPoll.value === true;
  }

  // ── Fallback detection: legacy recorders (wl-screenrec / wf-recorder) ───
  // These are only used via startLegacyRegionRecording() and leave no lock
  // file. Poll at a reduced 5 s frequency; gate behind subscriberCount so
  // the subprocess only runs when the UI is visible.
  property var _legacyPoll: CommandPoll {
    interval: 5000
    running: root.subscriberCount > 0
    command: ["sh", "-c", "pgrep -x wl-screenrec || pgrep -x wf-recorder"]
    parse: function(out) { return String(out || "").trim().length > 0 }
    onUpdated: root._updateRecordingState()
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

  function qualityLabel(value) {
    if (value === "very_high")
      return "Very High";
    if (value === "high")
      return "High";
    if (value === "medium")
      return "Medium";
    return String(value || "Auto");
  }

  // ── Actions ──────────────────────────────────
  function startRecording(mode) {
    var captureSource = String(mode || Config.recordingCaptureSource || "portal");
    if (captureSource === "fullscreen")
      captureSource = "screen";

    var command = [
      "os-cmd-screenrecord",
      "--capture-source=" + captureSource,
      "--fps=" + String(Config.recordingFps || 60),
      "--quality=" + String(Config.recordingQuality || "very_high"),
      "--record-cursor=" + (Config.recordingRecordCursor ? "true" : "false")
    ];

    if (Config.recordingIncludeDesktopAudio)
      command.push("--with-desktop-audio");
    if (Config.recordingIncludeMicrophoneAudio)
      command.push("--with-microphone-audio");
    if (String(Config.recordingOutputDir || "").trim() !== "")
      command.push("--output-dir=" + String(Config.recordingOutputDir).trim());

    Quickshell.execDetached(command);
  }

  function startLegacyRegionRecording() {
    Quickshell.execDetached(["screenrecord", "region"]);
  }

  function stopRecording() {
    Quickshell.execDetached(["os-cmd-screenrecord", "--stop-recording"]);
    Quickshell.execDetached(["screenrecord-stop"]);
    elapsedText = "00:00";
    recordingStartTime = 0;
  }
}
