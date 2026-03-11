import Quickshell
import QtQuick
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  // ── Output (sink) state ──────────────────────
  property real outputVolume: 0
  property bool outputMuted: false
  property string outputLabel: "No output device"

  // ── Input (source) state ─────────────────────
  property real inputVolume: 0
  property bool inputMuted: false
  property string inputLabel: "No input device"

  // ── Device lists (populated on demand) ───────
  property var sinks: []
  property var sources: []
  property int defaultSinkId: -1
  property int defaultSourceId: -1

  // ── Subscriber-based polling ─────────────────
  property int subscriberCount: 0
  function subscribe() { subscriberCount++; }
  function unsubscribe() { subscriberCount = Math.max(0, subscriberCount - 1); }

  // ── Lightweight volume poll (sink + source) ──
  property Process outputVolumeProc: Process {
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var text = (this.text || "").trim();
        var match = text.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
        if (!match) {
          root.outputVolume = 0;
          root.outputMuted = false;
          return;
        }
        var parsed = parseFloat(match[1]);
        root.outputVolume = isNaN(parsed) ? 0 : Colors.clamp01(parsed);
        root.outputMuted = text.indexOf("[MUTED]") !== -1;
      }
    }
  }

  property Process inputVolumeProc: Process {
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var text = (this.text || "").trim();
        var match = text.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
        if (!match) {
          root.inputVolume = 0;
          root.inputMuted = false;
          return;
        }
        var parsed = parseFloat(match[1]);
        root.inputVolume = isNaN(parsed) ? 0 : Colors.clamp01(parsed);
        root.inputMuted = text.indexOf("[MUTED]") !== -1;
      }
    }
  }

  function refreshVolumes() {
    outputVolumeProc.running = true;
    inputVolumeProc.running = true;
  }

  property Timer volumeTimer: Timer {
    interval: 1000
    running: root.subscriberCount > 0
    repeat: true
    onTriggered: root.refreshVolumes()
  }

  Component.onCompleted: refreshVolumes()

  // ── Full device scan (on demand) ─────────────
  property Process deviceScanProc: Process {
    command: ["sh", "-c", "wpctl status"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").split("\n");
        var section = "";
        var parsedSinks = [];
        var parsedSources = [];

        root.defaultSinkId = -1;
        root.defaultSourceId = -1;

        for (var i = 0; i < lines.length; i++) {
          var line = lines[i];
          if (line.indexOf("\u251c\u2500 Sinks:") !== -1) { section = "sinks"; continue; }
          if (line.indexOf("\u251c\u2500 Sources:") !== -1) { section = "sources"; continue; }
          if (line.indexOf("\u251c\u2500 Filters:") !== -1 || line.indexOf("\u2514\u2500 Streams:") !== -1 || line.indexOf("Video") === 0 || line.indexOf("Settings") === 0) {
            section = "";
          }
          if (section !== "sinks" && section !== "sources") continue;

          var trimmed = line.trim();
          if (!trimmed) continue;
          var isDefault = trimmed.indexOf("*") === 0;
          if (isDefault) trimmed = trimmed.substring(1).trim();

          var match = trimmed.match(/^(\d+)\.\s+(.*?)\s+\[vol:\s+([0-9.]+)\](\s+\[MUTED\])?$/);
          if (!match) continue;

          var item = {
            id: parseInt(match[1]),
            name: match[2],
            volume: parseFloat(match[3]),
            muted: !!match[4],
            isDefault: isDefault
          };

          if (section === "sinks") {
            parsedSinks.push(item);
            if (item.isDefault) {
              root.defaultSinkId = item.id;
              root.outputVolume = item.volume;
              root.outputMuted = item.muted;
              root.outputLabel = item.name;
            }
          } else {
            parsedSources.push(item);
            if (item.isDefault) {
              root.defaultSourceId = item.id;
              root.inputVolume = item.volume;
              root.inputMuted = item.muted;
              root.inputLabel = item.name;
            }
          }
        }

        root.sinks = parsedSinks;
        root.sources = parsedSources;
      }
    }
  }

  function refreshDevices() {
    deviceScanProc.running = true;
  }

  // ── Actions ──────────────────────────────────
  function setVolume(target, value) {
    var clamped = Colors.clamp01(value);
    if (clamped > 0) {
      Quickshell.execDetached(["wpctl", "set-mute", target, "0"]);
    }
    Quickshell.execDetached(["wpctl", "set-volume", target, Math.round(clamped * 100) + "%"]);

    if (target === "@DEFAULT_AUDIO_SINK@") {
      root.outputVolume = clamped;
      root.outputMuted = false;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showVolume", Math.round(clamped * 100).toString(), "false"]);
    } else if (target === "@DEFAULT_AUDIO_SOURCE@") {
      root.inputVolume = clamped;
      root.inputMuted = false;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showMic", Math.round(clamped * 100).toString(), "false"]);
    }
    Qt.callLater(root.refreshVolumes);
  }

  function toggleMute(target, currentlyMuted) {
    Quickshell.execDetached(["wpctl", "set-mute", target, currentlyMuted ? "0" : "1"]);
    if (target === "@DEFAULT_AUDIO_SINK@") {
      root.outputMuted = !currentlyMuted;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showVolume", Math.round(root.outputVolume * 100).toString(), (!currentlyMuted).toString()]);
    } else if (target === "@DEFAULT_AUDIO_SOURCE@") {
      root.inputMuted = !currentlyMuted;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showMic", Math.round(root.inputVolume * 100).toString(), (!currentlyMuted).toString()]);
    }
    Qt.callLater(root.refreshVolumes);
  }

  function setDefaultDevice(id) {
    if (id < 0) return;
    Quickshell.execDetached(["wpctl", "set-default", id.toString()]);
    Qt.callLater(root.refreshDevices);
  }
}
