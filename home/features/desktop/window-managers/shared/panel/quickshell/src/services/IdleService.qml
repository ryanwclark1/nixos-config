pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

QtObject {
    id: root

    // ── Sleep/Wake state (absorbed from SuspendManager) ──
    property bool isSuspending: false
    property bool wakeReady: true

    signal preparingForSleep()
    signal wakingUp()

    // ── Idle inhibition (absorbed from CaffeineService) ──
    readonly property bool inhibiting: Config.idleInhibitEnabled || _mediaInhibit
    readonly property bool _mediaInhibit: Config.inhibitIdleWhenPlaying && MediaService.isPlaying
    readonly property bool canUseIdleInhibitor: (Quickshell.env("QT_QPA_PLATFORM") || "").toLowerCase() !== "offscreen"

    function toggle() {
        Config.idleInhibitEnabled = !Config.idleInhibitEnabled;
    }

    // ── AC vs Battery timeout accessors ──
    // These derive the appropriate timeout based on power source.
    readonly property int lockTimeout: SystemStatus.isBatteryPowered
        ? Config.powerBatLockTimeout : Config.powerAcLockTimeout
    readonly property int suspendTimeout: SystemStatus.isBatteryPowered
        ? Config.powerBatSuspendTimeout : Config.powerAcSuspendTimeout
    readonly property int monitorTimeout: SystemStatus.isBatteryPowered
        ? Config.powerBatMonitorTimeout : Config.powerAcMonitorTimeout
    readonly property string suspendAction: SystemStatus.isBatteryPowered
        ? Config.powerBatSuspendAction : Config.powerAcSuspendAction

    // ── Named constants ──────────────────────────
    readonly property int _wakeReadyDelayMs: 3000
    readonly property int _restartDelayMs: 3000

    // ── Wake-ready delay (3s post-wake) ──────────
    property Timer _wakeReadyTimer: Timer {
        interval: root._wakeReadyDelayMs
        onTriggered: root.wakeReady = true
    }

    // ── dbus-monitor Process ─────────────────────
    property Process _monitor: Process {
        command: DependencyService.resolveCommand("qs-sleep-monitor")
        running: true

        stdout: SplitParser {
            onRead: data => {
                var line = (data || "").trim();
                if (line === "SUSPEND") {
                    root.isSuspending = true;
                    root.wakeReady = false;
                    root._wakeReadyTimer.stop();
                    root.preparingForSleep();
                } else if (line === "WAKE") {
                    root.isSuspending = false;
                    root._wakeReadyTimer.restart();
                    root.wakingUp();
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root._restartTimer.start();
        }
    }

    property Timer _restartTimer: Timer {
        interval: root._restartDelayMs
        onTriggered: {
            if (!root._monitor.running)
                root._monitor.running = true;
        }
    }

    onInhibitingChanged: {
        // Source of truth for other components.
        // Composition-level inhibition handled via external qs-inhibitor.
    }

    Component.onCompleted: {
    }
}
