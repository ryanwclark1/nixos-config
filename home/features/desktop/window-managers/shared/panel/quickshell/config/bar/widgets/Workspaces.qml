import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

Rectangle {
  id: root
  height: 24
  radius: height / 2
  color: Colors.bgWidget
  anchors.verticalCenter: parent.verticalCenter

  property var anchorWindow: null
  property var state: ({ workspaces: [], activeWorkspace: -1 })

  readonly property bool workspaceApiAvailable: CompositorAdapter.isHyprland || CompositorAdapter.isNiri
  width: workspaceApiAvailable && state.workspaces.length > 0 ? (strip.implicitWidth + 12) : 0
  visible: width > 0

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
    if (CompositorAdapter.isHyprland) {
      return [
        "sh",
        "-c",
        "hyprctl workspaces -j 2>/dev/null; printf '\\n'; hyprctl activeworkspace -j 2>/dev/null"
      ];
    }
    if (CompositorAdapter.isNiri) {
      return ["niri", "msg", "-j", "workspaces"];
    }
    return ["sh", "-c", "echo '[]'"];
  }

  Timer {
    id: pollTimer
    interval: 1200
    running: root.workspaceApiAvailable
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
        if (CompositorAdapter.isHyprland) root.updateStateFromHypr(this.text || "");
        else if (CompositorAdapter.isNiri) root.updateStateFromNiri(this.text || "");
        else root.state = ({ workspaces: [], activeWorkspace: -1 });
      }
    }
  }

  WorkspaceStrip {
    id: strip
    anchors.centerIn: parent
    state: root.state
  }
}
