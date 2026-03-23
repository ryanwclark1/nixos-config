import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../services"

Rectangle {
  id: root
  property bool _destroyed: false
  property bool _loggedWorkspaceApiUnavailable: false
  property bool _loggedEmptyWorkspaceList: false
  property bool _allowEmptyWorkspaceWarning: false
  property bool _hyprctlFallbackPending: false
  readonly property bool hasWorkspaceContent: workspaceApiAvailable && !!state && (state.workspaces || []).length > 0
  readonly property real contentWidth: vertical ? 28 : (strip.implicitWidth + 12)
  readonly property real contentHeight: vertical ? (strip.implicitHeight + 12) : 24
  height: hasWorkspaceContent ? contentHeight : 0
  radius: vertical ? 12 : (height > 0 ? height / 2 : 0)
  color: Colors.bgWidget

  property bool vertical: false
  property var settings: ({})
  property var anchorWindow: null
  property bool showAddButton: true
  property bool showMiniMap: true
  property var state: ({ workspaces: [], activeWorkspace: -1 })

  readonly property bool workspaceApiAvailable: CompositorAdapter.supportsWorkspaceListing
  width: hasWorkspaceContent ? contentWidth : 0
  implicitWidth: width
  implicitHeight: height
  visible: hasWorkspaceContent

  // ── Niri reactive path ──────────────────────────
  // When NiriService is available, derive state directly from its event-driven
  // properties instead of polling.  This gives instant workspace updates.
  Connections {
    target: NiriService
    enabled: CompositorAdapter.isNiri && NiriService.available
    function onFocusedWorkspaceIdChanged() {
      root._applyFocusedWorkspaceFromNiriService()
    }
    function onFocusedWorkspaceIndexChanged() {
      root._applyFocusedWorkspaceFromNiriService()
    }
    function onWorkspacesUpdated() {
      root._updateStateFromNiriService()
    }
    function onWindowsUpdated() {
      root._updateStateFromNiriService()
    }
    function onWindowUrgentChanged() {
      root._updateStateFromNiriService()
    }
  }

  Timer {
    id: emptyWorkspaceWarningTimer
    interval: 2000
    repeat: false
    running: true
    onTriggered: {
      root._allowEmptyWorkspaceWarning = true;
      root._maybeLogWorkspaceStrip("startup");
    }
  }

  function _maybeLogWorkspaceStrip(context) {
    if (!Config.barWidgetLoadLogging)
      return;
    if (!workspaceApiAvailable) {
      if (_loggedWorkspaceApiUnavailable)
        return;
      _loggedWorkspaceApiUnavailable = true;
      Logger.w("Workspaces", "[" + context + "] listing disabled — compositor=" + CompositorAdapter.compositor);
      return;
    }
    var len = (state && state.workspaces) ? state.workspaces.length : 0;
    if (len === 0) {
      if (!root._allowEmptyWorkspaceWarning)
        return;
      if (!_loggedEmptyWorkspaceList)
        Logger.w("Workspaces", "[" + context + "] no workspaces from compositor (strip hidden; check IPC / session env)");
      _loggedEmptyWorkspaceList = true;
    } else {
      _loggedEmptyWorkspaceList = false;
    }
  }

  Component.onCompleted: {
    if (CompositorAdapter.isNiri && NiriService.available) {
      _applyFocusedWorkspaceFromNiriService()
      _updateStateFromNiriService()
    }
    if (CompositorAdapter.isHyprland) {
      _requestHyprctlWorkspaceSnapshot();
      _updateStateFromHyprland();
      Hyprland.rawEvent.connect(_onHyprlandEvent);
    }
  }

  Component.onDestruction: {
    _destroyed = true;
    if (CompositorAdapter.isHyprland) {
      Hyprland.rawEvent.disconnect(_onHyprlandEvent);
    }
  }

  function _onHyprlandEvent(event) {
    var n = event.name;
    if (n === "workspace" || n === "workspacev2" || n === "createworkspace"
        || n === "destroyworkspace" || n === "openwindow" || n === "closewindow"
        || n === "movewindow" || n === "urgent" || n === "renameworkspace") {
      Qt.callLater(function() { if (root._destroyed) return; _updateStateFromHyprland(); });
    }
  }

  function _requestHyprctlWorkspaceSnapshot() {
    if (!CompositorAdapter.isHyprland || root._hyprctlFallbackPending)
      return;
    root._hyprctlFallbackPending = true;
    hyprctlWorkspaceSnapshot.running = true;
  }

  function _applyHyprctlWorkspaceSnapshot(raw) {
    root._hyprctlFallbackPending = false;

    var snapshot = null;
    try {
      snapshot = JSON.parse(String(raw || "").trim() || "{\"workspaces\":[],\"active\":null}");
    } catch (e) {
      Logger.w("Workspaces", "hyprctl workspace fallback parse failed", e);
      return;
    }

    var wsValues = Array.isArray(snapshot.workspaces) ? snapshot.workspaces : [];
    var workspaces = [];
    var activeId = parseInt(String(snapshot.active && snapshot.active.id !== undefined ? snapshot.active.id : -1), 10);

    for (var i = 0; i < wsValues.length; i++) {
      var ws = wsValues[i];
      if (!ws || ws.id <= 0)
        continue;

      workspaces.push({
        id: ws.id,
        name: String(ws.name || ws.id),
        urgent: false,
        windows: parseInt(String(ws.windows !== undefined ? ws.windows : 0), 10) || 0
      });
    }

    workspaces.sort(function(a, b) { return a.id - b.id; });
    if (workspaces.length === 0)
      return;

    state = {
      workspaces: workspaces,
      activeWorkspace: activeId > 0 ? activeId : root.state.activeWorkspace
    };
    _maybeLogWorkspaceStrip("hyprctl");
  }

  function _updateStateFromHyprland() {
    var wsList = Hyprland.workspaces;
    if (!wsList) {
      _requestHyprctlWorkspaceSnapshot();
      return;
    }

    var wsValues = wsList.values || wsList;
    if (!wsValues || wsValues.length === 0) {
      _requestHyprctlWorkspaceSnapshot();
      return;
    }

    var workspaces = [];
    var activeId = -1;

    for (var i = 0; i < wsValues.length; i++) {
      var ws = wsValues[i];
      if (!ws || ws.id <= 0) continue;

      var windowCount = 0;
      if (ws.toplevels) {
        var tlArr = ws.toplevels.values || ws.toplevels;
        windowCount = tlArr.length || 0;
      }

      if (ws.focused) activeId = ws.id;

      workspaces.push({
        id: ws.id,
        name: String(ws.name || ws.id),
        urgent: !!ws.urgent,
        windows: windowCount
      });
    }

    workspaces.sort(function(a, b) { return a.id - b.id; });
    if (workspaces.length === 0) {
      _requestHyprctlWorkspaceSnapshot();
      return;
    }

    state = {
      workspaces: workspaces,
      activeWorkspace: activeId
    };
    _maybeLogWorkspaceStrip("hyprland");
  }

  function _focusedWorkspaceIdFromNiriService() {
    var focusedId = parseInt(String(NiriService.focusedWorkspaceId || ""), 10);
    if (!isNaN(focusedId) && focusedId > 0)
      return focusedId;

    var all = NiriService.allWorkspaces || [];
    for (var i = 0; i < all.length; i++) {
      var ws = all[i];
      if (!ws || !ws.is_focused)
        continue;
      var resolvedId = ws.idx !== undefined ? ws.idx : ws.id;
      var parsedId = parseInt(String(resolvedId), 10);
      if (!isNaN(parsedId) && parsedId > 0)
        return parsedId;
    }

    return -1;
  }

  function _applyFocusedWorkspaceFromNiriService() {
    var activeId = _focusedWorkspaceIdFromNiriService();
    if (activeId < 0 || root.state.activeWorkspace === activeId)
      return;

    root.state = {
      workspaces: root.state.workspaces,
      activeWorkspace: activeId
    };
  }

  function _updateStateFromNiriService() {
    var workspaces = [];
    var activeId = -1;
    var all = NiriService.allWorkspaces;

    // Pre-compute window metadata per workspace for mini-map
    var wsWindows = {};
    var allWindows = NiriService.windows;
    for (var j = 0; j < allWindows.length; j++) {
      var win = allWindows[j];
      var wsId = win.workspace_id;
      if (!wsWindows[wsId]) wsWindows[wsId] = [];
      
      // Basic bounding box data for mini-map (normalized 0-1)
      if (win.width > 0 && win.height > 0) {
        wsWindows[wsId].push({
          x: win.x,
          y: win.y,
          w: win.width,
          h: win.height,
          active: !!win.is_focused
        });
      }
    }

    for (var i = 0; i < all.length; i++) {
      var ws = all[i];
      var intId = ws.idx !== undefined ? ws.idx : (ws.id !== undefined ? ws.id : i + 1);
      if (ws.is_focused) activeId = intId;

      workspaces.push({
        id: intId,
        name: String(ws.name || intId),
        urgent: !!(ws.is_urgent || ws.urgent),
        windows: (wsWindows[ws.id] || []).length,
        windowData: wsWindows[ws.id] || []
      });
    }

    state = {
      workspaces: workspaces,
      activeWorkspace: activeId
    };
    _maybeLogWorkspaceStrip("niri");
  }

  WorkspaceStrip {
    id: strip
    anchors.centerIn: parent
    vertical: root.vertical
    state: root.state
    settings: root.settings
    showAddButton: root.showAddButton
    showMiniMap: root.showMiniMap
  }

  Process {
    id: hyprctlWorkspaceSnapshot
    running: false
    command: [
      "sh",
      "-c",
      "workspaces=$(hyprctl workspaces -j 2>/dev/null || printf '[]'); " +
      "active=$(hyprctl activeworkspace -j 2>/dev/null || printf '{}'); " +
      "printf '{\"workspaces\":%s,\"active\":%s}' \"$workspaces\" \"$active\""
    ]
    stdout: StdioCollector {
      onStreamFinished: root._applyHyprctlWorkspaceSnapshot(this.text || "")
    }
    onExited: root._hyprctlFallbackPending = false
  }
}
