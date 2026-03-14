import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

Rectangle {
  id: root
  height: vertical ? (workspaceApiAvailable && state.workspaces.length > 0 ? (strip.implicitHeight + 12) : 0) : 24
  radius: vertical ? 12 : height / 2
  color: Colors.bgWidget

  property bool vertical: false
  property var anchorWindow: null
  property var state: ({ workspaces: [], activeWorkspace: -1 })

  readonly property bool workspaceApiAvailable: CompositorAdapter.supportsWorkspaceListing
  width: vertical ? (workspaceApiAvailable && state.workspaces.length > 0 ? 28 : 0)
       : (workspaceApiAvailable && state.workspaces.length > 0 ? (strip.implicitWidth + 12) : 0)
  implicitWidth: width
  implicitHeight: height
  visible: vertical ? (height > 0) : (width > 0)

  // ── Niri reactive path ──────────────────────────
  // When NiriService is available, derive state directly from its event-driven
  // properties instead of polling.  This gives instant workspace updates.
  Connections {
    target: NiriService
    enabled: CompositorAdapter.isNiri && NiriService.available
    function onWorkspacesUpdated() {
      root._updateStateFromNiriService()
    }
    function onWindowsUpdated() {
      root._updateStateFromNiriService()
    }
  }

  Component.onCompleted: {
    if (CompositorAdapter.isNiri && NiriService.available)
      _updateStateFromNiriService()
  }

  function _updateStateFromNiriService() {
    var workspaces = [];
    var activeId = -1;
    var all = NiriService.allWorkspaces;

    // Pre-compute window counts per workspace (O(windows) instead of O(ws × windows))
    var windowCounts = {};
    var allWindows = NiriService.windows;
    for (var j = 0; j < allWindows.length; j++) {
      var wsId = allWindows[j].workspace_id;
      windowCounts[wsId] = (windowCounts[wsId] || 0) + 1;
    }

    for (var i = 0; i < all.length; i++) {
      var ws = all[i];
      var intId = ws.idx !== undefined ? ws.idx : (ws.id !== undefined ? ws.id : i + 1);
      if (ws.is_focused) activeId = intId;

      workspaces.push({
        id: intId,
        name: String(ws.name || intId),
        urgent: !!(ws.is_urgent || ws.urgent),
        windows: windowCounts[ws.id] || 0
      });
    }

    state = {
      workspaces: workspaces,
      activeWorkspace: activeId
    };
  }

  // ── Hyprland polling path (unchanged) ───────────
  function updateStateFromHypr(rawText) {
    try {
      var lines = (rawText || "").trim().split("\n");
      if (lines.length < 2) return;
      var workspacesRaw = JSON.parse(lines[0] || "[]");
      var activeRaw = JSON.parse(lines[1] || "{}");

      var workspaces = [];
      for (var i = 0; i < workspacesRaw.length; i++) {
        var ws = workspacesRaw[i];
        if (!ws || ws.id <= 0) continue;
        workspaces.push({
          id: ws.id,
          name: String(ws.name || ws.id),
          urgent: !!ws.hasurgent
        });
      }
      workspaces.sort(function(a, b) { return a.id - b.id; });

      state = {
        workspaces: workspaces,
        activeWorkspace: activeRaw && activeRaw.id ? activeRaw.id : -1
      };
    } catch (e) {
      state = ({ workspaces: [], activeWorkspace: -1 });
    }
  }

  function updateStateFromNiri(rawText) {
    try {
      var parsed = JSON.parse(rawText || "[]");
      var source = [];
      if (Array.isArray(parsed)) source = parsed;
      else if (parsed && Array.isArray(parsed.workspaces)) source = parsed.workspaces;

      var workspaces = [];
      var activeId = -1;

      for (var i = 0; i < source.length; i++) {
        var ws = source[i];
        if (!ws) continue;

        var id = ws.idx;
        if (id === undefined || id === null) id = ws.id;
        if (id === undefined || id === null) id = ws.index;
        if (id === undefined || id === null) continue;

        var intId = parseInt(id, 10);
        if (isNaN(intId) || intId <= 0) continue;

        var isActive = !!(ws.is_active || ws.active || ws.is_focused || ws.focused);
        if (isActive) activeId = intId;

        workspaces.push({
          id: intId,
          name: String(ws.name || intId),
          urgent: !!(ws.is_urgent || ws.urgent)
        });
      }

      workspaces.sort(function(a, b) { return a.id - b.id; });
      state = {
        workspaces: workspaces,
        activeWorkspace: activeId
      };
    } catch (e) {
      state = ({ workspaces: [], activeWorkspace: -1 });
    }
  }

  function workspaceQueryCommand() {
    return CompositorAdapter.workspaceListCommand();
  }

  // Only poll when NiriService is NOT available (Hyprland, or fallback)
  Timer {
    id: pollTimer
    interval: 1200
    running: root.workspaceApiAvailable && !CompositorAdapter.isNiri
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      workspaceProc.command = root.workspaceQueryCommand();
      workspaceProc.running = true;
    }
  }

  Process {
    id: workspaceProc
    running: false
    command: root.workspaceQueryCommand()
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = String(this.text || "").trim();
        if (raw === "") {
          root.state = ({ workspaces: [], activeWorkspace: -1 });
          return;
        }

        try {
          JSON.parse(raw);
          root.updateStateFromNiri(raw);
          return;
        } catch (e) {}

        if (raw.indexOf("\n") !== -1) {
          root.updateStateFromHypr(raw);
          return;
        }
        root.state = ({ workspaces: [], activeWorkspace: -1 });
      }
    }
  }

  WorkspaceStrip {
    id: strip
    anchors.centerIn: parent
    vertical: root.vertical
    state: root.state
  }
}
