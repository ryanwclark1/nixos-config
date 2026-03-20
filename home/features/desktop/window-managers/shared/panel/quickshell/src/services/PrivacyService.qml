pragma Singleton

import QtQuick
import Quickshell.Services.Pipewire

QtObject {
  id: root

  // ── State ────────────────────────────────────
  // micActive is driven reactively via PipeWire; camera/screenshare via polling.
  readonly property bool micActive: _micStreamCount > 0
  property bool cameraActive: false
  property bool screenshareActive: false

  readonly property bool anyActive: micActive || cameraActive || screenshareActive

  // Priority order: camera > mic > screenshare for the single icon
  readonly property string activeIcon: {
    if (cameraActive) return "camera.svg";
    if (micActive) return "mic.svg";
    if (screenshareActive) return "desktop.svg";
    return "";
  }

  readonly property string activeLabel: {
    var parts = [];
    if (cameraActive) parts.push("Camera");
    if (micActive) parts.push("Mic");
    if (screenshareActive) parts.push("Screen");
    return parts.join(" · ");
  }

  // ── Named constants ──────────────────────────
  // Camera and screenshare are polled less aggressively — 8s is plenty for
  // privacy indicators that the user glances at rather than relies on sub-second accuracy.
  readonly property int _camSharePollMs: 8000

  // ── Subscriber-based polling ─────────────────
  // Use Ref { service: PrivacyService } for automatic lifecycle management.
  property int subscriberCount: 0

  // ── Microphone — reactive PipeWire monitoring ─
  // An active mic capture is a stream node (isStream=true) that is NOT a sink
  // (isSink=false means it reads from a source, i.e. it is a source-output / capture stream).
  // Monitor loopback streams expose a "monitor" property name; we skip those.
  readonly property int _micStreamCount: _countMicStreams()

  function _countMicStreams() {
    if (!Pipewire.ready) return 0;
    var nodes = Pipewire.nodes?.values ?? [];
    var count = 0;
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (!node || !node.audio || !node.isStream) continue;
      // Source-output (capture) streams have isSink=false.
      // Sink-input (playback) streams have isSink=true — those are not mic captures.
      if (node.isSink) continue;
      // Skip PipeWire monitor loopback streams (e.g. "Monitor of …").
      var name = String(node.name || (node.properties ? (node.properties["node.name"] || "") : "") || "").toLowerCase();
      if (name.indexOf("monitor") !== -1) continue;
      count++;
    }
    return count;
  }

  // Track all stream nodes so the _micStreamCount binding re-evaluates reactively
  // whenever streams are added, removed, or change state.
  property PwObjectTracker _streamTracker: PwObjectTracker {
    objects: _allStreamNodes()
  }

  function _allStreamNodes() {
    if (!Pipewire.ready) return [];
    var nodes = Pipewire.nodes?.values ?? [];
    var streams = [];
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i] && nodes[i].audio && nodes[i].isStream)
        streams.push(nodes[i]);
    }
    return streams;
  }

  // ── Camera + screenshare — reduced-frequency polling ─
  // No reactive alternative for /dev/video* without inotify; screenshare
  // detection relies on compositor-specific probes. 8s cadence is sufficient.
  // Poll only while someone has subscribed (privacy panel/bar widget visible).
  property var camSharePoll: CommandPoll {
    interval: root._camSharePollMs
    running: root.subscriberCount > 0
    command: [
      "sh", "-c",
      // Camera: count unique PIDs holding any /dev/video* device open.
      "cam=$(lsof /dev/video* 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | wc -l || echo 0); "
      // Screenshare: compositor-specific probe (sets share_out=0/1).
      + CompositorAdapter.screenshareProbeSnippet()
      + "echo \"$cam:$share_out\""
    ]
    parse: function(out) {
      var s = String(out || "").trim();
      var parts = s.split(":");
      return {
        cam: parseInt(parts[0] || "0", 10),
        share: parseInt(parts[1] || "0", 10)
      };
    }
    onUpdated: {
      root.cameraActive = camSharePoll.value.cam > 0;
      root.screenshareActive = camSharePoll.value.share > 0;
    }
  }
}
