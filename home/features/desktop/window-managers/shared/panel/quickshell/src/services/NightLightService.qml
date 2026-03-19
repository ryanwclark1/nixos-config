pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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
    }

    // Delayed start to let compositor settle
    Timer {
        id: verifyTimer
        interval: 2000
        onTriggered: {
            if (Config.nightLightEnabled && !root.active)
                root._start();
        }
    }

    // ── Process state check ──────────────────────
    Process {
        id: checkProc
        running: false
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null 2>&1 || pgrep -x wlsunset >/dev/null 2>&1 && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.active = (this.text || "").trim() === "on";
            }
        }
    }

    // ── Schedule ────────────────────────────────
    // Check schedule every 60 seconds when auto-schedule is enabled
    Timer {
        id: scheduleTimer
        interval: 60000
        running: Config.nightLightAutoSchedule
        repeat: true
        triggeredOnStart: true
        onTriggered: root._evaluateSchedule()
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
        var h = now.getHours();
        var m = now.getMinutes();
        var current = h * 60 + m;
        var start = Config.nightLightStartHour * 60 + Config.nightLightStartMinute;
        var end = Config.nightLightEndHour * 60 + Config.nightLightEndMinute;

        // Handle wrap-around (e.g., start=20:00, end=06:00)
        if (start > end) {
            return current >= start || current < end;
        }
        return current >= start && current < end;
    }

    function _shouldBeActiveForSunrise(now) {
        var lat = parseFloat(Config.nightLightLatitude);
        var lon = parseFloat(Config.nightLightLongitude);
        if (isNaN(lat) || isNaN(lon)) return false;

        var times = _computeSunTimes(now, lat, lon);
        var h = now.getHours();
        var m = now.getMinutes();
        var current = h * 60 + m;

        // Active between sunset and sunrise
        return current >= times.sunset || current < times.sunrise;
    }

    function _computeSunTimes(date, lat, lon) {
        // Simplified sunrise/sunset calculation
        var dayOfYear = Math.floor((date - new Date(date.getFullYear(), 0, 0)) / 86400000);
        var d = dayOfYear;
        var radLat = lat * Math.PI / 180;

        // Solar declination
        var decl = -23.45 * Math.cos(2 * Math.PI / 365 * (d + 10)) * Math.PI / 180;

        // Hour angle
        var cosHA = (Math.cos(90.833 * Math.PI / 180) - Math.sin(radLat) * Math.sin(decl)) / (Math.cos(radLat) * Math.cos(decl));
        cosHA = Math.max(-1, Math.min(1, cosHA));
        var ha = Math.acos(cosHA) * 180 / Math.PI;

        // Solar noon in minutes from midnight (UTC)
        var solarNoon = 720 - 4 * lon;

        var sunriseMin = Math.round(solarNoon - ha * 4);
        var sunsetMin = Math.round(solarNoon + ha * 4);

        // Convert from UTC minutes to local minutes
        var tzOffset = -date.getTimezoneOffset();
        sunriseMin += tzOffset;
        sunsetMin += tzOffset;

        // Clamp to 0-1440
        sunriseMin = ((sunriseMin % 1440) + 1440) % 1440;
        sunsetMin = ((sunsetMin % 1440) + 1440) % 1440;

        return { sunrise: sunriseMin, sunset: sunsetMin };
    }

    // ── Wake recovery ────────────────────────────
    Connections {
        id: suspendConn
        target: SuspendManager
        function onWakingUp() {
            // Re-check process state after wake
            wakeCheckTimer.restart();
        }
    }

    Timer {
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

    Timer {
        id: wakeRestartTimer
        interval: 3000
        onTriggered: {
            if (Config.nightLightEnabled && !root.active)
                root._start();
        }
    }
}
