pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    property var presets: []

    readonly property string _presetsDir: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/presets"
    readonly property string _configPath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/config.json"

    // ── Scan for presets ─────────────────────────
    Component.onCompleted: refresh()

    property Process _scanProc: Process {
        running: false
        command: ["sh", "-c",
            "mkdir -p '" + root._presetsDir + "'; "
            + "for f in '" + root._presetsDir + "'/*.json; do "
            + "[ -f \"$f\" ] || continue; "
            + "name=$(basename \"$f\" .json); "
            + "created=$(stat -c %Y \"$f\" 2>/dev/null || echo 0); "
            + "desc=$(head -c 4096 \"$f\" | jq -r '.description // \"\"' 2>/dev/null || echo ''); "
            + "printf '%s|%s|%s\\n' \"$name\" \"$created\" \"$desc\"; "
            + "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = (this.text || "").trim().split("\n");
                var result = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (!line) continue;
                    var parts = line.split("|");
                    if (parts.length < 2) continue;
                    result.push({
                        name: parts[0],
                        created: parseInt(parts[1], 10) || 0,
                        description: parts[2] || ""
                    });
                }
                root.presets = result;
            }
        }
    }

    function refresh() {
        if (!_scanProc.running)
            _scanProc.running = true;
    }

    // ── Save preset ──────────────────────────────
    function savePreset(name, description) {
        if (!name) return;
        var safeName = name.replace(/[^a-zA-Z0-9_-]/g, "_");
        // Read current config, inject description, write to preset file
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p '" + _presetsDir + "'; "
            + "jq '. + {\"description\": " + JSON.stringify(description || "") + "}' "
            + "'" + _configPath + "' > '" + _presetsDir + "/" + safeName + ".json' 2>/dev/null"
        ]);
        // Refresh after a short delay to pick up the new file
        _refreshDelay.restart();
    }

    property Timer _refreshDelay: Timer {
        interval: 500
        onTriggered: root.refresh()
    }

    // ── Load preset ──────────────────────────────
    function loadPreset(name) {
        if (!name) return;
        var safeName = name.replace(/[^a-zA-Z0-9_-]/g, "_");
        Quickshell.execDetached(["sh", "-c",
            "cp '" + _presetsDir + "/" + safeName + ".json' '" + _configPath + "' 2>/dev/null"
        ]);
        // Trigger config reload
        Qt.callLater(function() { Config.load(); });
    }

    // ── Delete preset ────────────────────────────
    function deletePreset(name) {
        if (!name) return;
        var safeName = name.replace(/[^a-zA-Z0-9_-]/g, "_");
        Quickshell.execDetached(["rm", "-f", _presetsDir + "/" + safeName + ".json"]);
        _refreshDelay.restart();
    }

}
