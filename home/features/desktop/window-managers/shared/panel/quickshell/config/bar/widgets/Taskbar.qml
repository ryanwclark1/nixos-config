import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import "../../services"

Row {
  id: root
  spacing: 8
  anchors.verticalCenter: parent.verticalCenter

  property var pinnedApps: []
  readonly property string pinnedPath: Quickshell.statePath("pinned_apps.json")

  property FileView pinnedFile: FileView {
    path: ""
    onLoaded: {
      try { root.pinnedApps = JSON.parse(text); } catch(e) {}
    }
  }

  function loadPinned() {
    if (pinnedFile.path === "") pinnedFile.path = root.pinnedPath;
    Quickshell.execDetached(["sh", "-c", "mkdir -p $(dirname " + pinnedPath + ") && touch " + pinnedPath]);
    pinnedFile.reload();
    if (pinnedApps.length === 0) {
      // Default pinned apps
      pinnedApps = [
        { name: "Browser", class: "google-chrome", exec: "google-chrome" },
        { name: "Terminal", class: "kitty", exec: "kitty" },
        { name: "Files", class: "nemo", exec: "nemo" },
        { name: "Code", class: "cursor", exec: "cursor" }
      ];
      savePinned();
    }
  }

  function savePinned() {
    pinnedFile.setText(JSON.stringify(pinnedApps));
  }

  function togglePin(app) {
    var found = -1;
    for (var i = 0; i < pinnedApps.length; i++) {
      if (pinnedApps[i].class === app.class) { found = i; break; }
    }
    if (found !== -1) pinnedApps.splice(found, 1);
    else pinnedApps.push({ name: app.title || app.class, class: app.class, exec: app.class });
    pinnedApps = pinnedApps; // Trigger update
    savePinned();
  }

  Component.onCompleted: loadPinned()

  // Combined model: Pinned Apps + Running Apps not in Pinned
  Repeater {
    model: root.pinnedApps
    delegate: TaskButton {
      appClass: modelData.class || ""
      appExec: modelData.exec || ""
      appName: modelData.name || ""
      isPinned: true
    }
  }

  // Separator if needed
  Rectangle {
    width: 1; height: 16; color: Colors.border; visible: Hyprland.toplevels.count > 0
    anchors.verticalCenter: parent.verticalCenter
  }

  Repeater {
    model: Hyprland.toplevels
    delegate: TaskButton {
      // Only show if not already pinned and on active workspace
      property bool alreadyPinned: {
        for (var i = 0; i < pinnedApps.length; i++) {
          if (pinnedApps[i].class === (modelData.objectName || "")) return true;
        }
        return false;
      }
      visible: !alreadyPinned && modelData.workspace && modelData.workspace.active
      width: visible ? 32 : 0
      appClass: modelData.objectName || ""
      appAddress: modelData.address
      isFocused: modelData.activated
      isPinned: false
    }
  }
}
