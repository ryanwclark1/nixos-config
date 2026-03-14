import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

Flow {
  id: root
  spacing: Colors.spacingS
  property bool vertical: false
  flow: vertical ? Flow.TopToBottom : Flow.LeftToRight
  property var anchorWindow: null

  property var pinnedApps: []
  property var iconMap: ({})
  property bool seedPinnedApps: false
  readonly property var allToplevels: (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels) ? (ToplevelManager.toplevels.values || []) : []
  readonly property bool niriEnriched: CompositorAdapter.isNiri && NiriService.available
  readonly property var runningToplevels: {
    // Force re-evaluation when NiriService windows change
    void root._niriWindowsVersion;

    var out = [];
    for (var i = 0; i < allToplevels.length; i++) {
      var tl = allToplevels[i];
      if (!tl) continue;
      if (!tl.workspace || tl.workspace.active || tl.activated) out.push(tl);
    }

    // On Niri, sort unpinned toplevels by MRU order
    if (root.niriEnriched && NiriService.mruWindowIds.length > 0) {
      var mru = NiriService.mruWindowIds;
      var niriWindows = NiriService.windows;

      // Build app_id → MRU rank map from NiriService
      var mruRank = {};
      for (var m = 0; m < mru.length; m++) {
        for (var w = 0; w < niriWindows.length; w++) {
          if (niriWindows[w].id === mru[m]) {
            var appId = (niriWindows[w].app_id || "").toLowerCase();
            if (appId && mruRank[appId] === undefined)
              mruRank[appId] = m;
            break;
          }
        }
      }

      out.sort(function(a, b) {
        var aClass = (a.class || a.appId || "").toLowerCase();
        var bClass = (b.class || b.appId || "").toLowerCase();
        var aRank = mruRank[aClass] !== undefined ? mruRank[aClass] : 9999;
        var bRank = mruRank[bClass] !== undefined ? mruRank[bClass] : 9999;
        return aRank - bRank;
      });
    }
    return out;
  }

  // Bump this to force runningToplevels re-evaluation on Niri window changes
  property int _niriWindowsVersion: 0
  Connections {
    target: NiriService
    enabled: root.niriEnriched
    function onWindowsUpdated() { root._niriWindowsVersion++; }
  }
  readonly property string pinnedPath: Quickshell.env("HOME") + "/.local/state/quickshell/pinned_apps.json"
  readonly property var defaultPinnedApps: [
    { name: "Browser", class: "google-chrome", exec: "google-chrome" },
    { name: "Terminal", class: "com.mitchellh.ghostty", exec: "ghostty" }
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

      // Temporary mitigation: do not launch Cursor from Quickshell taskbar.
      var beforeCount = root.pinnedApps.length;
      root.pinnedApps = root.pinnedApps.filter(function(app) {
        var appClass = (app.class || "").toLowerCase();
        var appExec = (app.exec || "").toLowerCase();
        return appClass !== "cursor" && appExec !== "cursor";
      });
      if (root.pinnedApps.length !== beforeCount) {
        root.savePinned();
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
    width: root.vertical ? 16 : 1
    height: root.vertical ? 1 : 16
    color: Colors.border
    visible: {
      for (var i = 0; i < runningToplevels.length; i++) {
        var cls = (runningToplevels[i].class || runningToplevels[i].appId || "");
        var found = false;
        for (var j = 0; j < pinnedApps.length; j++) {
          if (pinnedApps[j].class === cls) { found = true; break; }
        }
        if (!found) return true;
      }
      return false;
    }
  }

  Repeater {
    model: runningToplevels
    delegate: TaskButton {
      // Only show if not already pinned and on active workspace
      property bool alreadyPinned: {
        for (var i = 0; i < pinnedApps.length; i++) {
          if (pinnedApps[i].class === (modelData.class || modelData.appId || "")) return true;
        }
        return false;
      }
      visible: !alreadyPinned
      width: visible ? 32 : 0
      Behavior on width { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
      appClass: modelData.class || modelData.appId || ""
      appExec: modelData.class || modelData.appId || ""
      appName: modelData.title || ""
      isFocused: modelData.activated
      isPinned: false
      toplevelRef: modelData
      iconMap: root.iconMap
      anchorWindow: root.anchorWindow
      onPinToggled: (app) => root.togglePin(app)
    }
  }
}
