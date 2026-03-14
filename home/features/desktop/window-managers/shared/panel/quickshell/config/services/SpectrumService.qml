import Quickshell
import QtQuick
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  // ── Public API ─────────────────────────────────
  property var values: _emptyArray()
  property bool isIdle: true
  readonly property int barsCount: 32

  // ── Subscriber pattern ─────────────────────────
  property int subscriberCount: 0
  onSubscriberCountChanged: _onSubscribersChanged()

  property bool _shouldRun: subscriberCount > 0

  function _onSubscribersChanged() {
    if (_shouldRun && !_cavaProc.running) {
      _startCava();
    } else if (!_shouldRun && _cavaProc.running) {
      _cavaProc.running = false;
    }
  }

  // ── Double-buffer arrays ───────────────────────
  property var _buf0: _emptyArray()
  property var _buf1: _emptyArray()
  property bool _bufToggle: false

  function _emptyArray() {
    var arr = [];
    for (var i = 0; i < 32; i++) arr.push(0.0);
    return arr;
  }

  // ── Idle detection ─────────────────────────────
  property int _zeroFrames: 0
  readonly property int _zeroThreshold: 30

  // ── Crash recovery ─────────────────────────────
  property int _crashCount: 0
  readonly property int _maxCrashes: 5

  property Timer _restartTimer: Timer {
    interval: 2000
    onTriggered: {
      if (root._shouldRun && root._crashCount < root._maxCrashes) {
        root._startCava();
      }
    }
  }

  // ── Cava config ────────────────────────────────
  readonly property string _cavaConfig:
    "[general]\n" +
    "bars = 32\n" +
    "framerate = 60\n" +
    "sensitivity = 100\n" +
    "autosens = 1\n" +
    "\n" +
    "[output]\n" +
    "method = raw\n" +
    "raw_target = /dev/stdout\n" +
    "data_format = ascii\n" +
    "ascii_max_range = 100\n" +
    "bar_delimiter = 59\n"  // semicolon = 59

  // ── Cava process ───────────────────────────────
  property Process _cavaProc: Process {
    command: ["cava", "-p", "/dev/stdin"]
    running: false
    stdinEnabled: true

    onStarted: {
      _cavaProc.write(root._cavaConfig);
      _cavaProc.stdinEnabled = false;
    }

    onExited: (code, status) => {
      if (root._shouldRun) {
        root._crashCount++;
        console.warn("SpectrumService: cava exited (crash", root._crashCount, "of", root._maxCrashes + ")");
        if (root._crashCount < root._maxCrashes) {
          root._restartTimer.restart();
        }
      }
    }

    stdout: SplitParser {
      onRead: (data) => {
        root._parseFrame(data);
      }
    }
  }

  function _startCava() {
    _cavaProc.running = true;
  }

  // ── Frame parsing ──────────────────────────────
  function _parseFrame(data) {
    var str = String(data || "").trim();
    if (!str) return;

    var parts = str.split(";");
    var buf = _bufToggle ? _buf1 : _buf0;
    var allZero = true;

    for (var i = 0; i < barsCount && i < parts.length; i++) {
      var v = parseInt(parts[i], 10) / 100.0;
      if (isNaN(v)) v = 0;
      buf[i] = Math.max(0, Math.min(1, v));
      if (buf[i] > 0.01) allZero = false;
    }

    if (allZero) {
      _zeroFrames++;
      if (_zeroFrames >= _zeroThreshold) {
        isIdle = true;
        return;
      }
    } else {
      _zeroFrames = 0;
      isIdle = false;
    }

    _bufToggle = !_bufToggle;
    values = buf;
  }
}
