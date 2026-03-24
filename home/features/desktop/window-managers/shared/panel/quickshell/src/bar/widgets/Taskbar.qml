import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

Item {
  id: root
  property int spacing: Appearance.spacingS
  property bool vertical: false
  property var anchorWindow: null
  property int buttonSize: 32
  property int iconSize: 20
  property bool showRunningIndicator: true
  property bool showSeparator: true
  property int maxUnpinned: 0

  property var pinnedApps: []
  readonly property var iconMap: IconCatalogService.iconMap
  property bool seedPinnedApps: false
  readonly property var allToplevels: CompositorAdapter.toplevels
  readonly property bool niriEnriched: CompositorAdapter.isNiri && NiriService.available
  readonly property int taskCount: {
    var tasks = taskModel.values;
    return tasks ? tasks.length : 0;
  }
  readonly property real estimatedSpan: taskCount > 0
    ? (taskCount * buttonSize) + (Math.max(0, taskCount - 1) * spacing)
    : 0
  readonly property real contentWidth: {
    var item = layoutLoader.item;
    return item ? (item.implicitWidth || item.width || 0) : 0;
  }
  readonly property real contentHeight: {
    var item = layoutLoader.item;
    return item ? (item.implicitHeight || item.height || 0) : 0;
  }
  visible: taskCount > 0
  width: visible ? (vertical ? Math.max(buttonSize, contentWidth) : Math.max(estimatedSpan, contentWidth)) : 0
  height: visible ? (vertical ? Math.max(estimatedSpan, contentHeight) : Math.max(buttonSize, contentHeight)) : 0
  readonly property var runningToplevels: {
    // Force re-evaluation when NiriService windows change
    var _niriVer = root._niriWindowsVersion;

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
          var appId = CompositorAdapter.windowAppId(nw).toLowerCase();
          if (appId && mruRank[appId] === undefined)
            mruRank[appId] = m;
        }
      }

      out.sort(function(a, b) {
        var aClass = CompositorAdapter.windowAppId(a).toLowerCase();
        var bClass = CompositorAdapter.windowAppId(b).toLowerCase();
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
      } catch (e) {
        Logger.w("Taskbar", "pinned apps JSON parse failed, resetting", e);
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

  function pinnedAppId(app) {
    return String((app && (app.appId || app.class)) || "");
  }

  function togglePin(app) {
    var targetAppId = pinnedAppId(app);
    var found = -1;
    for (var i = 0; i < pinnedApps.length; i++) {
      if (pinnedAppId(pinnedApps[i]) === targetAppId) { found = i; break; }
    }
    if (found !== -1) pinnedApps.splice(found, 1);
    else pinnedApps.push({
      name: app.title || targetAppId,
      appId: targetAppId,
      class: targetAppId,
      exec: app.exec || targetAppId
    });
    pinnedApps = pinnedApps; // Trigger update
    savePinned();
  }

  // Unified model: pinned apps, optional separator sentinel, then unpinned running apps
  ScriptModel {
    id: taskModel
    values: {
      var _niriVer = root._niriWindowsVersion;  // force Niri reactivity
      var _pinned = root.pinnedApps;            // force pinned reactivity

      var result = [];
      var pinnedClasses = {};

      // Pre-build appId→toplevel map for O(1) pinned lookups
      var tlByAppId = {};
      for (var t = 0; t < root.runningToplevels.length; t++) {
        var tl = root.runningToplevels[t];
        var tlAppId = CompositorAdapter.windowAppId(tl);
        if (tlAppId && !tlByAppId[tlAppId]) tlByAppId[tlAppId] = tl;
      }

      // Phase 1: Pinned apps (always first)
      for (var i = 0; i < root.pinnedApps.length; i++) {
        var p = root.pinnedApps[i];
        var appId = root.pinnedAppId(p);
        pinnedClasses[appId] = true;

        // O(1) lookup from pre-built map
        var matchedTl = tlByAppId[appId] || null;
        var matchedFocused = matchedTl ? !!matchedTl.activated : false;

        result.push({
          _key: "pinned_" + appId,
          name: p.name || "",
          appId: appId,
          exec: p.exec || appId,
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
        var rtAppId = CompositorAdapter.windowAppId(rt);
        if (!pinnedClasses[rtAppId]) {
          unpinned.push({
            _key: "running_" + rtAppId,
            name: rt.title || "",
            appId: rtAppId,
            exec: rtAppId,
            isPinned: false,
            isSeparator: false,
            toplevelRef: rt,
            isFocused: !!rt.activated
          });
        }
      }

      // Separator sentinel (only if unpinned apps exist)
      var limitedUnpinned = unpinned;
      if (root.maxUnpinned > 0)
        limitedUnpinned = unpinned.slice(0, root.maxUnpinned);

      if (root.showSeparator && limitedUnpinned.length > 0) {
        result.push({ _key: "__separator__", isSeparator: true });
      }
      result = result.concat(limitedUnpinned);

      return result;
    }
  }

  Loader {
    id: layoutLoader
    x: 0
    y: 0
    sourceComponent: root.vertical ? verticalLayoutComponent : horizontalLayoutComponent
  }

  Component {
    id: horizontalLayoutComponent
    Row {
      spacing: root.spacing

      Repeater {
        model: taskModel
        delegate: Loader {
          required property var modelData
          sourceComponent: modelData.isSeparator ? separatorComponent : taskButtonComponent
        }
      }
    }
  }

  Component {
    id: verticalLayoutComponent
    Column {
      spacing: root.spacing

      Repeater {
        model: taskModel
        delegate: Loader {
          required property var modelData
          sourceComponent: modelData.isSeparator ? separatorComponent : taskButtonComponent
        }
      }
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
      appId: itemData.appId || ""
      appExec: itemData.exec || ""
      appName: itemData.name || ""
      isPinned: !!itemData.isPinned
      isFocused: !!itemData.isFocused
      toplevelRef: itemData.toplevelRef || null
      iconMap: root.iconMap
      anchorWindow: root.anchorWindow
      buttonSize: root.buttonSize
      iconSize: root.iconSize
      showRunningIndicator: root.showRunningIndicator
      onPinToggled: (app) => root.togglePin(app)
    }
  }
}
