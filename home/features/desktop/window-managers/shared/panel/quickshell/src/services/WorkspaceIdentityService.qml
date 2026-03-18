pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // id (string) → { name: string, project: string, lastActive: number }
    property var workspaceData: ({})
    
    readonly property string savePath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/workspace-identity.json"
    property bool _loading: false

    function getWorkspaceName(id) {
        var data = workspaceData[id];
        return data ? (data.name || "") : "";
    }

    function setWorkspaceName(id, name) {
        var data = workspaceData[id] || {};
        data.name = name;
        workspaceData[id] = data;
        workspaceDataChanged();
        saveState();
    }

    function getActiveProject() {
        var focusedId = CompositorAdapter.isNiri ? NiriService.focusedWorkspaceId : "";
        if (!focusedId) return "";
        var data = workspaceData[focusedId];
        return data ? (data.name || "") : "";
    }

    // ── Persistence ──────────────────────────────
    function saveState() {
        if (_loading) return;
        var content = JSON.stringify(workspaceData);
        _saveProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && cat > \"$1\"", "sh", savePath];
        _saveProc.running = true;
    }

    property Process _saveProc: Process {
        stdinEnabled: true
        onStarted: {
            write(JSON.stringify(root.workspaceData));
            stdinEnabled = false;
        }
    }

    function loadState() {
        _loading = true;
        _loadProc.running = true;
    }

    property Process _loadProc: Process {
        command: ["cat", root.savePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() !== "") {
                        root.workspaceData = JSON.parse(this.text);
                    }
                } catch (e) {
                    console.warn("[WorkspaceIdentity] Failed to load state:", e);
                }
                root._loading = false;
            }
        }
    }

    Component.onCompleted: loadState()
}
