import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    property bool isSuspending: false
    property bool wakeReady: true

    // ── Signals ──────────────────────────────────
    signal preparingForSleep()
    signal wakingUp()

    // ── Wake-ready delay (3s post-wake) ──────────
    property Timer _wakeReadyTimer: Timer {
        interval: 3000
        onTriggered: {
            root.wakeReady = true;
        }
    }

    // ── dbus-monitor Process ─────────────────────
    property Process _monitor: Process {
        command: ["qs-sleep-monitor"]
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
            // Auto-restart on crash after a delay
            root._restartTimer.start();
        }
    }

    property Timer _restartTimer: Timer {
        interval: 3000
        onTriggered: {
            if (!root._monitor.running)
                root._monitor.running = true;
        }
    }
}
