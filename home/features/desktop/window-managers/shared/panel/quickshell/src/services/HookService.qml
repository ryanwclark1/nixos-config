pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// User-extensible hook system. Runs scripts in response to system events.
//
// Hook resolution (first match wins):
//   1. Config.hookPaths[hookName] — per-hook override path
//   2. ~/.config/quickshell/hooks/<hookName> — directory-based
//
// Hook scripts receive: $1 = hookName, $2 = hookValue
QtObject {
    id: root

    readonly property string hookDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/hooks"

    readonly property var hookCatalog: [
        { name: "wallpaper-changed", category: "Appearance", description: "Wallpaper changed on any monitor", valueDescription: "wallpaper file path" },
        { name: "theme-changed", category: "Appearance", description: "Theme changed", valueDescription: "theme name" },
        { name: "colors-changed", category: "Appearance", description: "Shell colors changed (after transition)", valueDescription: "path to colors-export.json" },
        { name: "nightlight-toggled", category: "Appearance", description: "Night light toggled", valueDescription: "enabled or disabled" },
        { name: "battery-level", category: "Power", description: "Battery level changed (5% increments)", valueDescription: "0-100" },
        { name: "power-source-changed", category: "Power", description: "AC/battery power source changed", valueDescription: "ac or battery" },
        { name: "idle-inhibit-changed", category: "Power", description: "Idle inhibitor toggled", valueDescription: "enabled or disabled" },
        { name: "sleep", category: "Power", description: "System preparing to sleep", valueDescription: "(empty)" },
        { name: "wake", category: "Power", description: "System woke from sleep", valueDescription: "(empty)" },
        { name: "volume-changed", category: "Audio", description: "Output volume changed (debounced)", valueDescription: "0-100" },
        { name: "mute-toggled", category: "Audio", description: "Output mute toggled", valueDescription: "muted or unmuted" },
        { name: "brightness-changed", category: "Display", description: "Display brightness changed (debounced)", valueDescription: "0-100" },
        { name: "dnd-toggled", category: "Notifications", description: "Do Not Disturb toggled", valueDescription: "enabled or disabled" },
        { name: "recording-started", category: "Media", description: "Screen recording started", valueDescription: "(empty)" },
        { name: "recording-stopped", category: "Media", description: "Screen recording stopped", valueDescription: "(empty)" }
    ]

    // ── Hook execution ─────────────────────────────
    function fireHook(hookName, hookValue) {
        if (!Config.hooksEnabled) return;

        var scriptPath = _resolveHookPath(hookName);
        if (!scriptPath) return;

        var args = [
            "sh",
            "-c",
            'script="$1"; shift; [ -x "$script" ] || exit 0; exec "$script" "$@"',
            "sh",
            scriptPath,
            hookName
        ];
        if (hookValue !== undefined && hookValue !== null && hookValue !== "")
            args.push(String(hookValue));

        _runProc.command = args;
        if (!_runProc.running)
            _runProc.running = true;
    }

    function fireHookDebounced(hookName, hookValue, ms) {
        if (!Config.hooksEnabled) return;
        _pendingDebounced[hookName] = hookValue;
        if (!_debouncers[hookName]) {
            var timer = Qt.createQmlObject(
                'import QtQuick; Timer { property string hookName; interval: ' + (ms || 500) + '; onTriggered: parent._firePending(hookName); }',
                root
            );
            timer.hookName = hookName;
            _debouncers[hookName] = timer;
        }
        _debouncers[hookName].restart();
    }

    function _firePending(hookName) {
        var val = _pendingDebounced[hookName];
        delete _pendingDebounced[hookName];
        fireHook(hookName, val);
    }

    function _resolveHookPath(hookName) {
        // Config override first
        var paths = Config.hookPaths || {};
        if (paths[hookName]) return paths[hookName];
        // Directory-based fallback
        return hookDir + "/" + hookName;
    }

    // ── Internal state ─────────────────────────────
    property var _pendingDebounced: ({})
    property var _debouncers: ({})
    property int _lastBatteryBucket: -1
    property int _lastBrightness: -1

    property Process _runProc: Process {
        running: false
        command: ["true"]
        onExited: (exitCode, exitStatus) => {
            // Fire-and-forget; log errors in debug
            if (exitCode !== 0)
                Logger.w("HookService", "hook exited with code " + exitCode);
        }
    }

    // ── Ensure hooks directory exists ─────────────
    property Process _mkdirProc: Process {
        running: true
        command: ["mkdir", "-p", root.hookDir]
    }

    // ── Service connections ─────────────────────────

    // Wallpaper changes (via Config.wallpaperPaths)
    property Connections _wallpaperConn: Connections {
        target: Config
        function onWallpaperPathsChanged() {
            var paths = Config.wallpaperPaths || {};
            // Fire with the first monitor's wallpaper path
            var keys = Object.keys(paths);
            if (keys.length > 0)
                root.fireHook("wallpaper-changed", paths[keys[0]]);
        }
    }

    // Theme changes
    property Connections _themeConn: Connections {
        target: Config
        function onThemeNameChanged() {
            if (Config.themeName)
                root.fireHook("theme-changed", Config.themeName);
        }
    }

    // Night light
    property Connections _nightLightConn: Connections {
        target: NightLightService
        function onActiveChanged() {
            root.fireHook("nightlight-toggled", NightLightService.active ? "enabled" : "disabled");
        }
    }

    // Power source
    property Connections _powerConn: Connections {
        target: PowerService
        function onPowerSourceChanged() {
            root.fireHook("power-source-changed", PowerService.powerSource);
        }
    }

    // Idle inhibitor + sleep/wake (unified IdleService)
    property Connections _idleConn: Connections {
        target: IdleService
        function onInhibitingChanged() {
            root.fireHook("idle-inhibit-changed", IdleService.inhibiting ? "enabled" : "disabled");
        }
        function onPreparingForSleep() { root.fireHook("sleep", ""); }
        function onWakingUp() { root.fireHook("wake", ""); }
    }

    // Volume (debounced)
    property Connections _audioConn: Connections {
        target: AudioService
        function onOutputVolumeChanged() {
            root.fireHookDebounced("volume-changed", Math.round(AudioService.outputVolume * 100), 500);
        }
        function onOutputMutedChanged() {
            root.fireHook("mute-toggled", AudioService.outputMuted ? "muted" : "unmuted");
        }
    }

    // Recording
    property Connections _recordingConn: Connections {
        target: RecordingService
        function onIsRecordingChanged() {
            root.fireHook(RecordingService.isRecording ? "recording-started" : "recording-stopped", "");
        }
    }

    // Battery level (5% bucket increments)
    property var _batteryDevice: UPower.displayDevice
    property Connections _batteryConn: Connections {
        target: root._batteryDevice
        enabled: root._batteryDevice != null && root._batteryDevice.isPresent
        function onPercentageChanged() {
            var pct = Math.round(root._batteryDevice.percentage * 100);
            var bucket = Math.floor(pct / 5) * 5;
            if (bucket !== root._lastBatteryBucket) {
                root._lastBatteryBucket = bucket;
                root.fireHook("battery-level", pct);
            }
        }
    }

    // Brightness (poll-based since primaryMonitor is a JS object, not a QObject)
    property Connections _brightnessConn: Connections {
        target: BrightnessService
        function onMonitorsChanged() {
            if (BrightnessService.monitors.length > 0) {
                var b = Math.round(BrightnessService.monitors[0].brightness);
                if (b !== root._lastBrightness) {
                    root._lastBrightness = b;
                    root.fireHookDebounced("brightness-changed", b, 500);
                }
            }
        }
    }
}
