import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  // ── Output (sink) state ──────────────────────
  property real outputVolume: 0
  property bool outputMuted: false
  property string outputLabel: "No output device"
  property string outputDeviceType: "speaker" // "speaker" | "headphone" | "bluetooth"

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
  // Use Ref { service: AudioService } for automatic lifecycle management.
  property int subscriberCount: 0

  // ── Helpers ─────────────────────────────────
  function _parseWpctlVolume(text) {
    var t = (text || "").trim();
    var match = t.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
    if (!match) return null;
    var parsed = parseFloat(match[1]);
    return { volume: isNaN(parsed) ? 0 : Colors.clamp01(parsed), muted: t.indexOf("[MUTED]") !== -1 };
  }

  function _sendOsdIpc(isSink, percent, muted) {
    var method = isSink ? "showVolume" : "showMic";
    Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", method, Math.round(percent).toString(), muted.toString()]);
  }

  // ── Lightweight volume poll (sink + source) ──
  property Process outputVolumeProc: Process {
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var r = root._parseWpctlVolume(this.text);
        if (!r) { root.outputVolume = 0; root.outputMuted = false; return; }
        root.outputVolume = r.volume;
        root.outputMuted = r.muted;
      }
    }
  }

  property Process inputVolumeProc: Process {
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var r = root._parseWpctlVolume(this.text);
        if (!r) { root.inputVolume = 0; root.inputMuted = false; return; }
        root.inputVolume = r.volume;
        root.inputMuted = r.muted;
      }
    }
  }

  // ── Default sink name poll (device type detection) ──
  property Process defaultSinkProc: Process {
    command: ["pactl", "get-default-sink"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var name = (this.text || "").trim().toLowerCase();
        if (name.indexOf("bluetooth") !== -1 || name.indexOf("bluez") !== -1 || name.indexOf("a2dp") !== -1) {
          root.outputDeviceType = "bluetooth";
        } else if (name.indexOf("headphone") !== -1 || name.indexOf("headset") !== -1) {
          root.outputDeviceType = "headphone";
        } else {
          root.outputDeviceType = "speaker";
        }
      }
    }
  }

  function refreshVolumes() {
    if (!outputVolumeProc.running) outputVolumeProc.running = true;
    if (!inputVolumeProc.running) inputVolumeProc.running = true;
    if (!defaultSinkProc.running) defaultSinkProc.running = true;
  }

  property Timer volumeTimer: Timer {
    interval: 1000
    running: root.subscriberCount > 0
    repeat: true
    onTriggered: root.refreshVolumes()
  }

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

          // Strip Unicode box-drawing tree prefixes (│ ├ └ ─) and whitespace
          var trimmed = line.replace(/^[\s\u2502\u251c\u2514\u2500]+/, "");
          if (!trimmed) continue;
          var isDefault = trimmed.indexOf("*") === 0;
          if (isDefault) trimmed = trimmed.substring(1).trim();

          var match = trimmed.match(/^(\d+)\.\s+(.*?)\s+\[vol:\s+([0-9.]+)\](\s+\[MUTED\])?$/);
          if (!match) continue;

          var item = {
            id: parseInt(match[1], 10),
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
    if (!deviceScanProc.running) deviceScanProc.running = true;
  }

  // ── Actions ──────────────────────────────────
  function setVolume(target, value) {
    var clamped = Colors.clamp01(value);
    if (clamped > 0) {
      Quickshell.execDetached(["wpctl", "set-mute", target, "0"]);
    }
    Quickshell.execDetached(["wpctl", "set-volume", target, Math.round(clamped * 100) + "%"]);

    var isSink = target === "@DEFAULT_AUDIO_SINK@";
    if (isSink) { root.outputVolume = clamped; root.outputMuted = false; }
    else if (target === "@DEFAULT_AUDIO_SOURCE@") { root.inputVolume = clamped; root.inputMuted = false; }
    if (isSink || target === "@DEFAULT_AUDIO_SOURCE@")
      root._sendOsdIpc(isSink, clamped * 100, false);
    Qt.callLater(root.refreshVolumes);
  }

  function toggleMute(target, currentlyMuted) {
    Quickshell.execDetached(["wpctl", "set-mute", target, currentlyMuted ? "0" : "1"]);
    var isSink = target === "@DEFAULT_AUDIO_SINK@";
    if (isSink) root.outputMuted = !currentlyMuted;
    else if (target === "@DEFAULT_AUDIO_SOURCE@") root.inputMuted = !currentlyMuted;
    var vol = isSink ? root.outputVolume : root.inputVolume;
    if (isSink || target === "@DEFAULT_AUDIO_SOURCE@")
      root._sendOsdIpc(isSink, vol * 100, !currentlyMuted);
    Qt.callLater(root.refreshVolumes);
  }

  function setDefaultDevice(id) {
    if (id < 0) return;
    Quickshell.execDetached(["wpctl", "set-default", id.toString()]);
    Qt.callLater(root.refreshDevices);
  }
}
