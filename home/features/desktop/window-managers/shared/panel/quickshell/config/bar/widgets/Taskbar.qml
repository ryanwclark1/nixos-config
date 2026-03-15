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

      // Build id → window map, then app_id → MRU rank
      var windowMap = {};
      for (var w = 0; w < niriWindows.length; w++)
        windowMap[niriWindows[w].id] = niriWindows[w];
      var mruRank = {};
      for (var m = 0; m < mru.length; m++) {
        var nw = windowMap[mru[m]];
        if (nw) {
          var appId = (nw.app_id || "").toLowerCase();
          if (appId && mruRank[appId] === undefined)
            mruRank[appId] = m;
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

  // Unified model: pinned apps, optional separator sentinel, then unpinned running apps
  ScriptModel {
    id: taskModel
    values: {
      void root._niriWindowsVersion;  // force Niri reactivity
      void root.pinnedApps;           // force pinned reactivity

      var result = [];
      var pinnedClasses = {};

      // Phase 1: Pinned apps (always first)
      for (var i = 0; i < root.pinnedApps.length; i++) {
        var p = root.pinnedApps[i];
        var cls = p.class || "";
        pinnedClasses[cls] = true;

        // Find matching running toplevel
        var matchedTl = null;
        var matchedFocused = false;
        for (var t = 0; t < root.runningToplevels.length; t++) {
          var tl = root.runningToplevels[t];
          if ((tl.class || tl.appId || "") === cls) {
            matchedTl = tl;
            matchedFocused = !!tl.activated;
            break;
          }
        }

        result.push({
          _key: "pinned_" + cls,
          name: p.name || "",
          class: cls,
          exec: p.exec || "",
          isPinned: true,
          isSeparator: false,
          toplevelRef: matchedTl,
          isFocused: matchedFocused
        });
      }

      // Phase 2: Unpinned running apps
      var unpinned = [];
      for (var r = 0; r < root.runningToplevels.length; r++) {
        var rt = root.runningToplevels[r];
        var rtCls = rt.class || rt.appId || "";
        if (!pinnedClasses[rtCls]) {
          unpinned.push({
            _key: "running_" + rtCls,
            name: rt.title || "",
            class: rtCls,
            exec: rtCls,
            isPinned: false,
            isSeparator: false,
            toplevelRef: rt,
            isFocused: !!rt.activated
          });
        }
      }

      // Separator sentinel (only if unpinned apps exist)
      if (unpinned.length > 0) {
        result.push({ _key: "__separator__", isSeparator: true });
        result = result.concat(unpinned);
      }

      return result;
    }
  }

  Repeater {
    model: taskModel
    delegate: Loader {
      required property var modelData
      sourceComponent: modelData.isSeparator ? separatorComponent : taskButtonComponent
    }
  }

  Component {
    id: separatorComponent
    Rectangle {
      width: root.vertical ? 16 : 1
      height: root.vertical ? 1 : 16
      color: Colors.border
    }
  }

  Component {
    id: taskButtonComponent
    TaskButton {
      readonly property var itemData: parent ? parent.modelData : ({})
      appClass: itemData.class || ""
      appExec: itemData.exec || ""
      appName: itemData.name || ""
      isPinned: !!itemData.isPinned
      isFocused: !!itemData.isFocused
      toplevelRef: itemData.toplevelRef || null
      iconMap: root.iconMap
      anchorWindow: root.anchorWindow
      onPinToggled: (app) => root.togglePin(app)
    }
  }
}
