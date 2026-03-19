pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    property var monitors: []
    readonly property var primaryMonitor: monitors.length > 0 ? monitors[0] : _emptyMonitor
    readonly property bool hasMultipleMonitors: monitors.length > 1

    readonly property var _emptyMonitor: ({
            name: "none",
            brightness: 0,
            isInternal: false,
            busNumber: -1,
            available: false
        })

    // ── Keyboard backlight ─────────────────────────
    property var kbdDevice: _emptyKbdDevice
    readonly property bool kbdAvailable: kbdDevice.available

    readonly property var _emptyKbdDevice: ({
            name: "none",
            brightness: 0,
            maxSteps: 0,
            available: false
        })

    // ── Subscriber-based polling ─────────────────
    property int subscriberCount: 0

    // ── Internal state ───────────────────────────
    property bool _detected: false
    property bool _hasInternalSysfs: false
    property bool _hasDdc: false

    // ── Named constants ────────────────────────────
    readonly property int _wakeSettleMs: 3000
    readonly property int _ddcDebounceMs: 300
    readonly property int _ddcPollIntervalMs: 5000

    // ── Detection on startup + wake ──────────────
    Component.onCompleted: _detectMonitors()

    property Connections _suspendConn: Connections {
        target: SuspendManager
        function onWakingUp() {
            root._detected = false;
            root._detectTimer.restart();
        }
    }

    property Timer _detectTimer: Timer {
        interval: root._wakeSettleMs
        onTriggered: root._detectMonitors()
    }

    // Detection extracts sysfs backlight device name (SYSFS|<device>) for FileView.
    property Process _detectProc: Process {
        running: false
        command: ["sh", "-c",
            "int_avail=0; int_curr=0; int_max=100; int_name='eDP-1'; sysfs_dev=''; "
            + "if command -v brightnessctl >/dev/null 2>&1; then "
            + "bl_line=$(brightnessctl -m 2>/dev/null | head -n1); "
            + "if [ -n \"$bl_line\" ]; then "
            + "int_avail=1; sysfs_dev=$(printf '%s' \"$bl_line\" | cut -d, -f1); "
            + "int_curr=$(brightnessctl g 2>/dev/null || echo 0); "
            + "int_max=$(brightnessctl m 2>/dev/null || echo 100); fi; fi; "
            + "printf 'INT|%s|%s|%s|%s\\n' \"$int_avail\" \"$int_name\" \"$int_curr\" \"$int_max\"; "
            + "if [ -n \"$sysfs_dev\" ]; then printf 'SYSFS|%s\\n' \"$sysfs_dev\"; fi; "
            + "if command -v ddcutil >/dev/null 2>&1; then "
            + "ddcutil detect --brief 2>/dev/null | awk '"
            + "/^Display [0-9]/ { bus=\"\"; name=\"\" } "
            + "/I2C bus:/ { gsub(/.*\\/dev\\/i2c-/, \"\"); bus=$0 } "
            + "/Monitor:/ { $1=\"\"; name=$0; gsub(/^[ \\t]+/, \"\", name) } "
            + "bus && name { printf \"DDC|%s|%s\\n\", bus, name; bus=\"\"; name=\"\" }'"
            + "; for bus in $(ddcutil detect --brief 2>/dev/null | awk '/I2C bus:/ {gsub(/.*i2c-/,\"\"); print}'); do "
            + "val=$(ddcutil getvcp 10 --bus \"$bus\" --brief 2>/dev/null | awk '{print $4, $5}'); "
            + "printf 'DDCVAL|%s|%s\\n' \"$bus\" \"$val\"; done; fi; "
            + "for d in /sys/class/leds/*kbd_backlight*; do "
            + "if [ -e \"$d\" ]; then "
            + "dname=$(basename \"$d\"); "
            + "kmax=$(cat \"$d/max_brightness\" 2>/dev/null || echo 0); "
            + "kcurr=$(cat \"$d/brightness\" 2>/dev/null || echo 0); "
            + "printf 'KBD|%s|%s|%s\\n' \"$dname\" \"$kcurr\" \"$kmax\"; "
            + "break; fi; done"]
        stdout: StdioCollector {
            onStreamFinished: root._parseDetection(this.text || "")
        }
    }

    function _detectMonitors() {
        if (!_detectProc.running)
            _detectProc.running = true;
    }

    function _parseDetection(text) {
        var lines = text.trim().split("\n");
        var result = [];
        var ddcBuses = {};
        var ddcVals = {};

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (!line) continue;
            var parts = line.split("|");

            if (parts[0] === "INT") {
                if (parts[1] === "1") {
                    var curr = parseFloat(parts[3]) || 0;
                    var max = parseFloat(parts[4]) || 100;
                    result.push({
                        name: parts[2] || "Internal",
                        brightness: max > 0 ? Colors.clamp01(curr / max) : 0,
                        isInternal: true, busNumber: -1, available: true
                    });
                }
            } else if (parts[0] === "SYSFS") {
                var dev = (parts[1] || "").trim();
                if (dev) {
                    _intBrightFile.path = "/sys/class/backlight/" + dev + "/brightness";
                    _intMaxFile.path = "/sys/class/backlight/" + dev + "/max_brightness";
                    root._hasInternalSysfs = true;
                }
            } else if (parts[0] === "DDC") {
                ddcBuses[parts[1]] = { name: parts[2] || ("External " + parts[1]) };
            } else if (parts[0] === "DDCVAL") {
                var vals = (parts[2] || "").trim().split(/\s+/);
                ddcVals[parts[1]] = { curr: parseFloat(vals[0]) || 0, max: parseFloat(vals[1]) || 100 };
            } else if (parts[0] === "KBD") {
                var kbdName = (parts[1] || "kbd_backlight").trim();
                var kbdCurr = parseFloat(parts[2]) || 0;
                var kbdMax = parseFloat(parts[3]) || 0;
                if (kbdMax > 0) {
                    root.kbdDevice = {
                        name: kbdName, brightness: Colors.clamp01(kbdCurr / kbdMax),
                        maxSteps: kbdMax, available: true
                    };
                    _kbdBrightFile.path = "/sys/class/leds/" + kbdName + "/brightness";
                    _kbdMaxFile.path = "/sys/class/leds/" + kbdName + "/max_brightness";
                }
            }
        }

        for (var bus in ddcBuses) {
            var val = ddcVals[bus] || { curr: 50, max: 100 };
            result.push({
                name: ddcBuses[bus].name,
                brightness: val.max > 0 ? Colors.clamp01(val.curr / val.max) : 0,
                isInternal: false, busNumber: parseInt(bus, 10), available: true
            });
            root._hasDdc = true;
        }

        root.monitors = result;
        root._detected = true;
    }

    // ── Sysfs FileView for internal display (zero-cost inotify reactive) ──
    property FileView _intBrightFile: FileView {
        path: ""; watchChanges: true; printErrors: false
        onTextChanged: root._updateInternalBrightness()
    }
    property FileView _intMaxFile: FileView {
        path: ""; watchChanges: true; printErrors: false
        onTextChanged: root._updateInternalBrightness()
    }

    function _updateInternalBrightness() {
        if (!_hasInternalSysfs || !_intBrightFile.text || !_intMaxFile.text) return;
        var curr = parseFloat(_intBrightFile.text) || 0;
        var max = parseFloat(_intMaxFile.text) || 100;
        var brightness = max > 0 ? Colors.clamp01(curr / max) : 0;
        var updated = [];
        for (var i = 0; i < monitors.length; i++) {
            var m = monitors[i];
            if (m.isInternal)
                updated.push({ name: m.name, brightness: brightness, isInternal: true, busNumber: -1, available: true });
            else
                updated.push(m);
        }
        if (updated.length > 0) monitors = updated;
    }

    // ── Sysfs FileView for keyboard backlight (zero-cost inotify reactive) ──
    property FileView _kbdBrightFile: FileView {
        path: ""; watchChanges: true; printErrors: false
        onTextChanged: root._updateKbdBrightness()
    }
    property FileView _kbdMaxFile: FileView {
        path: ""; watchChanges: true; printErrors: false
        onTextChanged: root._updateKbdBrightness()
    }

    function _updateKbdBrightness() {
        if (!kbdDevice.available || !_kbdBrightFile.text || !_kbdMaxFile.text) return;
        var curr = parseFloat(_kbdBrightFile.text) || 0;
        var max = parseFloat(_kbdMaxFile.text) || 0;
        if (max > 0)
            kbdDevice = { name: kbdDevice.name, brightness: Colors.clamp01(curr / max), maxSteps: max, available: true };
    }

    // ── DDC-only poll (only active when external DDC monitors exist) ──
    property Process _ddcPollProc: Process {
        running: false
        command: ["sh", "-c", "true"]
        stdout: StdioCollector {
            onStreamFinished: root._parseDdcPoll(this.text || "")
        }
    }

    property Timer _ddcPollTimer: Timer {
        interval: root._ddcPollIntervalMs
        running: root.subscriberCount > 0 && root._detected && root._hasDdc
        repeat: true
        onTriggered: {
            var buses = [];
            for (var i = 0; i < root.monitors.length; i++)
                if (!root.monitors[i].isInternal && root.monitors[i].busNumber >= 0)
                    buses.push(root.monitors[i].busNumber);
            if (buses.length === 0) return;
            var cmd = "";
            for (var j = 0; j < buses.length; j++) {
                if (j > 0) cmd += " ";
                cmd += "val=$(ddcutil getvcp 10 --bus " + buses[j] + " --brief 2>/dev/null | awk '{print $4, $5}'); "
                    + "printf 'DDCVAL|" + buses[j] + "|%s\\n' \"$val\"";
            }
            root._ddcPollProc.command = ["sh", "-c", cmd];
            if (!root._ddcPollProc.running) root._ddcPollProc.running = true;
        }
    }

    function _parseDdcPoll(text) {
        var lines = text.trim().split("\n");
        var ddcVals = {};
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].trim().split("|");
            if (parts[0] === "DDCVAL") {
                var vals = (parts[2] || "").trim().split(/\s+/);
                ddcVals[parts[1]] = { curr: parseFloat(vals[0]) || 0, max: parseFloat(vals[1]) || 100 };
            }
        }
        var updated = [];
        for (var j = 0; j < monitors.length; j++) {
            var m = monitors[j];
            if (!m.isInternal && m.busNumber >= 0 && ddcVals[m.busNumber]) {
                var v = ddcVals[m.busNumber];
                updated.push({
                    name: m.name, brightness: v.max > 0 ? Colors.clamp01(v.curr / v.max) : m.brightness,
                    isInternal: false, busNumber: m.busNumber, available: true
                });
            } else {
                updated.push(m);
            }
        }
        if (updated.length > 0) monitors = updated;
    }

    // ── Set brightness ───────────────────────────
    property Timer _ddcDebounce: Timer {
        interval: root._ddcDebounceMs
        property string _pendingBus: ""
        property int _pendingValue: 0
        onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", _pendingValue.toString(), "--bus", _pendingBus])
    }

    function setBrightness(monitorName, value) {
        var clamped = Colors.clamp01(value);
        var updated = [];
        for (var i = 0; i < monitors.length; i++) {
            var m = monitors[i];
            if (m.name === monitorName) {
                updated.push({ name: m.name, brightness: clamped, isInternal: m.isInternal, busNumber: m.busNumber, available: m.available });
                if (m.isInternal)
                    Quickshell.execDetached(["brightnessctl", "s", Math.round(clamped * 100) + "%"]);
                else if (m.busNumber >= 0) {
                    _ddcDebounce._pendingBus = m.busNumber.toString();
                    _ddcDebounce._pendingValue = Math.round(clamped * 100);
                    _ddcDebounce.restart();
                }
            } else {
                updated.push(m);
            }
        }
        monitors = updated;
    }

    // ── Set keyboard brightness ───────────────────
    function setKbdBrightness(value) {
        if (!kbdDevice.available) return;
        var clamped = Colors.clamp01(value);
        var step = Math.round(clamped * kbdDevice.maxSteps);
        Quickshell.execDetached(["brightnessctl", "-d", kbdDevice.name, "set", step.toString()]);
        kbdDevice = { name: kbdDevice.name, brightness: clamped, maxSteps: kbdDevice.maxSteps, available: true };
    }
}
