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
  readonly property bool geminiEnabled: Config.modelUsageGeminiEnabled
  readonly property string activeProvider: Config.modelUsageActiveProvider
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
  property var codexTotalUsage: ({})
  property var codexRateLimits: ({})
  property var codexRecentDays: []

  // ── Gemini state ─────────────────────────────────
  property bool geminiReady: false
  property int geminiTodayPrompts: 0
  property int geminiTodaySessions: 0
  property var geminiTodayTokens: ({})
  property int geminiTotalSessions: 0
  property int geminiTotalTokens: 0
  property string geminiModel: "unknown"
  property var geminiRecentDays: []
  property var geminiTokensByModel: ({})
  property int geminiLast24hPrompts: 0
  property int geminiLast24hSessions: 0
  property var geminiLast24hTokensByModel: ({})

  // ── Provider selection ─────────────────────────────
  readonly property var enabledProviders: {
    var providers = [];
    if (root.claudeEnabled) providers.push("claude");
    if (root.codexEnabled) providers.push("codex");
    if (root.geminiEnabled) providers.push("gemini");
    return providers;
  }
  readonly property bool hasEnabledProviders: enabledProviders.length > 0
  readonly property string effectiveActiveProvider: {
    if (!root.hasEnabledProviders) return "";
    if (root.enabledProviders.indexOf(root.activeProvider) >= 0)
      return root.activeProvider;
    return root.enabledProviders[0];
  }
  readonly property string providerLabel: {
    var p = root.effectiveActiveProvider;
    if (p === "claude") return "Claude Code";
    if (p === "gemini") return "Gemini CLI";
    if (p === "codex") return "Codex CLI";
    return "No Providers Enabled";
  }
  readonly property string displayTooltip: root.hasEnabledProviders
    ? "AI Model Usage · " + root.providerLabel
    : "AI Model Usage · No providers enabled"

  // ── Provider identity ────────────────────────────
  readonly property string providerIcon: {
    var p = root.effectiveActiveProvider;
    if (p === "claude") return "brands/anthropic-symbolic.svg";
    if (p === "gemini") return "brands/google-gemini-symbolic.svg";
    if (p === "codex") return "brands/openai-symbolic.svg";
    return "board.svg";
  }
  readonly property color providerColor: {
    var p = root.effectiveActiveProvider;
    if (p === "claude") return "#cc785c";  // Warm terracotta
    if (p === "gemini") return "#4285F4";  // Google blue
    if (p === "codex") return "#22c55e";   // Green for Codex/OpenAI
    return "#94a3b8";
  }
  readonly property bool isReady: {
    var p = root.effectiveActiveProvider;
    if (p === "claude") return root.claudeReady;
    if (p === "gemini") return root.geminiReady;
    return root.codexReady;
  }
  readonly property int todayPrompts: {
    var p = root.effectiveActiveProvider;
    if (p === "claude") return root.claudeTodayPrompts;
    if (p === "gemini") return root.geminiTodayPrompts;
    return root.codexTodayPrompts;
  }

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

  function formatUnixResetTime(epochSeconds) {
    if (!epochSeconds || epochSeconds <= 0)
      return "";
    return root.formatResetTime(new Date(epochSeconds * 1000).toISOString());
  }

  function usageWindowLabel(windowMinutes) {
    if (!windowMinutes || windowMinutes <= 0)
      return "";
    if (windowMinutes === 300)
      return "5h";
    if (windowMinutes === 1440)
      return "24h";
    if (windowMinutes === 10080)
      return "Weekly";
    if (windowMinutes % 1440 === 0)
      return String(windowMinutes / 1440) + "d";
    if (windowMinutes % 60 === 0)
      return String(windowMinutes / 60) + "h";
    return String(windowMinutes) + "m";
  }

  function _resetClaudeUsage() {
    root.claudeReady = false;
    root.claudeTodayPrompts = 0;
    root.claudeTodaySessions = 0;
    root.claudeTodayToolCalls = 0;
    root.claudeTodayTokensByModel = ({});
    root.claudeTotalPrompts = 0;
    root.claudeTotalSessions = 0;
    root.claudeTotalTokens = 0;
    root.claudeModelUsage = ({});
    root.claudeRecentDays = [];
    root.claudeFirstSessionDate = "";
  }

  function _resetCodexUsage() {
    root.codexReady = false;
    root.codexTodayPrompts = 0;
    root.codexTodaySessions = 0;
    root.codexModel = "unknown";
    root.codexLatestSession = ({});
    root.codexTotalUsage = ({});
    root.codexRateLimits = ({});
    root.codexRecentDays = [];
  }

  function _resetGeminiUsage() {
    root.geminiReady = false;
    root.geminiTodayPrompts = 0;
    root.geminiTodaySessions = 0;
    root.geminiTodayTokens = ({});
    root.geminiTotalSessions = 0;
    root.geminiTotalTokens = 0;
    root.geminiModel = "unknown";
    root.geminiRecentDays = [];
    root.geminiTokensByModel = ({});
    root.geminiLast24hPrompts = 0;
    root.geminiLast24hSessions = 0;
    root.geminiLast24hTokensByModel = ({});
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
    if (root.enabledProviders.length < 2) return;
    var idx = root.enabledProviders.indexOf(root.effectiveActiveProvider);
    Config.modelUsageActiveProvider = root.enabledProviders[(idx + 1) % root.enabledProviders.length];
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
          if (data.error === "no data") {
            root._resetClaudeUsage();
            return;
          }
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
          Logger.w("ModelUsageService", "claude parse error:", e);
          if (!root.claudeReady) root._resetClaudeUsage();
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
          if (data.error === "no data") {
            root._resetCodexUsage();
            return;
          }
          if (data.error) throw new Error(data.error);

          root.codexTodayPrompts = data.todayPrompts || 0;
          root.codexTodaySessions = data.todaySessions || 0;
          root.codexModel = data.model || "unknown";
          root.codexLatestSession = data.latestSession || {};
          root.codexTotalUsage = data.totalUsage || {};
          root.codexRateLimits = data.rateLimits || {};
          root.codexRecentDays = data.recentDays || [];
          root.codexReady = true;
        } catch (e) {
          Logger.w("ModelUsageService", "codex parse error:", e);
          if (!root.codexReady) root._resetCodexUsage();
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
          if (data.error === "no data") {
            root._resetGeminiUsage();
            return;
          }
          if (data.error) throw new Error(data.error);

          root.geminiTodayPrompts = data.todayPrompts || 0;
          root.geminiTodaySessions = data.todaySessions || 0;
          root.geminiTodayTokens = data.todayTokens || {};
          root.geminiTotalSessions = data.totalSessions || 0;
          root.geminiTotalTokens = data.totalTokens || 0;
          root.geminiModel = data.model || "unknown";
          root.geminiRecentDays = data.recentDays || [];
          root.geminiTokensByModel = data.tokensByModel || {};
          root.geminiLast24hPrompts = data.last24hPrompts || 0;
          root.geminiLast24hSessions = data.last24hSessions || 0;
          root.geminiLast24hTokensByModel = data.last24hTokensByModel || {};
          root.geminiReady = true;
        } catch (e) {
          Logger.w("ModelUsageService", "gemini parse error:", e);
          if (!root.geminiReady) root._resetGeminiUsage();
        }
      }
    }
  }

  // ── Polling timers removed ─────────────────────────
  // Since active polling was deemed unimportant, we only fetch when the 
  // dropdown/popup menu becomes visible (see ModelUsageMenu.qml).
}
