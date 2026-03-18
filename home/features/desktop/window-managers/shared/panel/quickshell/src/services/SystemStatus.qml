pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

QtObject {
  id: root

  // ── Health Monitoring ──────────────────────────
  property string overallStatus: "healthy" // healthy, warning, manual_review_required, failure
  property var activeIncidents: []
  signal newIncident(var incident)

  property var pluginDiagnostics: ({})
  property bool isHealthChecking: false
  property date lastHealthCheckTime: new Date(0)

  readonly property string configuredScriptRoot: Quickshell.env("QS_SCRIPT_ROOT") || ""
  readonly property string repoRoot: (Quickshell.env("HOME") || "/home/administrator") + "/nixos-config"
  readonly property string quickshellRepoRoot: repoRoot + "/home/features/desktop/window-managers/shared/panel/quickshell"
  readonly property string defaultScriptRoot: quickshellRepoRoot + "/scripts"
  readonly property string scriptRoot: configuredScriptRoot !== "" ? configuredScriptRoot : defaultScriptRoot
  readonly property string healthCheckScript: scriptRoot + "/health-check.sh"
  readonly property string pluginDoctorScript: scriptRoot + "/plugin-doctor.sh"
  readonly property string incidentRoot: Quickshell.env("HOME") + "/.local/state/quickshell/incidents"
  property bool _helperScriptsAvailable: false
  property bool _helperScriptWarningLogged: false

  // ── Named constants ──────────────────────────
  readonly property int _healthCheckIntervalMs: 300000  // 5 min
  readonly property int _cpuUsageHighThreshold: 85
  readonly property int _ramUsageHighThreshold: 90
  readonly property int _cpuTempHighThreshold: 85
  readonly property int _gpuTempHighThreshold: 80

  property Process _helperScriptProbe: Process {
    command: ["sh", "-c", "test -f \"$1\" && test -f \"$2\"", "qs-system-status-probe", root.healthCheckScript, root.pluginDoctorScript]
    running: true
    onExited: (exitCode, exitStatus) => {
      root._helperScriptsAvailable = exitCode === 0;
      if (exitCode !== 0)
        root._reportHelperScriptsUnavailable("helper scripts not executable", exitCode, exitStatus);
    }
  }

  property Process _healthProc: Process {
    command: ["bash", root.healthCheckScript]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(this.text);
          root.overallStatus = data.status || "failure";
          root._loadDetailedIncidents();
        } catch (e) {
          root.overallStatus = "failure";
        }
        root.isHealthChecking = false;
        root.lastHealthCheckTime = new Date();
      }
    }
  }

  property Process _pluginProc: Process {
    command: ["bash", root.pluginDoctorScript, "--json"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.pluginDiagnostics = JSON.parse(this.text); } catch (e) {}
      }
    }
  }

  function _reportHelperScriptsUnavailable(reason, exitCode, exitStatus) {
    if (_helperScriptWarningLogged)
      return;
    _helperScriptWarningLogged = true;
    var details = reason || "helper scripts unavailable";
    if (configuredScriptRoot !== "")
      details += " (QS_SCRIPT_ROOT=" + configuredScriptRoot + ")";
    else
      details += " (set QS_SCRIPT_ROOT to override " + defaultScriptRoot + ")";
    if (exitCode !== undefined)
      details += " exitCode=" + exitCode;
    if (exitStatus !== undefined)
      details += " exitStatus=" + exitStatus;
    console.warn("SystemStatus:", details);
  }

  function refreshHealth() {
    if (isHealthChecking) return;
    if (!_helperScriptsAvailable) {
      _reportHelperScriptsUnavailable();
      return;
    }
    isHealthChecking = true;
    _healthProc.running = true;
    _pluginProc.running = true;
  }

  function applySafeFixes() {
    if (!_helperScriptsAvailable) {
      _reportHelperScriptsUnavailable();
      return;
    }
    var fixProc = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
    fixProc.command = ["bash", root.healthCheckScript, "--apply-safe-fixes"];
    fixProc.onExited.connect(function() {
      root.refreshHealth();
      fixProc.destroy();
    });
    fixProc.running = true;
  }

  function _loadDetailedIncidents() {
    _incidentCollector.running = true;
  }

  property Process _incidentCollector: Process {
    command: ["sh", "-c", "mkdir -p '" + root.incidentRoot + "'; find '" + root.incidentRoot + "' -name 'incident.json' -exec cat {} + | jq -s ."]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try { 
          var nextIncidents = JSON.parse(this.text || "[]");
          // Check for genuinely new signatures to avoid notification spam
          var currentSigs = root.activeIncidents.map(function(i) { return i.signature; });
          for (var i = 0; i < nextIncidents.length; i++) {
            if (currentSigs.indexOf(nextIncidents[i].signature) === -1) {
              root.newIncident(nextIncidents[i]);
            }
          }
          root.activeIncidents = nextIncidents;
        } catch (e) { 
          root.activeIncidents = []; 
        }
      }
    }
  }

  property Timer _healthTimer: Timer {
    interval: root._healthCheckIntervalMs
    running: root.subscriberCount > 0
    repeat: true
    onTriggered: root.refreshHealth()
  }


  readonly property real cpuTempNum: parseFloat(cpuTemp) || 0
  readonly property real gpuTempNum: parseFloat(gpuTemp) || 0
  readonly property real cpuUsageNum: parseFloat(cpuUsage) || 0
  readonly property real ramUsageNum: parseFloat(ramUsage) || 0

  readonly property bool hasHighLoad: cpuUsageNum > _cpuUsageHighThreshold || ramUsageNum > _ramUsageHighThreshold
  readonly property bool hasHighTemp: cpuTempNum > _cpuTempHighThreshold || gpuTempNum > _gpuTempHighThreshold
  readonly property bool isCritical: hasHighLoad || hasHighTemp || overallStatus === "failure"

  property string cpuTemp: "--"
  property string gpuTemp: "--"
  property string cpuUsage: "0%"
  property string ramUsage: "0GB"
  property string gpuUsage: "0%"
  property real cpuPercent: 0.0
  property real ramPercent: 0.0
  property real gpuPercent: 0.0

  // History arrays — 60 samples (2 minutes at default 2s poll).
  // Enables sparkline/graph visualizations in SystemStatsMenu.
  readonly property int historyMaxSamples: 60
  property var cpuHistory: []
  property var ramHistory: []
  property var gpuHistory: []

  function _pushHistory(arr, value) {
    var copy = arr.length >= historyMaxSamples ? arr.slice(1) : arr.slice();
    copy.push(value);
    return copy;
  }
  // Brightness is delegated to BrightnessService (multi-monitor + DDC support).
  // This writable property preserves backward compat for Osd.qml which assigns directly.
  // We use Connections instead of a binding so the imperative OSD assignment doesn't
  // permanently destroy the sync (QML bindings break on imperative write).
  property real brightness: 0.0
  readonly property bool brightnessAvailable: BrightnessService.primaryMonitor.available
  readonly property string brightnessStatus: {
      if (BrightnessService.monitors.length === 0) return "No brightness device detected";
      if (BrightnessService.primaryMonitor.available) return "Brightness control ready";
      return "Brightness control unavailable";
  }

  property Connections _brightnessSyncConn: Connections {
      target: BrightnessService
      function onMonitorsChanged() {
          root.brightness = BrightnessService.primaryMonitor.brightness;
      }
  }

  // Keyboard backlight brightness, synced from BrightnessService
  property real kbdBrightness: 0.0
  readonly property bool kbdBrightnessAvailable: BrightnessService.kbdAvailable

  property Connections _kbdBrightnessSyncConn: Connections {
      target: BrightnessService
      function onKbdDeviceChanged() {
          root.kbdBrightness = BrightnessService.kbdDevice.brightness;
      }
  }

  function setKbdBrightness(value) {
    BrightnessService.setKbdBrightness(value);
  }

  property int pollIntervalMs: 2000

  // Subscriber-based polling: only runs when at least one consumer is active.
  // Use Ref { service: SystemStatus } for automatic lifecycle management.
  property int subscriberCount: 0

  function formatTemp(rawValue) {
    var parsed = parseFloat(rawValue);
    return isNaN(parsed) || parsed === 0 ? "--" : Math.round(parsed) + "°C";
  }

  function parseStatsOutput(rawText) {
    var text = String(rawText || "").replace(/\r/g, "");
    if (text.endsWith("\n"))
      text = text.slice(0, -1);
    return text === "" ? [] : text.split("\n");
  }

  property var statsPoll: CommandPoll {
    id: statsPoll
    interval: Math.max(1000, root.pollIntervalMs)
    running: root.subscriberCount > 0
    command: [
      "sh",
      "-c",
      // Optimized single-pass system stats collection
      "sensors_out=$(sensors 2>/dev/null); "
      + "cpu_temp=$(echo \"$sensors_out\" | awk '/Tctl:|Package id 0:|Tdie:|Core 0:/ {gsub(/[+°C]/, \"\", $0); for(i=1;i<=NF;i++) if($i ~ /^[0-9.]+$/) {print $i; exit}}'); "
      + "gpu_temp=$(echo \"$sensors_out\" | awk '/edge:|junction:/ {gsub(/[+°C]/, \"\", $2); print $2; exit}'); "
      + "if [ -z \"$gpu_temp\" ] && command -v nvidia-smi >/dev/null 2>&1; then gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1); fi; "
      + "cpu_raw=$(grep '^cpu ' /proc/stat); "
      + "gpu_usage=$(cat /sys/class/drm/card{1,0}/device/gpu_busy_percent 2>/dev/null | head -1); "
      + "if [ -z \"$gpu_usage\" ] && command -v nvidia-smi >/dev/null 2>&1; then gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1); fi; "
      + "ram_stats=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {used=total-avail; printf \"%.1fGB\\n%.4f\", used/1024/1024, used/total}' /proc/meminfo); "
      + "printf '%s\\n%s\\n%s\\n%s\\n%s\\n' \"$cpu_temp\" \"$gpu_temp\" \"$cpu_raw\" \"$gpu_usage\" \"$ram_stats\""
    ]

    property var lastTotal: 0
    property var lastIdle: 0

    onUpdated: {
      var lines = root.parseStatsOutput(this.value);
      if (lines.length >= 6) {
        root.cpuTemp = root.formatTemp(lines[0]);
        root.gpuTemp = root.formatTemp(lines[1]);

        // CPU Usage calculation via /proc/stat delta
        var cpuParts = (lines[2] || "").split(/\s+/);
        if (cpuParts.length >= 5) {
          // cpu  user nice system idle iowait irq softirq steal guest guest_nice
          // index: 0    1    2      3    4      5   6       7     8     9         10
          var user = parseInt(cpuParts[1], 10) || 0;
          var nice = parseInt(cpuParts[2], 10) || 0;
          var system = parseInt(cpuParts[3], 10) || 0;
          var idle = parseInt(cpuParts[4], 10) || 0;
          var iowait = parseInt(cpuParts[5], 10) || 0;
          var irq = parseInt(cpuParts[6], 10) || 0;
          var softirq = parseInt(cpuParts[7], 10) || 0;
          var steal = parseInt(cpuParts[8], 10) || 0;

          var currentTotal = user + nice + system + idle + iowait + irq + softirq + steal;
          var currentIdle = idle + iowait;

          if (this.lastTotal > 0) {
            var totalDiff = currentTotal - this.lastTotal;
            var idleDiff = currentIdle - this.lastIdle;

            if (totalDiff > 0) {
              var usage = 1.0 - (idleDiff / totalDiff);
              var cpuVal = Math.round(usage * 100);
              root.cpuUsage = Math.max(0, Math.min(100, cpuVal)) + "%";
              root.cpuPercent = Colors.clamp01(usage);
              root.cpuHistory = root._pushHistory(root.cpuHistory, root.cpuPercent);
            }
          }
          this.lastTotal = currentTotal;
          this.lastIdle = currentIdle;
        }

        var gpuRaw = lines[3] || "";
        var gpuVal = parseInt(gpuRaw, 10);
        if (!isNaN(gpuVal)) {
          root.gpuUsage = Math.max(0, Math.min(100, gpuVal)) + "%";
          root.gpuPercent = Colors.clamp01(gpuVal / 100);
          root.gpuHistory = root._pushHistory(root.gpuHistory, root.gpuPercent);
        }

        if (lines[4]) root.ramUsage = lines[4];

        var ramRaw = lines[5] || "";
        var ramVal = parseFloat(ramRaw);
        if (!isNaN(ramVal)) {
          root.ramPercent = Colors.clamp01(ramVal);
          root.ramHistory = root._pushHistory(root.ramHistory, root.ramPercent);
        }
      }
    }
  }

  function setBrightness(value) {
    BrightnessService.setBrightness(BrightnessService.primaryMonitor.name, value);
  }

  // ── MPRIS players ────────────────────────────
  readonly property var activeMprisPlayers: {
    var players = [];
    for (var i = 0; i < Mpris.players.length; i++) {
      var p = Mpris.players[i];
      if (p.playbackState !== Mpris.Stopped) players.push(p);
    }
    return players;
  }
  readonly property bool hasActivePlayer: activeMprisPlayers.length > 0

  // Recording state is now in RecordingService singleton.
  // This alias preserves backward compatibility for existing consumers.
  readonly property bool isRecording: RecordingService.isRecording
}
