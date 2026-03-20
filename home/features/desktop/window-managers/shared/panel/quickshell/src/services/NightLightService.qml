pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "ScheduleUtils.js" as SU

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    property bool active: false
    readonly property int temperature: Config.nightLightTemperature

    // ── Toggle ───────────────────────────────────
    function toggle() {
        if (active)
            _stop();
        else
            _start();
    }

    function _start() {
        if (CompositorAdapter.isHyprland) {
            CompositorAdapter.dispatchAction("exec", "hyprsunset -t " + temperature, "Night light");
        } else {
            Quickshell.execDetached(["wlsunset", "-T", temperature.toString()]);
        }
        root.active = true;
        Config.nightLightEnabled = true;
    }

    function _stop() {
        // Both hyprsunset and wlsunset are standalone processes; pkill is compositor-agnostic
        Quickshell.execDetached(["pkill", "-x", CompositorAdapter.isHyprland ? "hyprsunset" : "wlsunset"]);
        root.active = false;
        Config.nightLightEnabled = false;
    }

    // ── Startup restore ──────────────────────────
    Component.onCompleted: {
        if (Config.nightLightEnabled)
            verifyTimer.start();
        if (Config.nightLightAutoSchedule)
            _evaluateSchedule();
    }

    // Delayed start to let compositor settle
    property Timer verifyTimer: Timer {
        id: verifyTimer
        interval: 2000
        onTriggered: {
            if (Config.nightLightEnabled && !root.active)
                root._start();
        }
    }

    // ── Process state check ──────────────────────
    property Process checkProc: Process {
        id: checkProc
        running: false
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null 2>&1 || pgrep -x wlsunset >/dev/null 2>&1 && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.active = (this.text || "").trim() === "on";
            }
        }
    }

    // ── Schedule (fires once per minute via SystemClock) ──
    property Connections _scheduleClock: Connections {
        target: SystemClock
        enabled: Config.nightLightAutoSchedule
        function onMinutesChanged() { root._evaluateSchedule(); }
    }

    function _evaluateSchedule() {
        if (!Config.nightLightAutoSchedule) return;

        var now = new Date();
        var shouldBeActive = false;

        if (Config.nightLightScheduleMode === "sunrise_sunset") {
            shouldBeActive = _shouldBeActiveForSunrise(now);
        } else {
            shouldBeActive = _shouldBeActiveForFixedTime(now);
        }

        if (shouldBeActive && !root.active) {
            root._start();
        } else if (!shouldBeActive && root.active) {
            root._stop();
        }
    }

    function _shouldBeActiveForFixedTime(now) {
        return SU.isInWindow(
            SU.currentMinutes(now),
            Config.nightLightStartHour * 60 + Config.nightLightStartMinute,
            Config.nightLightEndHour * 60 + Config.nightLightEndMinute
        );
    }

    function _shouldBeActiveForSunrise(now) {
        return SU.isDarkAtLocation(now,
            parseFloat(Config.nightLightLatitude),
            parseFloat(Config.nightLightLongitude));
    }

    // ── Wake recovery ────────────────────────────
    property Connections _suspendConn: Connections {
        target: IdleService
        function onWakingUp() {
            // Re-check process state after wake
            wakeCheckTimer.restart();
        }
    }

    property Timer wakeCheckTimer: Timer {
        id: wakeCheckTimer
        interval: 2000
        onTriggered: {
            if (Config.nightLightEnabled) {
                checkProc.running = true;
                // If process died during suspend, restart it
                wakeRestartTimer.restart();
            }
        }
    }

    property Timer wakeRestartTimer: Timer {
        id: wakeRestartTimer
        interval: 3000
        onTriggered: {
            if (Config.nightLightEnabled && !root.active)
                root._start();
        }
    }
}
