pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // id (string) → { name: string, project: string, lastActive: number }
    property var workspaceData: ({})

    readonly property string savePath: Quickshell.statePath("workspace-identity.json")
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
    readonly property FileView _stateFile: FileView {
        path: root.savePath
        blockLoading: true
        printErrors: false
        atomicWrites: true
    }

    function saveState() {
        if (_loading) return;
        _stateFile.setText(JSON.stringify(workspaceData));
    }

    function loadState() {
        _loading = true;
        var raw = (_stateFile.text() || "").trim();
        if (raw) {
            try {
                workspaceData = JSON.parse(raw);
            } catch (e) {
                Logger.w("WorkspaceIdentityService", "Failed to load state:", e);
            }
        }
        _loading = false;
    }

    Component.onCompleted: loadState()
}
