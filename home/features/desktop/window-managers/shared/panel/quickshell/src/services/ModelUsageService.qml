pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // ── Subscriber lifecycle ──────────────────────────
  property int subscriberCount: 0

  // ── Config-driven ──────────────────────────────────
  readonly property bool claudeEnabled: Config.modelUsageClaudeEnabled
  readonly property bool codexEnabled: Config.modelUsageCodexEnabled
  readonly property string activeProvider: Config.modelUsageActiveProvider
  readonly property string barMetric: Config.modelUsageBarMetric
  readonly property int _refreshMs: Config.modelUsageRefreshSec * 1000
  readonly property int _rateLimitMs: 300000 // 5 min

  // ── Claude state ───────────────────────────────────
  property bool claudeReady: false
  property int claudeTodayPrompts: 0
  property int claudeTodaySessions: 0
  property int claudeTodayToolCalls: 0
  property var claudeTodayTokensByModel: ({})
  property int claudeTotalPrompts: 0
  property int claudeTotalSessions: 0
  property int claudeTotalTokens: 0
  property var claudeModelUsage: ({})
  property var claudeRecentDays: []
  property string claudeFirstSessionDate: ""

  // ── Claude rate limit state ────────────────────────
  property bool claudeRateLimitAvailable: false
  property real claudeRateLimitPercent: -1
  property string claudeRateLimitLabel: ""
  property string claudeRateLimitResetAt: ""
  property int _lastRateLimitNotifiedTier: 0  // 0=none, 1=warning, 2=critical

  // ── Codex state ────────────────────────────────────
  property bool codexReady: false
  property int codexTodayPrompts: 0
  property int codexTodaySessions: 0
  property string codexModel: "unknown"
  property var codexLatestSession: ({})

  // ── Gemini state ─────────────────────────────────
  readonly property bool geminiEnabled: Config.modelUsageGeminiEnabled
  property bool geminiReady: false
  property int geminiTodayPrompts: 0
  property int geminiTodaySessions: 0
  property var geminiTodayTokens: ({})
  property int geminiTotalSessions: 0
  property int geminiTotalTokens: 0
  property string geminiModel: "unknown"
  property var geminiRecentDays: []
  property var geminiTokensByModel: ({})

  // ── Computed display ───────────────────────────────
  readonly property string displayText: _computeDisplayText()
  readonly property string displayTooltip: _computeTooltip()

  property bool _ready: false
  Component.onCompleted: _ready = true

  // ── Format helpers ─────────────────────────────────
  function formatTokenCount(n) {
    if (n >= 1000000000) return (n / 1000000000).toFixed(1) + "B";
    if (n >= 1000000) return (n / 1000000).toFixed(1) + "M";
    if (n >= 1000) return (n / 1000).toFixed(1) + "K";
    return String(n);
  }

  function friendlyModelName(id) {
    if (!id) return "Unknown";
    // Strip date suffixes and common prefixes
    var name = String(id)
      .replace(/-\d{8}$/, "")
      .replace(/^claude-/, "");
    // Capitalize first letter of each segment
    return name.split("-").map(function(s) {
      return s.charAt(0).toUpperCase() + s.slice(1);
    }).join(" ");
  }

  function formatResetTime(isoString) {
    if (!isoString) return "";
    var target = new Date(isoString);
    var now = new Date();
    var diff = target.getTime() - now.getTime();
    if (diff <= 0) return "now";
    var hours = Math.floor(diff / 3600000);
    var mins = Math.floor((diff % 3600000) / 60000);
    if (hours >= 24) return Math.floor(hours / 24) + "d " + (hours % 24) + "h";
    if (hours > 0) return hours + "h " + mins + "m";
    return mins + "m";
  }

  function refresh() {
    if (root.claudeEnabled && !claudeProc.running)
      claudeProc.running = true;
    if (root.codexEnabled && !codexProc.running)
      codexProc.running = true;
    if (root.geminiEnabled && !geminiProc.running)
      geminiProc.running = true;
  }

  function refreshRateLimit() {
    if (root.claudeEnabled && !rateLimitProc.running)
      rateLimitProc.running = true;
  }

  function switchProvider() {
    var providers = [];
    if (root.claudeEnabled) providers.push("claude");
    if (root.codexEnabled) providers.push("codex");
    if (root.geminiEnabled) providers.push("gemini");
    if (providers.length < 2) return;
    var idx = providers.indexOf(root.activeProvider);
    Config.modelUsageActiveProvider = providers[(idx + 1) % providers.length];
  }

  // ── Display computation ────────────────────────────
  function _computeDisplayText() {
    var p = root.activeProvider;
    if (p === "claude") {
      if (!root.claudeReady) return "--";
      if (root.barMetric === "tokens") return formatTokenCount(root.claudeTotalTokens);
      return String(root.claudeTodayPrompts);
    }
    if (p === "gemini") {
      if (!root.geminiReady) return "--";
      if (root.barMetric === "tokens") return formatTokenCount(root.geminiTotalTokens);
      return String(root.geminiTodayPrompts);
    }
    if (!root.codexReady) return "--";
    return String(root.codexTodayPrompts);
  }

  function _computeTooltip() {
    var p = root.activeProvider;
    if (p === "claude") {
      if (!root.claudeReady) return "Claude Code · No data";
      var tip = "Claude Code · " + root.claudeTodayPrompts + " prompts today";
      if (root.claudeTodaySessions > 0)
        tip += " · " + root.claudeTodaySessions + " sessions";
      return tip;
    }
    if (p === "gemini") {
      if (!root.geminiReady) return "Gemini CLI · No data";
      return "Gemini CLI · " + root.geminiTodayPrompts + " prompts today";
    }
    if (!root.codexReady) return "Codex CLI · No data";
    return "Codex CLI · " + root.codexTodayPrompts + " prompts today";
  }

  // ── Claude data process ────────────────────────────
  property Process claudeProc: Process {
    command: ["qs-model-usage", "claude"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = String(this.text || "").trim();
          if (!raw || raw.indexOf("{") !== 0) throw new Error("invalid response");
          var data = JSON.parse(raw);
          if (data.error) throw new Error(data.error);

          root.claudeTodayPrompts = data.todayPrompts || 0;
          root.claudeTodaySessions = data.todaySessions || 0;
          root.claudeTodayToolCalls = data.todayToolCalls || 0;
          root.claudeTodayTokensByModel = data.todayTokensByModel || {};
          root.claudeTotalPrompts = data.totalPrompts || 0;
          root.claudeTotalSessions = data.totalSessions || 0;
          root.claudeTotalTokens = data.totalTokens || 0;
          root.claudeModelUsage = data.modelUsage || {};
          root.claudeRecentDays = data.recentDays || [];
          root.claudeFirstSessionDate = data.firstSessionDate || "";
          root.claudeReady = true;
        } catch (e) {
          console.warn("ModelUsageService: claude parse error:", e);
          if (!root.claudeReady) root.claudeTodayPrompts = 0;
        }
      }
    }
  }

  // ── Claude rate limit process ──────────────────────
  property Process rateLimitProc: Process {
    command: ["qs-model-usage", "claude-rate-limit"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = String(this.text || "").trim();
          if (!raw || raw.indexOf("{") !== 0) return;
          var data = JSON.parse(raw);
          root.claudeRateLimitAvailable = !!data.available;
          if (data.available && data.daily_usage !== undefined && data.daily_limit !== undefined) {
            var pct = data.daily_limit > 0 ? (data.daily_usage / data.daily_limit * 100) : 0;
            root.claudeRateLimitPercent = Math.round(pct * 10) / 10;
            root.claudeRateLimitLabel = data.daily_usage + " / " + data.daily_limit;
            root.claudeRateLimitResetAt = data.reset_at || "";

            // Proactive rate limit toast
            var tier = pct >= 95 ? 2 : pct >= 80 ? 1 : 0;
            if (tier > root._lastRateLimitNotifiedTier) {
              root._lastRateLimitNotifiedTier = tier;
              var resetStr = root.formatResetTime(data.reset_at || "");
              if (tier === 2)
                ToastService.showError("Rate Limit Critical",
                  "Claude usage at " + pct.toFixed(0) + "%" + (resetStr ? ". Resets " + resetStr : ""));
              else
                ToastService.showNotice("Rate Limit Warning",
                  "Claude usage at " + pct.toFixed(0) + "%" + (resetStr ? ". Resets " + resetStr : ""));
            } else if (tier === 0) {
              root._lastRateLimitNotifiedTier = 0;
            }
          } else {
            root.claudeRateLimitPercent = -1;
            root.claudeRateLimitLabel = "";
            root.claudeRateLimitResetAt = "";
          }
        } catch (e) {
          root.claudeRateLimitAvailable = false;
        }
      }
    }
  }

  // ── Codex data process ─────────────────────────────
  property Process codexProc: Process {
    command: ["qs-model-usage", "codex"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = String(this.text || "").trim();
          if (!raw || raw.indexOf("{") !== 0) throw new Error("invalid response");
          var data = JSON.parse(raw);
          if (data.error) throw new Error(data.error);

          root.codexTodayPrompts = data.todayPrompts || 0;
          root.codexTodaySessions = data.todaySessions || 0;
          root.codexModel = data.model || "unknown";
          root.codexLatestSession = data.latestSession || {};
          root.codexReady = true;
        } catch (e) {
          console.warn("ModelUsageService: codex parse error:", e);
          if (!root.codexReady) root.codexTodayPrompts = 0;
        }
      }
    }
  }

  // ── Gemini data process ───────────────────────
  property Process geminiProc: Process {
    command: ["qs-model-usage", "gemini"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = String(this.text || "").trim();
          if (!raw || raw.indexOf("{") !== 0) throw new Error("invalid response");
          var data = JSON.parse(raw);
          if (data.error) throw new Error(data.error);

          root.geminiTodayPrompts = data.todayPrompts || 0;
          root.geminiTodaySessions = data.todaySessions || 0;
          root.geminiTodayTokens = data.todayTokens || {};
          root.geminiTotalSessions = data.totalSessions || 0;
          root.geminiTotalTokens = data.totalTokens || 0;
          root.geminiModel = data.model || "unknown";
          root.geminiRecentDays = data.recentDays || [];
          root.geminiTokensByModel = data.tokensByModel || {};
          root.geminiReady = true;
        } catch (e) {
          console.warn("ModelUsageService: gemini parse error:", e);
          if (!root.geminiReady) root.geminiTodayPrompts = 0;
        }
      }
    }
  }

  // ── Polling timers ─────────────────────────────────
  property Timer dataTimer: Timer {
    interval: root._refreshMs
    running: root._ready && root.subscriberCount > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  property Timer rateLimitTimer: Timer {
    interval: root._rateLimitMs
    running: root._ready && root.subscriberCount > 0 && root.claudeEnabled
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshRateLimit()
  }
}
