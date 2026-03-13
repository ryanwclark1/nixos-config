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

  Timer {
    id: pollTimer
    interval: 1200
    running: root.workspaceApiAvailable && CompositorAdapter.isHyprland
    repeat: true
    triggeredOnStart: true
    onTriggered: workspaceProc.running = true
  }

  Process {
    id: workspaceProc
    running: false
    command: [
      "sh",
      "-c",
      "hyprctl workspaces -j 2>/dev/null; printf '\\n'; hyprctl activeworkspace -j 2>/dev/null"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        root.updateStateFromHypr(this.text || "");
      }
    }
  }

  WorkspaceStrip {
    id: strip
    anchors.centerIn: parent
    state: root.state
  }
}
