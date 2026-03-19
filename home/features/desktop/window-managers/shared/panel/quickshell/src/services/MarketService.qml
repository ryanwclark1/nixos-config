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

  // ── Named constants ──────────────────────────
  readonly property int _refreshIntervalMs: 60000  // 1 min
  readonly property int _configDebounceMs: 500

  // Deferred activation flag
  property bool _ready: false
  Component.onCompleted: _ready = true

  function refresh() {
    var tickers = (Config.marketTickers || "^SPX ^DJI ^NDQ").trim().replace(/,/g, " ").replace(/\s+/g, "+");
    if (!tickers) {
      root.marketData = [];
      return;
    }

    var url = "https://stooq.com/q/l/?s=" + tickers + "&f=sd2t2ohlcv&h&e=json";
    marketProc.command = ["curl", "-s", "--max-time", "15", url];
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

  property Process marketProc: Process {
    command: ["sh", "-c", "echo"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = String(this.text || "").trim();
          if (!raw) throw new Error("empty market response");
          if (raw.indexOf("{") !== 0) throw new Error("response is not JSON");
          var json = JSON.parse(raw);
          if (!json.symbols) throw new Error("missing symbols in response");

          root.marketData = json.symbols;
          root._hasSuccessfulFetch = true;
          root._lastFailureKey = "";
        } catch (e) {
          root._reportFailure(String(e || "parse error"));
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

  property Timer _configDebounce: Timer {
    interval: root._configDebounceMs
    onTriggered: root.refresh()
  }

  property Connections configConnections: Connections {
    target: Config
    function onMarketTickersChanged() { root._configDebounce.restart(); }
  }
}
