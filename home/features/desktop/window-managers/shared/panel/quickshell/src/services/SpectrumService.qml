pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // ── Public API ─────────────────────────────────
  property var values: _emptyArray()
  property bool isIdle: true
  readonly property int barsCount: 32
  readonly property bool available: DependencyService.isAvailable("cava")

  // ── Subscriber pattern ─────────────────────────
  property int subscriberCount: 0
  onSubscriberCountChanged: _onSubscribersChanged()

  property bool _shouldRun: subscriberCount > 0 && available

  function _onSubscribersChanged() {
    if (_shouldRun && !_cavaProc.running) {
      _startCava();
    } else if ((!_shouldRun || !available) && _cavaProc.running) {
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
  readonly property int _restartDelayMs: 2000

  property Timer _restartTimer: Timer {
    interval: root._restartDelayMs
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
    "method = noncurses\n" +
    "ascii_max_range = 1000\n"

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
        Logger.w("SpectrumService", "cava exited (crash", root._crashCount, "of", root._maxCrashes + ")");
        if (root._crashCount < root._maxCrashes) {
          root._restartTimer.restart();
        }
      }
    }

    stdout: SplitParser {
      onRead: (line) => {
        root._parseTextFrame(line);
      }
    }
  }

  function _startCava() {
    if (!available) return;
    _crashCount = 0;
    _cavaProc.running = true;
  }

  // ── Frame parsing ──────────────────────────────
  readonly property real _asciiMaxRange: 1000.0

  function _parseTextFrame(line) {
    var parts = line.split(";");
    if (parts.length < 2) return;

    var buf = _bufToggle ? _buf1 : _buf0;
    var allZero = true;
    var count = Math.min(barsCount, parts.length);

    for (var i = 0; i < count; i++) {
      var v = parseInt(parts[i], 10) / _asciiMaxRange;
      if (isNaN(v)) v = 0;
      buf[i] = Math.max(0, Math.min(1, v));
      if (buf[i] > 0.005) allZero = false;
    }

    if (allZero) {
      _zeroFrames++;
      if (_zeroFrames >= _zeroThreshold) {
        if (!isIdle) {
          isIdle = true;
          values = _emptyArray();
        }
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
