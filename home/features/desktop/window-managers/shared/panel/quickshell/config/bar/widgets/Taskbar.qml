import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../services"

Row {
  id: root
  spacing: Colors.spacingS
  anchors.verticalCenter: parent.verticalCenter
  property var anchorWindow: null

  property var pinnedApps: []
  property var iconMap: ({})
  property bool seedPinnedApps: false
  readonly property string pinnedPath: Quickshell.env("HOME") + "/.local/state/quickshell/pinned_apps.json"
  readonly property var defaultPinnedApps: [
    { name: "Browser", class: "google-chrome", exec: "google-chrome" },
    { name: "Terminal", class: "com.mitchellh.ghostty", exec: "ghostty" },
    { name: "Code", class: "cursor", exec: "cursor" }
  ]

  property FileView pinnedFile: FileView {
    path: root.pinnedPath
    blockLoading: true
    printErrors: false
    onLoaded: {
      var raw = pinnedFile.text();
      try {
        root.pinnedApps = raw ? JSON.parse(raw) : [];
      } catch(e) {
        root.pinnedApps = [];
      }

      if (root.pinnedApps.length === 0) {
        root.pinnedApps = root.defaultPinnedApps.slice();
        root.seedPinnedApps = true;
        seedPinnedTimer.restart();
      }
    }
    onLoadFailed: (error) => {
      if (error === 2) {
        root.pinnedApps = root.defaultPinnedApps.slice();
        root.seedPinnedApps = true;
        seedPinnedTimer.restart();
      }
    }
  }

  Timer {
    id: seedPinnedTimer
    interval: 0
    repeat: false
    onTriggered: {
      if (!root.seedPinnedApps) return;
      root.seedPinnedApps = false;
      root.savePinned();
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
    else pinnedApps.push({ name: app.title || app.class, class: app.class, exec: app.exec || app.class });
    pinnedApps = pinnedApps; // Trigger update
    savePinned();
  }

  Process {
    id: iconResolverProc
    command: ["qs-icon-resolver"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.iconMap = JSON.parse(this.text || "{}"); } catch(e) { console.warn("Taskbar: icon map parse error:", e) }
      }
    }
  }

  Component.onCompleted: {} // Pinned apps loaded via FileView.onLoaded

  // Combined model: Pinned Apps + Running Apps not in Pinned
  Repeater {
    model: root.pinnedApps
    delegate: TaskButton {
      appClass: modelData.class || ""
      appExec: modelData.exec || ""
      appName: modelData.name || ""
      isPinned: true
      iconMap: root.iconMap
      anchorWindow: root.anchorWindow
      onPinToggled: (app) => root.togglePin(app)
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
          if (pinnedApps[i].class === (modelData.class || "")) return true;
        }
        return false;
      }
      visible: !alreadyPinned && modelData.workspace && modelData.workspace.active
      width: visible ? 32 : 0
      Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      appClass: modelData.class || ""
      appExec: modelData.class || ""
      appName: modelData.title || ""
      appAddress: modelData.address
      isFocused: modelData.activated
      isPinned: false
      iconMap: root.iconMap
      anchorWindow: root.anchorWindow
      onPinToggled: (app) => root.togglePin(app)
    }
  }
}
