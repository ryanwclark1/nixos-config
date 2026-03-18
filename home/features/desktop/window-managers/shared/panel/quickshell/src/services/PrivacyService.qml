pragma Singleton

import QtQuick

QtObject {
  id: root

  // ── State ────────────────────────────────────
  property bool micActive: false
  property bool cameraActive: false
  property bool screenshareActive: false

  readonly property bool anyActive: micActive || cameraActive || screenshareActive

  // Priority order: camera > mic > screenshare for the single icon
  readonly property string activeIcon: {
    if (cameraActive) return "󰄀";
    if (micActive) return "";
    if (screenshareActive) return "󰍹";
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
  readonly property int _privacyPollMs: 3000

  // ── Subscriber-based polling ─────────────────
  // Use Ref { service: PrivacyService } for automatic lifecycle management.
  property int subscriberCount: 0

  // Single poll that detects all three sources in one shell invocation.
  // Outputs three colon-separated integers: mic_count:cam_count:share_count
  //   mic:   active PipeWire source-outputs (non-monitor captures)
  //   cam:   processes holding a /dev/video* device open (via lsof)
  //   share: compositor-specific screen sharing probe from CompositorAdapter
  property var privacyPoll: CommandPoll {
    interval: root._privacyPollMs
    running: root.subscriberCount > 0
    command: [
      "sh", "-c",
      // Mic: count active PipeWire source-outputs, excluding monitor loopbacks.
      // pactl list source-outputs gives one block per active capture; count non-blank lines starting with 'Source Output'.
      "mic=$(pactl list source-outputs 2>/dev/null | grep -c '^Source Output' || echo 0); "
      // Camera: lsof any /dev/video* device and count unique PIDs holding them.
      + "cam=$(lsof /dev/video* 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | wc -l || echo 0); "
      // Screenshare: compositor-specific probe (sets share_out=0/1).
      + CompositorAdapter.screenshareProbeSnippet()
      + "echo \"$mic:$cam:$share_out\""
    ]
    parse: function(out) {
      var s = String(out || "").trim();
      var parts = s.split(":");
      return {
        mic: parseInt(parts[0] || "0", 10),
        cam: parseInt(parts[1] || "0", 10),
        share: parseInt(parts[2] || "0", 10)
      };
    }
    onUpdated: {
      root.micActive = privacyPoll.value.mic > 0;
      root.cameraActive = privacyPoll.value.cam > 0;
      root.screenshareActive = privacyPoll.value.share > 0;
    }
  }
}
