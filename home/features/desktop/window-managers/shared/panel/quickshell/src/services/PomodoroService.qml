pragma Singleton

import QtQuick
import Quickshell

QtObject {
  id: root

  // ── Config (seconds) ─────────────────────────
  property int focusDuration: 25 * 60
  property int breakDuration: 5 * 60
  property int longBreakDuration: 15 * 60
  property int cyclesBeforeLongBreak: 4

  // ── State ────────────────────────────────────
  property bool running: false
  property bool isBreak: false
  property int cycle: 0
  property int secondsLeft: focusDuration
  property bool isLongBreak: isBreak && (cycle + 1 === cyclesBeforeLongBreak)

  readonly property int currentLapDuration: isLongBreak ? longBreakDuration : isBreak ? breakDuration : focusDuration
  readonly property real progress: 1.0 - (secondsLeft / Math.max(1, currentLapDuration))
  readonly property string timeDisplay: {
    var mins = Math.floor(secondsLeft / 60);
    var secs = secondsLeft % 60;
    return String(mins).padStart(2, "0") + ":" + String(secs).padStart(2, "0");
  }

  property int _startTimestamp: 0

  function _now() { return Math.floor(Date.now() / 1000); }

  function toggle() {
    if (running) {
      running = false;
    } else {
      _startTimestamp = _now() + secondsLeft - currentLapDuration;
      running = true;
    }
  }

  function reset() {
    running = false;
    isBreak = false;
    cycle = 0;
    secondsLeft = focusDuration;
  }

  function skip() {
    _transitionLap();
  }

  function _transitionLap() {
    if (!isBreak) {
      cycle = (cycle + 1) % cyclesBeforeLongBreak;
    }
    isBreak = !isBreak;
    _startTimestamp = _now();
    secondsLeft = currentLapDuration;

    var msg = isBreak
      ? (isLongBreak ? "Long break: " + Math.floor(longBreakDuration / 60) + " min" : "Break: " + Math.floor(breakDuration / 60) + " min")
      : "Focus: " + Math.floor(focusDuration / 60) + " min";
    Quickshell.execDetached(["notify-send", "Pomodoro", msg, "-a", "Quickshell"]);
  }

  function _refresh() {
    if (_now() >= _startTimestamp + currentLapDuration) {
      _transitionLap();
    }
    secondsLeft = currentLapDuration - (_now() - _startTimestamp);
  }

  property Timer _timer: Timer {
    interval: 200
    running: root.running
    repeat: true
    onTriggered: root._refresh()
  }
}
