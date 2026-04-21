pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "."
import "GpuTelemetryHelpers.js" as GpuTelemetryHelpers
import "SystemStatusTelemetry.js" as SystemStatusTelemetry

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
  property double _highLoadSinceMs: 0
  property double _highTempSinceMs: 0
  property double _lastLoadSampleAtMs: 0
  property double _lastThermalSampleAtMs: 0

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
          var data = root._parseJsonOutput(this.text, ({}));
          root.overallStatus = root._normalizeHealthStatus(data.status);
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
          root.pluginDiagnostics = root._parseJsonOutput(this.text, ({}));
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

  function _parseJsonOutput(rawText, fallbackValue) {
    var text = String(rawText || "").trim();
    if (text === "")
      return fallbackValue;

    var parseError = null;
    try {
      return JSON.parse(text);
    } catch (e) {
      parseError = e;
    }

    var lines = text.split("\n");
    for (var i = 0; i < lines.length; i++) {
      var candidate = lines.slice(i).join("\n").trim();
      if (candidate === "")
        continue;
      var firstChar = candidate.charAt(0);
      if (firstChar !== "{" && firstChar !== "[")
        continue;
      try {
        return JSON.parse(candidate);
      } catch (_) {
      }
    }

    throw parseError;
  }

  function _normalizeHealthStatus(status) {
    switch (String(status || "").trim().toLowerCase()) {
      case "healthy":
        return "healthy";
      case "warning":
      case "safe_fix_pending":
        return "warning";
      case "manual_review_required":
        return "manual_review_required";
      case "failure":
      case "detector_failed":
        return "failure";
      default:
        return "failure";
    }
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
          var nextIncidents = root._parseJsonOutput(this.text, []);
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
    running: root.anyDemandActive
    repeat: true
    onTriggered: root.refreshHealth()
  }


  readonly property real cpuTempNum: parseFloat(cpuTemp) || 0
  readonly property real gpuTempNum: parseFloat(gpuTemp) || 0

  readonly property bool hasHighLoad: cpuPercent >= (_cpuUsageHighThreshold / 100) || ramPercent >= (_ramUsageHighThreshold / 100)
  readonly property bool hasHighTemp: cpuTempNum > _cpuTempHighThreshold || gpuTempNum > _gpuTempHighThreshold
  readonly property bool hasSustainedHighLoad: hasHighLoad
      && _highLoadSinceMs > 0
      && (_lastLoadSampleAtMs - _highLoadSinceMs) >= Math.max(0, Config.criticalStateSustainMs)
  readonly property bool hasSustainedHighTemp: hasHighTemp
      && _highTempSinceMs > 0
      && (_lastThermalSampleAtMs - _highTempSinceMs) >= Math.max(0, Config.osdCriticalThermalSustainMs)
  readonly property bool isCritical: hasSustainedHighLoad || hasSustainedHighTemp || overallStatus === "failure"
  readonly property bool shouldShowCriticalOsd: hasSustainedHighTemp || overallStatus === "failure"
  readonly property bool hasSafeFixableIncidents: {
    for (var i = 0; i < activeIncidents.length; i++) {
      if (activeIncidents[i] && activeIncidents[i].safe_fix_available)
        return true;
    }
    return false;
  }
  readonly property var criticalReasons: {
    var reasons = [];
    if (hasSustainedHighLoad && cpuPercent >= (_cpuUsageHighThreshold / 100))
      reasons.push("CPU " + cpuUsage);
    if (hasSustainedHighLoad && ramPercent >= (_ramUsageHighThreshold / 100))
      reasons.push("RAM " + Math.round(ramPercent * 100) + "%");
    if (hasSustainedHighTemp && cpuTempNum > _cpuTempHighThreshold)
      reasons.push("CPU " + cpuTemp);
    if (hasSustainedHighTemp && gpuTempNum > _gpuTempHighThreshold)
      reasons.push("GPU " + gpuTemp);
    if (overallStatus === "failure")
      reasons.push("health check failure");
    return reasons;
  }
  readonly property string criticalSummary: criticalReasons.length > 0
      ? "CRITICAL: " + criticalReasons.join(" • ")
      : "CRITICAL: Resource threshold exceeded"
  readonly property var criticalOsdReasons: {
    var reasons = [];
    if (cpuTempNum > _cpuTempHighThreshold)
      reasons.push("CPU " + cpuTemp);
    if (gpuTempNum > _gpuTempHighThreshold)
      reasons.push("GPU " + gpuTemp);
    if (overallStatus === "failure")
      reasons.push("health check failure");
    return reasons;
  }
  readonly property string criticalOsdSummary: criticalOsdReasons.length > 0
      ? "CRITICAL: " + criticalOsdReasons.join(" • ")
      : criticalSummary

  property string cpuTemp: "--"
  property string gpuTemp: "--"
  property string cpuUsage: "0%"
  property string ramUsage: "0GB"
  property string ramTotal: "0GB"
  property string swapUsage: "--"
  property string gpuUsage: "0%"
  property string gpuCardName: ""
  property string gpuPciAddress: ""
  property real cpuPercent: 0.0
  property real ramPercent: 0.0
  property real gpuPercent: 0.0
  readonly property string ramPercentText: SystemStatusTelemetry.formatPercent(ramPercent)
  readonly property string ramUsedTotalText: SystemStatusTelemetry.formatUsedTotal(ramUsage, ramTotal, "--")

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

  function refreshStats() {
    if (!anyDemandActive)
      return;
    statsPoll.triggerPoll();
    statsHwPoll.triggerPoll();
  }

  property int pollIntervalMs: 2000
  property int summarySubscriberCount: 0

  // Subscriber-based polling: summary subscribers keep critical health fresh,
  // while detailed subscribers enable the full telemetry path.
  // Use Ref { service: SystemStatus } for automatic lifecycle management.
  property int subscriberCount: 0
  readonly property bool summaryDemandActive: summarySubscriberCount > 0
  readonly property bool detailedDemandActive: subscriberCount > 0
  readonly property bool anyDemandActive: summaryDemandActive || detailedDemandActive
  readonly property int effectivePollIntervalMs: detailedDemandActive
      ? Math.max(1000, pollIntervalMs)
      : Math.max(5000, pollIntervalMs * 3)
  readonly property int effectiveHwPollIntervalMs: detailedDemandActive
      ? Math.max(4000, pollIntervalMs * 2)
      : Math.max(15000, pollIntervalMs * 6)

  function addSummarySubscriber() {
    summarySubscriberCount++;
  }

  function removeSummarySubscriber() {
    summarySubscriberCount = Math.max(0, summarySubscriberCount - 1);
  }

  onDetailedDemandActiveChanged: {
    if (!detailedDemandActive) {
      _netLastRx = 0;
      _netLastTx = 0;
      return;
    }
    refreshStats();
  }

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
  // Emit tagged rows instead of positional placeholders so CommandPoll trimming
  // cannot shift fields and corrupt CPU/RAM parsing.
  readonly property string _statsLiteDetailedScript:
      "cpu_raw=$(grep '^cpu ' /proc/stat); "
      + "ram_used_text=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {used=total-avail; if (total>0) printf \"%.1fGB\", used/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "ram_total_text=$(awk '/MemTotal/ {total=$2} END {if (total>0) printf \"%.1fGB\", total/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "ram_frac=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {used=total-avail; if (total>0) printf \"%.8f\", used/total; else print \"0\"}' /proc/meminfo); "
      + "swap_used_text=$(awk '/SwapTotal/ {total=$2} /SwapFree/ {free=$2} END {used=total-free; if (total>0) printf \"%.1fGB\", used/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "swap_total_text=$(awk '/SwapTotal/ {total=$2} END {if (total>0) printf \"%.1fGB\", total/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "disk_pct=$(df / 2>/dev/null | awk 'NR==2 {print $5}'); "
      + "iface=$(ip route show default 2>/dev/null | awk 'NR==1 {print $5}'); "
      + "net_rx=0; net_tx=0; "
      + "if [ -n \"$iface\" ] && [ -r \"/sys/class/net/$iface/statistics/rx_bytes\" ]; then "
      + "net_rx=$(cat /sys/class/net/$iface/statistics/rx_bytes); "
      + "net_tx=$(cat /sys/class/net/$iface/statistics/tx_bytes); fi; "
      + "printf 'cpu_raw\\t%s\\nram_used_text\\t%s\\nram_total_text\\t%s\\nram_frac\\t%s\\nswap_used_text\\t%s\\nswap_total_text\\t%s\\ndisk_pct\\t%s\\nnet_rx\\t%s\\nnet_tx\\t%s\\n' \"$cpu_raw\" \"$ram_used_text\" \"$ram_total_text\" \"$ram_frac\" \"$swap_used_text\" \"$swap_total_text\" \"$disk_pct\" \"$net_rx\" \"$net_tx\""
  readonly property string _statsLiteSummaryScript:
      "cpu_raw=$(grep '^cpu ' /proc/stat); "
      + "ram_used_text=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {used=total-avail; if (total>0) printf \"%.1fGB\", used/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "ram_total_text=$(awk '/MemTotal/ {total=$2} END {if (total>0) printf \"%.1fGB\", total/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "ram_frac=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {used=total-avail; if (total>0) printf \"%.8f\", used/total; else print \"0\"}' /proc/meminfo); "
      + "swap_used_text=$(awk '/SwapTotal/ {total=$2} /SwapFree/ {free=$2} END {used=total-free; if (total>0) printf \"%.1fGB\", used/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "swap_total_text=$(awk '/SwapTotal/ {total=$2} END {if (total>0) printf \"%.1fGB\", total/1024/1024; else print \"0.0GB\"}' /proc/meminfo); "
      + "printf 'cpu_raw\\t%s\\nram_used_text\\t%s\\nram_total_text\\t%s\\nram_frac\\t%s\\nswap_used_text\\t%s\\nswap_total_text\\t%s\\ndisk_pct\\t\\nnet_rx\\t\\nnet_tx\\t\\n' \"$cpu_raw\" \"$ram_used_text\" \"$ram_total_text\" \"$ram_frac\" \"$swap_used_text\" \"$swap_total_text\""
  readonly property string _statsLiteScript: root.detailedDemandActive
      ? root._statsLiteDetailedScript
      : root._statsLiteSummaryScript

  // ── Slow path: temperatures + GPU utilization (less frequent) ──────────
  readonly property string _statsHwScriptBase:
      "sensors_out=$(sensors 2>/dev/null); "
      + "cpu_temp=$(echo \"$sensors_out\" | awk '/Tctl:|Package id 0:|Tdie:|Core 0:/ {gsub(/[+°C]/, \"\", $0); for(i=1;i<=NF;i++) if($i ~ /^[0-9.]+$/) {print $i; exit}}'); "
  readonly property string _statsHwScriptMid:
      "printf '%s\\n' \"$cpu_temp\"; "
      + "for card in /sys/class/drm/card[0-9]; do "
      + "[ -d \"$card/device\" ] || continue; "
      + "busy=''; [ -r \"$card/device/gpu_busy_percent\" ] && busy=$(cat \"$card/device/gpu_busy_percent\" 2>/dev/null); "
      + "vram_total=''; [ -r \"$card/device/mem_info_vram_total\" ] && vram_total=$(cat \"$card/device/mem_info_vram_total\" 2>/dev/null); "
      + "temp=''; temp_input=$(find \"$card/device/hwmon\" -maxdepth 2 -name 'temp*_input' 2>/dev/null | sort | head -1); "
      + "[ -n \"$temp_input\" ] && temp=$(awk '{printf \"%.1f\", $1/1000}' \"$temp_input\" 2>/dev/null); "
      + "pci=$(basename \"$(readlink -f \"$card/device\")\"); "
      + "printf 'gpu\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$(basename \"$card\")\" \"$pci\" \"$busy\" \"$temp\" \"$vram_total\"; "
      + "done; "
  readonly property string _statsHwNvidiaFallback:
      "if ! ls /sys/class/drm/card[0-9]/device/gpu_busy_percent >/dev/null 2>&1; then "
      + "nvidia_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1); "
      + "nvidia_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1); "
      + "printf 'nvidia\\t%s\\t%s\\n' \"$nvidia_usage\" \"$nvidia_temp\"; "
      + "fi; "
  readonly property string _statsHwScript: root._statsHwScriptBase
      + root._statsHwScriptMid
      + (root._nvidiaSmiAvailable ? root._statsHwNvidiaFallback : "")

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

  function _parseLiteStats(rawText) {
    return SystemStatusTelemetry.parseTaggedStats(rawText);
  }

  function _parseHardwareStats(rawText) {
    var lines = root.parseStatsOutput(rawText);
    var next = {
      cpuTempRaw: "",
      gpuTempRaw: "",
      gpuUsageRaw: "",
      gpuCardName: "",
      gpuPciAddress: "",
    };

    if (lines.length === 0)
      return next;

    next.cpuTempRaw = String(lines[0] || "").trim();

    var gpuCandidates = [];
    for (var i = 1; i < lines.length; i++) {
      var line = String(lines[i] || "").trim();
      if (line === "")
        continue;
      var parts = line.split("\t");
      if (parts[0] === "gpu") {
        gpuCandidates.push({
          cardName: parts[1],
          pciAddress: parts[2],
          busyPercent: parts[3],
          tempC: parts[4],
          vramTotalBytes: parts[5],
        });
        continue;
      }
      if (parts[0] === "nvidia") {
        next.gpuUsageRaw = String(parts[1] || "").trim();
        next.gpuTempRaw = String(parts[2] || "").trim();
      }
    }

    var selected = GpuTelemetryHelpers.selectPreferredGpuCandidate(gpuCandidates);
    if (selected) {
      next.gpuUsageRaw = selected.busyPercent;
      next.gpuTempRaw = selected.tempC;
      next.gpuCardName = selected.cardName;
      next.gpuPciAddress = selected.pciAddress;
    }

    return next;
  }

  property var statsPoll: CommandPoll {
    id: statsPoll
    interval: root.effectivePollIntervalMs
    running: root.anyDemandActive
    command: ["sh", "-c", root._statsLiteScript]
    parse: function(out) { return root._parseLiteStats(out); }

    property var lastTotal: 0
    property var lastIdle: 0

    onUpdated: {
      var data = statsPoll.value || ({});

      var cpuParts = String(data.cpuRaw || "").trim().split(/\s+/);
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

        if (statsPoll.lastTotal > 0) {
          var totalDiff = currentTotal - statsPoll.lastTotal;
          var idleDiff = currentIdle - statsPoll.lastIdle;

          if (totalDiff > 0) {
            var usage = 1.0 - (idleDiff / totalDiff);
            var cpuVal = Math.round(usage * 100);
            root.cpuUsage = Math.max(0, Math.min(100, cpuVal)) + "%";
            root.cpuPercent = Colors.clamp01(usage);
            root.cpuHistory = root._pushHistory(root.cpuHistory, root.cpuPercent);
          }
        }
        statsPoll.lastTotal = currentTotal;
        statsPoll.lastIdle = currentIdle;
      }

      if (data.ramUsedText)
        root.ramUsage = data.ramUsedText;
      if (data.ramTotalText)
        root.ramTotal = data.ramTotalText;

      var swapText = SystemStatusTelemetry.formatUsedTotal(data.swapUsedText, data.swapTotalText, "--");
      if (swapText !== "--")
        root.swapUsage = swapText;

      var ramVal = parseFloat(String(data.ramFrac || ""));
      if (!isNaN(ramVal) && ramVal >= 0 && ramVal <= 1.001) {
        root.ramPercent = Colors.clamp01(ramVal);
        root.ramHistory = root._pushHistory(root.ramHistory, root.ramPercent);
      }

      if (root.detailedDemandActive) {
        var diskRaw = parseInt(String(data.diskPct || "").replace("%", ""), 10);
        if (!isNaN(diskRaw)) {
          root.diskPercent = Colors.clamp01(diskRaw / 100);
          root.diskUsage = Math.max(0, Math.min(100, diskRaw)) + "%";
        }

        var rx = parseInt(String(data.netRx || ""), 10) || 0;
        var tx = parseInt(String(data.netTx || ""), 10) || 0;
        if (root._netLastRx > 0) {
          var diffRx = Math.max(0, rx - root._netLastRx);
          var diffTx = Math.max(0, tx - root._netLastTx);
          var dtSec = Math.max(0.001, statsPoll.interval / 1000);
          root.netDown = root._formatRate(diffRx / dtSec);
          root.netUp = root._formatRate(diffTx / dtSec);
        }
        root._netLastRx = rx;
        root._netLastTx = tx;
      }
    }
  }

  property var statsHwPoll: CommandPoll {
    id: statsHwPoll
    interval: root.effectiveHwPollIntervalMs
    running: root.anyDemandActive
    command: ["sh", "-c", root._statsHwScript]
    parse: function(out) { return root._parseHardwareStats(out); }

    onUpdated: {
      var data = statsHwPoll.value || ({});
      var now = Date.now();
      var cpuRaw = String(data.cpuTempRaw || "").trim();
      if (cpuRaw !== "")
        root.cpuTemp = root.formatTemp(cpuRaw);

      root.gpuCardName = String(data.gpuCardName || "");
      root.gpuPciAddress = String(data.gpuPciAddress || "");

      var gpuTempRaw = String(data.gpuTempRaw || "").trim();
      if (gpuTempRaw !== "")
        root.gpuTemp = root.formatTemp(gpuTempRaw);

      var gpuUsageRaw = String(data.gpuUsageRaw || "").trim();
      if (root.detailedDemandActive && gpuUsageRaw !== "") {
        var gpuVal = parseInt(gpuUsageRaw, 10);
        if (!isNaN(gpuVal)) {
          root.gpuUsage = Math.max(0, Math.min(100, gpuVal)) + "%";
          root.gpuPercent = Colors.clamp01(gpuVal / 100);
          root.gpuHistory = root._pushHistory(root.gpuHistory, root.gpuPercent);
        }
      }

      root._lastLoadSampleAtMs = now;
      if (root.hasHighLoad) {
        if (root._highLoadSinceMs <= 0)
          root._highLoadSinceMs = now;
      } else {
        root._highLoadSinceMs = 0;
      }

      root._lastThermalSampleAtMs = now;
      if (root.hasHighTemp) {
        if (root._highTempSinceMs <= 0)
          root._highTempSinceMs = now;
      } else {
        root._highTempSinceMs = 0;
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
