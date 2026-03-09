import Quickshell
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property string statePath: Quickshell.statePath("hyprland.json")
  property var workspaces: []
  property var clients: []
  property int activeWorkspace: 0
  property string windowTitle: ""
  property string keyboardLayout: ""
  property string specialWorkspace: ""
  property int pollIntervalMs: 1000

  readonly property bool specialWorkspaceActive: specialWorkspace !== ""

  function parseState(text) {
    if (!text) return;
    try {
      var data = JSON.parse(text);
      root.workspaces = data.workspaces || [];
      root.clients = data.clients || [];
      root.activeWorkspace = data.activeWorkspace || 0;
      root.windowTitle = data.windowTitle || "";
      root.keyboardLayout = data.keyboardLayout || "";
      root.specialWorkspace = data.specialWorkspace || "";
    } catch (err) {
    }
  }

  property FileView stateFile: FileView {
    path: root.statePath
    watchChanges: true
    preload: true
    printErrors: false

    onTextChanged: root.parseState(stateFile.text())
  }

  property Timer refreshTimer: Timer {
    interval: root.pollIntervalMs
    running: true
    repeat: true
    onTriggered: stateFile.reload()
  }

  Component.onCompleted: stateFile.reload()
}
