pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Detects when games are running (via gamemoded or fullscreen heuristics)
// and signals other services to reduce animations, polling, and effects.
//
// Integration points:
//   - NiriService: reduces window update batching interval
//   - SpectrumService: can pause cava during gaming
//   - SystemStatus: can reduce poll frequency
//   - Animations: can be disabled via `active` property
//
// Detection methods (in priority order):
//   1. gamemoded D-Bus (if gamemode is installed)
//   2. Process detection for known game launchers/engines
QtObject {
    id: root

    property bool active: _gamemodedActive || _processDetected
    property bool enabled: true  // Config toggle

    // Individual detection sources
    property bool _gamemodedActive: false
    property bool _processDetected: false

    // List of process names that indicate gaming
    readonly property var _gameProcesses: [
        "gamemoded", "steam", "lutris", "mangohud",
        "gamemode", "gamescope"
    ]

    // ── gamemoded polling via D-Bus ──────────────────
    property Process _gamemodedProc: Process {
        command: ["sh", "-c",
            "if command -v gamemoded >/dev/null 2>&1; then "
            + "busctl get-property com.feralinteractive.GameMode "
            + "/com/feralinteractive/GameMode "
            + "com.feralinteractive.GameMode ClientCount 2>/dev/null "
            + "| awk '{print $2}'; "
            + "else echo -1; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt((this.text || "").trim(), 10)
                if (val < 0) {
                    // gamemoded not available, rely on process detection only
                    root._gamemodedActive = false
                } else {
                    root._gamemodedActive = val > 0
                }
            }
        }
    }

    // ── Process detection fallback ──────────────────
    property Process _processProc: Process {
        command: ["sh", "-c",
            "pgrep -c -f 'gamescope|gamemoded' 2>/dev/null || echo 0"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var count = parseInt((this.text || "").trim(), 10) || 0
                root._processDetected = count > 0
            }
        }
    }

    property Timer _pollTimer: Timer {
        interval: 5000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root._gamemodedProc.running)
                root._gamemodedProc.running = true
            if (!root._processProc.running)
                root._processProc.running = true
        }
    }
}
