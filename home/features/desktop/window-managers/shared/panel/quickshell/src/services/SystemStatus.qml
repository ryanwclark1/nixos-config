pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "."

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
  // QS_NIXOS_CONFIG: flake / config repo root (set by Nix module); else ~/nixos-config
  readonly property string repoRoot: {
    var cfg = Quickshell.env("QS_NIXOS_CONFIG") || "";
    if (cfg.length > 0)
      return cfg;
    var home = Quickshell.env("HOME") || "";
    if (home.length > 0)
      return home + "/nixos-config";
    return "/nixos-config";
  }
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

  readonly property bool isBatteryPowered: UPower.onBattery

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
          var snippet = String(this.text || "").replace(/\s+/g, " ").substring(0, 120);
          Logger.w("SystemStatus", "health-check JSON parse failed:", e, snippet ? "stdout:" + snippet : "");
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
        try {
          root.pluginDiagnostics = JSON.parse(this.text);
        } catch (e) {
          var ps = String(this.text || "").replace(/\s+/g, " ").substring(0, 120);
          Logger.w("SystemStatus", "plugin-doctor JSON parse failed:", e, ps ? "stdout:" + ps : "");
          root.pluginDiagnostics = ({});
        }
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
    Logger.w("SystemStatus", details);
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
    if (!_fixProc.running)
      _fixProc.running = true;
  }

  property Process _fixProc: Process {
    running: false
    command: ["bash", root.healthCheckScript, "--apply-safe-fixes"]
    onExited: root.refreshHealth()
  }

  function _loadDetailedIncidents() {
    _incidentCollector.running = true;
  }

  property Process _incidentCollector: Process {
    command: ["sh", "-c", "mkdir -p \"$1\"; find \"$1\" -name 'incident.json' -exec cat {} + | jq -s .", "sh", root.incidentRoot]
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
          var is = String(this.text || "").replace(/\s+/g, " ").substring(0, 120);
          Logger.w("SystemStatus", "incidents JSON parse failed:", e, is ? "stdout:" + is : "");
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

  // Disk summary (lightweight, polled alongside main stats when subscribers > 0)
  property real diskPercent: 0.0
  property string diskUsage: "0%"

  // Network summary (polled alongside main stats when subscribers > 0)
  property string netDown: "0 KB/s"
  property string netUp: "0 KB/s"
  property real _netLastRx: 0
  property real _netLastTx: 0

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
  property Connections _brightnessSyncConn: Connections {
      target: BrightnessService
      function onMonitorsChanged() {
          root.brightness = BrightnessService.primaryMonitor.brightness;
      }
  }

  property int pollIntervalMs: 2000

  // Subscriber-based polling: only runs when at least one consumer is active.
  // Use Ref { service: SystemStatus } for automatic lifecycle management.
  property int subscriberCount: 0

  // Probed once at startup — avoids `command -v nvidia-smi` on every fast stats tick.
  property bool _nvidiaSmiAvailable: false

  property Process _nvidiaProbe: Process {
    command: ["sh", "-c", "command -v nvidia-smi >/dev/null 2>&1"]
    running: true
    onExited: (exitCode) => {
      root._nvidiaSmiAvailable = exitCode === 0;
    }
  }

  // ── Fast path: CPU/RAM/disk/net without sensors or GPU queries ─────────
  // RAM must be two separate printf fields: embedding "\n" inside one %s breaks the
  // fixed line layout (QML splits on "\n"), so disk_pct could be parsed as ramPercent;
  // parseFloat("71%") === 71 → clamp01 → 100% gauge while labels still look sane.
  readonly property string _statsLiteScript:
      "cpu_raw=$(grep '^cpu ' /proc/stat); "
      + "ram_usage_line=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {used=total-avail; if (total>0) printf \"%.1fGB\", used/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "ram_frac=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {used=total-avail; if (total>0) printf \"%.8f\", used/total; else print \"0\"}' /proc/meminfo); "
      + "disk_pct=$(df / 2>/dev/null | awk 'NR==2 {print $5}'); "
      + "iface=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}'); "
      + "net_rx=0; net_tx=0; "
      + "if [ -n \"$iface\" ] && [ -r \"/sys/class/net/$iface/statistics/rx_bytes\" ]; then "
      + "net_rx=$(cat /sys/class/net/$iface/statistics/rx_bytes); "
      + "net_tx=$(cat /sys/class/net/$iface/statistics/tx_bytes); fi; "
      + "printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' '' '' \"$cpu_raw\" '' \"$ram_usage_line\" \"$ram_frac\" \"$disk_pct\" \"$net_rx\" \"$net_tx\""

  // ── Slow path: temperatures + GPU utilization (less frequent) ──────────
  readonly property string _statsHwScriptBase:
      "sensors_out=$(sensors 2>/dev/null); "
      + "cpu_temp=$(echo \"$sensors_out\" | awk '/Tctl:|Package id 0:|Tdie:|Core 0:/ {gsub(/[+°C]/, \"\", $0); for(i=1;i<=NF;i++) if($i ~ /^[0-9.]+$/) {print $i; exit}}'); "
      + "gpu_temp=$(echo \"$sensors_out\" | awk '/edge:|junction:/ {gsub(/[+°C]/, \"\", $2); print $2; exit}'); "
  readonly property string _statsHwScriptMid:
      "gpu_usage=\"\"; for f in /sys/class/drm/card[0-9]/device/gpu_busy_percent; do "
      + "[ ! -r \"$f\" ] && continue; u=$(cat \"$f\" 2>/dev/null); [ -n \"$u\" ] && gpu_usage=$u && break; done; "
  readonly property string _statsHwNvidiaTemp:
      "if [ -z \"$gpu_temp\" ]; then gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1); fi; "
  readonly property string _statsHwNvidiaUtil:
      "if [ -z \"$gpu_usage\" ]; then gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1); fi; "
  readonly property string _statsHwScript: root._statsHwScriptBase
      + (root._nvidiaSmiAvailable ? root._statsHwNvidiaTemp : "")
      + root._statsHwScriptMid
      + (root._nvidiaSmiAvailable ? root._statsHwNvidiaUtil : "")
      + "printf '%s\\n%s\\n%s\\n' \"$cpu_temp\" \"$gpu_temp\" \"$gpu_usage\""

  function formatTemp(rawValue) {
    var parsed = parseFloat(rawValue);
    return isNaN(parsed) || parsed === 0 ? "--" : Math.round(parsed) + "°C";
  }

  function _formatRate(bytesPerSec) {
    if (bytesPerSec >= 1073741824) return (bytesPerSec / 1073741824).toFixed(1) + " GB/s";
    if (bytesPerSec >= 1048576) return (bytesPerSec / 1048576).toFixed(1) + " MB/s";
    if (bytesPerSec >= 1024) return (bytesPerSec / 1024).toFixed(0) + " KB/s";
    return bytesPerSec.toFixed(0) + " B/s";
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
    command: ["sh", "-c", root._statsLiteScript]

    property var lastTotal: 0
    property var lastIdle: 0

    onUpdated: {
      var lines = root.parseStatsOutput(this.value);
      if (lines.length >= 6) {
        var t0 = String(lines[0] || "").trim();
        if (t0 !== "")
          root.cpuTemp = root.formatTemp(lines[0]);
        var t1 = String(lines[1] || "").trim();
        if (t1 !== "")
          root.gpuTemp = root.formatTemp(lines[1]);

        // CPU Usage calculation via /proc/stat delta
        var cpuParts = (lines[2] || "").split(/\s+/);
        if (cpuParts.length >= 5) {
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

        var gpuRaw = String(lines[3] || "").trim();
        if (gpuRaw !== "") {
          var gpuVal = parseInt(gpuRaw, 10);
          if (!isNaN(gpuVal)) {
            root.gpuUsage = Math.max(0, Math.min(100, gpuVal)) + "%";
            root.gpuPercent = Colors.clamp01(gpuVal / 100);
            root.gpuHistory = root._pushHistory(root.gpuHistory, root.gpuPercent);
          }
        }

        if (lines[4])
          root.ramUsage = lines[4];

        var ramRaw = lines[5] || "";
        var ramVal = parseFloat(ramRaw);
        // Reject misparsed fields (e.g. "71%" → 71, "65.0GB" → 65) from a shifted layout.
        if (!isNaN(ramVal) && ramVal >= 0 && ramVal <= 1.001) {
          root.ramPercent = Colors.clamp01(ramVal);
          root.ramHistory = root._pushHistory(root.ramHistory, root.ramPercent);
        }

        // Disk usage (line 6: e.g. "45%")
        if (lines.length >= 7) {
          var diskRaw = parseInt(String(lines[6] || "").replace("%", ""), 10);
          if (!isNaN(diskRaw)) {
            root.diskPercent = Colors.clamp01(diskRaw / 100);
            root.diskUsage = Math.max(0, Math.min(100, diskRaw)) + "%";
          }
        }

        // Network throughput (lines 7-8: rx_bytes, tx_bytes)
        if (lines.length >= 9) {
          var rx = parseInt(lines[7], 10) || 0;
          var tx = parseInt(lines[8], 10) || 0;
          if (root._netLastRx > 0) {
            var diffRx = Math.max(0, rx - root._netLastRx);
            var diffTx = Math.max(0, tx - root._netLastTx);
            var dtSec = Math.max(0.001, root.pollIntervalMs / 1000);
            root.netDown = root._formatRate(diffRx / dtSec);
            root.netUp = root._formatRate(diffTx / dtSec);
          }
          root._netLastRx = rx;
          root._netLastTx = tx;
        }
      }
    }
  }

  property var statsHwPoll: CommandPoll {
    id: statsHwPoll
    interval: Math.max(4000, root.pollIntervalMs * 2)
    running: root.subscriberCount > 0
    command: ["sh", "-c", root._statsHwScript]

    onUpdated: {
      var lines = root.parseStatsOutput(this.value);
      if (lines.length >= 1) {
        var c0 = String(lines[0] || "").trim();
        if (c0 !== "")
          root.cpuTemp = root.formatTemp(lines[0]);
      }
      if (lines.length >= 2) {
        var c1 = String(lines[1] || "").trim();
        if (c1 !== "")
          root.gpuTemp = root.formatTemp(lines[1]);
      }
      if (lines.length >= 3) {
        var gpuRaw = String(lines[2] || "").trim();
        if (gpuRaw !== "") {
          var gpuVal = parseInt(gpuRaw, 10);
          if (!isNaN(gpuVal)) {
            root.gpuUsage = Math.max(0, Math.min(100, gpuVal)) + "%";
            root.gpuPercent = Colors.clamp01(gpuVal / 100);
            root.gpuHistory = root._pushHistory(root.gpuHistory, root.gpuPercent);
          }
        }
      }
    }
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
