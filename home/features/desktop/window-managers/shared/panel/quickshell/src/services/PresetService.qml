pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "config/ConfigPersistence.js" as ConfigPersistence
import "preset/PresetData.js" as PresetData

QtObject {
    id: root
    property bool _destroyed: false

    // ── Public state ─────────────────────────────
    property var presets: []

    readonly property string _presetsDir: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/presets"

    // ── Scan for presets ─────────────────────────
    Component.onCompleted: refresh()
    Component.onDestruction: _destroyed = true

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

    function _safePresetName(name) {
        return String(name || "").trim().replace(/[^a-zA-Z0-9_-]/g, "_");
    }

    function _presetPath(name) {
        return root._presetsDir + "/" + root._safePresetName(name) + ".json";
    }

    function _writeFile(path, contents, onDone) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { stdinEnabled: true }',
            root
        );
        proc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && cat > \"$1\"", "sh", path];
        proc.onStarted.connect(function() {
            proc.write(contents);
            proc.stdinEnabled = false;
        });
        proc.onExited.connect(function(code) {
            if (onDone)
                onDone(code === 0);
            proc.destroy();
        });
        proc.running = true;
    }

    function _deleteFile(path, onDone) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process {}',
            root
        );
        proc.command = ["rm", "-f", path];
        proc.onExited.connect(function(code) {
            if (onDone)
                onDone(code === 0);
            proc.destroy();
        });
        proc.running = true;
    }

    function _readFile(path, onDone) {
        var proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { property string collectedText: ""; stdout: StdioCollector { onStreamFinished: parent.collectedText = this.text } }',
            root
        );
        proc.command = ["sh", "-c", "cat \"$1\"", "sh", path];
        proc.onExited.connect(function(code) {
            if (onDone)
                onDone(code === 0, proc.collectedText || "");
            proc.destroy();
        });
        proc.running = true;
    }

    function _applyPresetData(data) {
        Config._loading = true;
        try {
            ConfigPersistence.applyData(Config, data);
            Config.ensureSelectedBar();
            Config.syncLegacyBarSettingsFromPrimary();
        } finally {
            Config._loading = false;
        }
        Config.applyRuntimeSettings();
        Config.save();
    }

    // ── Save preset ──────────────────────────────
    function savePreset(name, description) {
        var safeName = root._safePresetName(name);
        if (!safeName)
            return;

        var data = ConfigPersistence.buildData(Config);
        var presetData = PresetData.sanitizePresetData(data);
        presetData.description = String(description || "");

        root._writeFile(root._presetPath(safeName), JSON.stringify(presetData, null, 2) + "\n", function(success) {
            if (!success)
                Logger.e("PresetService", "failed to save preset:", safeName);
            root.refresh();
        });
    }

    // ── Load preset ──────────────────────────────
    function loadPreset(name) {
        var safeName = root._safePresetName(name);
        if (!safeName)
            return;

        root._readFile(root._presetPath(safeName), function(success, text) {
            if (!success) {
                Logger.e("PresetService", "failed to read preset:", safeName);
                return;
            }

            try {
                var presetData = JSON.parse(text || "{}");
                var currentData = ConfigPersistence.buildData(Config);
                var mergedData = PresetData.mergePresetData(currentData, presetData);
                root._applyPresetData(mergedData);
            } catch (e) {
                Logger.e("PresetService", "failed to load preset:", e);
            }
        });
    }

    // ── Built-in presets ─────────────────────────
    readonly property var builtinPresets: PresetData.builtinPresets()

    function loadBuiltinPreset(presetId) {
        var preset = PresetData.findBuiltinPreset(presetId);
        if (!preset) {
            Logger.e("PresetService", "unknown built-in preset:", presetId);
            return;
        }

        var currentData = ConfigPersistence.buildData(Config);
        var mergedData = PresetData.mergePresetData(currentData, preset.data);
        root._applyPresetData(mergedData);
        ToastService.showNotice("Preset Applied", preset.name + " preset loaded");
    }

    // ── Delete preset ────────────────────────────
    function deletePreset(name) {
        var safeName = root._safePresetName(name);
        if (!safeName)
            return;

        root._deleteFile(root._presetPath(safeName), function() {
            root.refresh();
        });
    }

}
