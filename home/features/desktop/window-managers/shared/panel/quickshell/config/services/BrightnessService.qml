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

    // ── Subscriber-based polling ─────────────────
    property int subscriberCount: 0

    // ── Internal state ───────────────────────────
    property bool _detected: false

    // ── Detection on startup + wake ──────────────
    Component.onCompleted: _detectMonitors()

    property Connections _suspendConn: Connections {
        target: SuspendManager
        function onWakingUp() {
            // DDC devices may have changed after wake
            root._detected = false;
            root._detectTimer.restart();
        }
    }

    property Timer _detectTimer: Timer {
        interval: 3000   // wait for hardware to settle after wake
        onTriggered: root._detectMonitors()
    }

    property Process _detectProc: Process {
        running: false
        command: ["sh", "-c",
            // Line 1: internal brightness (brightnessctl)
            "int_avail=0; int_curr=0; int_max=100; int_name='eDP-1'; " + "if command -v brightnessctl >/dev/null 2>&1; then " + "if brightnessctl -m 2>/dev/null | head -n1 | grep -q .; then " + "int_avail=1; int_curr=$(brightnessctl g 2>/dev/null || echo 0); " + "int_max=$(brightnessctl m 2>/dev/null || echo 100); fi; fi; " + "printf 'INT|%s|%s|%s|%s\\n' \"$int_avail\" \"$int_name\" \"$int_curr\" \"$int_max\"; " +
            // Line 2+: DDC external monitors
            "if command -v ddcutil >/dev/null 2>&1; then " + "ddcutil detect --brief 2>/dev/null | awk '" + "/^Display [0-9]/ { bus=\"\"; name=\"\" } " + "/I2C bus:/ { gsub(/.*\\/dev\\/i2c-/, \"\"); bus=$0 } " + "/Monitor:/ { $1=\"\"; name=$0; gsub(/^[ \\t]+/, \"\", name) } " + "bus && name { printf \"DDC|%s|%s\\n\", bus, name; bus=\"\"; name=\"\" }'" + "; for bus in $(ddcutil detect --brief 2>/dev/null | awk '/I2C bus:/ {gsub(/.*i2c-/,\"\"); print}'); do " + "val=$(ddcutil getvcp 10 --bus \"$bus\" --brief 2>/dev/null | awk '{print $4, $5}'); " + "printf 'DDCVAL|%s|%s\\n' \"$bus\" \"$val\"; done; fi"]
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
        var ddcBuses = {};   // bus -> {name}
        var ddcVals = {};    // bus -> {curr, max}

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (!line)
                continue;

            var parts = line.split("|");
            if (parts[0] === "INT") {
                var avail = parts[1] === "1";
                if (avail) {
                    var curr = parseFloat(parts[3]) || 0;
                    var max = parseFloat(parts[4]) || 100;
                    result.push({
                        name: parts[2] || "Internal",
                        brightness: max > 0 ? Colors.clamp01(curr / max) : 0,
                        isInternal: true,
                        busNumber: -1,
                        available: true
                    });
                }
            } else if (parts[0] === "DDC") {
                ddcBuses[parts[1]] = {
                    name: parts[2] || ("External " + parts[1])
                };
            } else if (parts[0] === "DDCVAL") {
                var vals = (parts[2] || "").trim().split(/\s+/);
                ddcVals[parts[1]] = {
                    curr: parseFloat(vals[0]) || 0,
                    max: parseFloat(vals[1]) || 100
                };
            }
        }

        // Merge DDC entries
        for (var bus in ddcBuses) {
            var val = ddcVals[bus] || {
                curr: 50,
                max: 100
            };
            result.push({
                name: ddcBuses[bus].name,
                brightness: val.max > 0 ? Colors.clamp01(val.curr / val.max) : 0,
                isInternal: false,
                busNumber: parseInt(bus, 10),
                available: true
            });
        }

        root.monitors = result;
        root._detected = true;
    }

    // ── Set brightness ───────────────────────────
    property Timer _ddcDebounce: Timer {
        interval: 300
        property string _pendingBus: ""
        property int _pendingValue: 0
        onTriggered: {
            Quickshell.execDetached(["ddcutil", "setvcp", "10", _pendingValue.toString(), "--bus", _pendingBus]);
        }
    }

    function setBrightness(monitorName, value) {
        var clamped = Colors.clamp01(value);
        var updated = [];
        for (var i = 0; i < monitors.length; i++) {
            var m = monitors[i];
            if (m.name === monitorName) {
                var copy = {
                    name: m.name,
                    brightness: clamped,
                    isInternal: m.isInternal,
                    busNumber: m.busNumber,
                    available: m.available
                };
                updated.push(copy);

                if (m.isInternal) {
                    Quickshell.execDetached(["brightnessctl", "s", Math.round(clamped * 100) + "%"]);
                } else if (m.busNumber >= 0) {
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

    // ── Polling for brightness changes (internal only) ──
    property Process _internalPollProc: Process {
        running: false
        command: ["sh", "-c", "curr=$(brightnessctl g 2>/dev/null || echo 0); " + "max=$(brightnessctl m 2>/dev/null || echo 100); " + "echo \"$curr $max\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = (this.text || "").trim().split(/\s+/);
                var curr = parseFloat(parts[0]) || 0;
                var max = parseFloat(parts[1]) || 100;
                var brightness = max > 0 ? Colors.clamp01(curr / max) : 0;

                var updated = [];
                for (var i = 0; i < root.monitors.length; i++) {
                    var m = root.monitors[i];
                    if (m.isInternal) {
                        updated.push({
                            name: m.name,
                            brightness: brightness,
                            isInternal: true,
                            busNumber: -1,
                            available: true
                        });
                    } else {
                        updated.push(m);
                    }
                }
                if (updated.length > 0)
                    root.monitors = updated;
            }
        }
    }

    property Timer _pollTimer: Timer {
        interval: 2000
        running: root.subscriberCount > 0 && root._detected
        repeat: true
        onTriggered: {
            if (!root._internalPollProc.running)
                root._internalPollProc.running = true;
        }
    }
}
