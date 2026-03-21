pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // ── Subscriber lifecycle ──────────────────────────
  property int subscriberCount: 0

  property var marketData: []
  property bool _hasSuccessfulFetch: false
  property string _lastFailureKey: ""
  property double _rateLimitQuietUntil: 0 // epoch ms; refresh() no-ops until then

  // ── Named constants ──────────────────────────
  readonly property int _refreshIntervalMs: 60000  // 1 min
  readonly property int _retryIntervalMs: 10000    // 10s retry on failure
  readonly property int _rateLimitBackoffMs: 6 * 60 * 60 * 1000 // Stooq daily cap — avoid hammering
  readonly property int _configDebounceMs: 500

  // Deferred activation flag
  property bool _ready: false
  Component.onCompleted: _ready = true

  function refresh() {
    if (Date.now() < root._rateLimitQuietUntil) {
      return;
    }
    var tickers = (Config.marketTickers || "^SPX ^DJI ^NDQ").trim().replace(/,/g, " ").replace(/\s+/g, "+");
    if (!tickers) {
      root.marketData = [];
      return;
    }

    var url = "https://stooq.com/q/l/?s=" + tickers + "&f=sd2t2ohlcv&h&e=json";
    marketProc.command = ["curl", "-s", "--compressed", "--max-time", "15",
      "-H", "User-Agent: quickshell-market/1.0", url];
    if (!marketProc.running) marketProc.running = true;
  }

  function _reportFailure(key, details) {
    var failureKey = String(key || "unknown");
    if (root._lastFailureKey !== failureKey) {
      root._lastFailureKey = failureKey;
      if (details)
        Logger.w("MarketService", failureKey, details);
      else
        Logger.w("MarketService", failureKey);
    }
  }

  property int _lastExitCode: 0

  property Process marketProc: Process {
    command: ["sh", "-c", "echo"]
    running: false
    onExited: (exitCode, exitStatus) => root._lastExitCode = exitCode
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = String(this.text || "").trim();
          if (!raw) {
            throw new Error("empty market response (curl exit " + root._lastExitCode + ")");
          }
          if (raw.indexOf("{") !== 0) {
            var rl = raw.toLowerCase();
            if (rl.indexOf("exceeded") !== -1 && rl.indexOf("limit") !== -1) {
              root._reportFailure(
                "stooq_rate_limited",
                "Daily Stooq quota exceeded; pausing market refresh for several hours"
              );
              retryTimer.stop();
              root._rateLimitQuietUntil = Date.now() + root._rateLimitBackoffMs;
              return;
            }
            throw new Error("response is not JSON: " + raw.substring(0, 80));
          }
          var json = JSON.parse(raw);
          if (!json.symbols) throw new Error("missing symbols in response");

          retryTimer.interval = root._retryIntervalMs;
          root._rateLimitQuietUntil = 0;
          root.marketData = json.symbols;
          root._hasSuccessfulFetch = true;
          root._lastFailureKey = "";
        } catch (e) {
          root._reportFailure(String(e || "parse error"));
          retryTimer.restart();
        }
      }
    }
  }

  property Timer marketTimer: Timer {
    interval: root._refreshIntervalMs
    running: root._ready && root.subscriberCount > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  property Timer _retryTimer: Timer {
    id: retryTimer
    interval: root._retryIntervalMs
    onTriggered: root.refresh()
  }

  property Timer _configDebounce: Timer {
    id: configDebounce
    interval: root._configDebounceMs
    onTriggered: root.refresh()
  }

  property Connections configConnections: Connections {
    target: Config
    function onMarketTickersChanged() { configDebounce.restart(); }
  }
}
