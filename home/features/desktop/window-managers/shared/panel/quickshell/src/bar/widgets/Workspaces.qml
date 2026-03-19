import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../services"

Rectangle {
  id: root
  property bool _destroyed: false
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

  Component.onCompleted: {
    if (CompositorAdapter.isNiri && NiriService.available) {
      _applyFocusedWorkspaceFromNiriService()
      _updateStateFromNiriService()
    }
    if (CompositorAdapter.isHyprland) {
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

  function _updateStateFromHyprland() {
    var wsList = Hyprland.workspaces;
    if (!wsList) {
      state = { workspaces: [], activeWorkspace: -1 };
      return;
    }

    var wsValues = wsList.values || wsList;
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
    state = {
      workspaces: workspaces,
      activeWorkspace: activeId
    };
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
}
