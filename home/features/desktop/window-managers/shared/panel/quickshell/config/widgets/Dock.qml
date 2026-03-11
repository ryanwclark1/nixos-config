import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"

Scope {
  id: root

  // App model: merged pinned + running toplevels
  property var dockApps: []
  // Desktop entry ID cache for heuristic resolution
  property var _entryCache: ({})

  function normalizeAppId(id) {
    if (!id) return "";
    return id.toLowerCase().replace(/\.desktop$/, "");
  }

  function resolveDesktopEntryId(appId) {
    if (!appId) return appId;
    if (_entryCache.hasOwnProperty(appId)) return _entryCache[appId];
    try {
      if (typeof DesktopEntries !== 'undefined' && DesktopEntries.heuristicLookup) {
        var entry = DesktopEntries.heuristicLookup(appId);
        if (entry && entry.id) {
          _entryCache[appId] = entry.id;
          return entry.id;
        }
      }
    } catch (e) {}
    _entryCache[appId] = appId;
    return appId;
  }

  function isAppPinned(appId) {
    var norm = normalizeAppId(appId);
    for (var i = 0; i < Config.dockPinnedApps.length; i++) {
      if (normalizeAppId(Config.dockPinnedApps[i]) === norm) return true;
    }
    return false;
  }

  function getAppName(appId) {
    try {
      if (typeof DesktopEntries !== 'undefined') {
        var entry = DesktopEntries.heuristicLookup
          ? DesktopEntries.heuristicLookup(appId)
          : (DesktopEntries.byId ? DesktopEntries.byId(appId) : null);
        if (entry && entry.name) return entry.name;
      }
    } catch (e) {}
    return appId || "";
  }

  function getAppIcon(appId) {
    try {
      if (typeof DesktopEntries !== 'undefined') {
        var entry = DesktopEntries.heuristicLookup
          ? DesktopEntries.heuristicLookup(appId)
          : (DesktopEntries.byId ? DesktopEntries.byId(appId) : null);
        if (entry && entry.icon) return Config.resolveIconSource(entry.icon);
      }
    } catch (e) {}
    return Config.resolveIconSource(appId);
  }

  function getAppActions(appId) {
    try {
      if (typeof DesktopEntries !== 'undefined') {
        var entry = DesktopEntries.heuristicLookup
          ? DesktopEntries.heuristicLookup(appId)
          : (DesktopEntries.byId ? DesktopEntries.byId(appId) : null);
        if (entry && entry.actions) {
          var result = [];
          for (var i = 0; i < entry.actions.length; i++) {
            var a = entry.actions[i];
            if (a && a.name) result.push({ name: a.name, action: a });
          }
          return result;
        }
      }
    } catch (e) {}
    return [];
  }

  function togglePin(appId) {
    var pinned = Config.dockPinnedApps.slice();
    var norm = normalizeAppId(appId);
    var idx = -1;
    for (var i = 0; i < pinned.length; i++) {
      if (normalizeAppId(pinned[i]) === norm) { idx = i; break; }
    }
    if (idx >= 0) pinned.splice(idx, 1);
    else pinned.push(appId);
    Config.dockPinnedApps = pinned;
    updateDockApps();
  }

  function updateDockApps() {
    var toplevels = [];
    if (typeof ToplevelManager !== 'undefined' && ToplevelManager.toplevels) {
      toplevels = ToplevelManager.toplevels.values || [];
    }
    var pinned = Config.dockPinnedApps || [];
    var combined = [];
    var processedIds = {};

    // First: pinned apps (in order)
    for (var i = 0; i < pinned.length; i++) {
      var pinnedId = pinned[i];
      var normPinned = normalizeAppId(pinnedId);
      var matchingToplevels = [];

      for (var j = 0; j < toplevels.length; j++) {
        var tl = toplevels[j];
        if (!tl || !tl.appId) continue;
        var normTl = normalizeAppId(tl.appId);
        var resolved = normalizeAppId(resolveDesktopEntryId(tl.appId));
        if (normTl === normPinned || resolved === normPinned) {
          matchingToplevels.push(tl);
        }
      }

      combined.push({
        appId: pinnedId,
        pinned: true,
        toplevels: matchingToplevels,
        name: matchingToplevels.length > 0 ? matchingToplevels[0].title : getAppName(pinnedId)
      });
      processedIds[normPinned] = true;
    }

    // Second: running but not pinned
    var grouped = {};
    for (var k = 0; k < toplevels.length; k++) {
      var tl2 = toplevels[k];
      if (!tl2 || !tl2.appId) continue;
      var norm2 = normalizeAppId(tl2.appId);
      var resolved2 = normalizeAppId(resolveDesktopEntryId(tl2.appId));
      if (processedIds[norm2] || processedIds[resolved2]) continue;

      var groupKey = Config.dockGroupApps ? norm2 : (norm2 + "_" + k);
      if (!grouped[groupKey]) {
        grouped[groupKey] = {
          appId: tl2.appId,
          pinned: false,
          toplevels: [],
          name: tl2.title
        };
      }
      grouped[groupKey].toplevels.push(tl2);
    }

    var keys = Object.keys(grouped);
    for (var m = 0; m < keys.length; m++) {
      combined.push(grouped[keys[m]]);
    }

    dockApps = combined;
  }

  // Rebuild on toplevel changes
  Connections {
    target: (typeof ToplevelManager !== 'undefined' && ToplevelManager.toplevels) ? ToplevelManager.toplevels : null
    function onValuesChanged() {
      root._entryCache = {};
      root.updateDockApps();
    }
  }

  // Rebuild on pinned apps change
  Connections {
    target: Config
    function onDockPinnedAppsChanged() { root.updateDockApps(); }
    function onDockGroupAppsChanged() { root.updateDockApps(); }
  }

  Component.onCompleted: Qt.callLater(updateDockApps)

  // Per-screen dock
  Variants {
    model: Quickshell.screens

    delegate: Component {
      Item {
        id: screenDelegate
        required property ShellScreen modelData

        readonly property bool isBottom: Config.dockPosition === "bottom"
        readonly property bool autoHide: Config.dockAutoHide
        property bool hidden: autoHide
        property bool dockHovered: false
        property bool peekHovered: false

        Timer {
          id: showTimer
          interval: 100
          onTriggered: screenDelegate.hidden = false
        }

        Timer {
          id: hideTimer
          interval: 500
          onTriggered: {
            if (!screenDelegate.dockHovered && !screenDelegate.peekHovered)
              screenDelegate.hidden = true;
          }
        }

        // Window 1: Peek (1px invisible hover trap at dock edge)
        Loader {
          active: Config.dockEnabled && screenDelegate.autoHide && screenDelegate.modelData
          sourceComponent: PanelWindow {
            screen: screenDelegate.modelData
            anchors.bottom: screenDelegate.isBottom
            anchors.top: !screenDelegate.isBottom
            focusable: false
            color: "transparent"
            implicitWidth: 200
            implicitHeight: 1
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-dock-peek"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            mask: Region {}

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: {
                screenDelegate.peekHovered = true;
                if (screenDelegate.hidden) showTimer.start();
              }
              onExited: {
                screenDelegate.peekHovered = false;
                showTimer.stop();
                if (!screenDelegate.dockHovered) hideTimer.restart();
              }
            }
          }
        }

        // Window 2: Indicator bar (thin colored line when hidden)
        Loader {
          active: Config.dockEnabled && screenDelegate.autoHide && screenDelegate.modelData
          sourceComponent: PanelWindow {
            screen: screenDelegate.modelData
            anchors.bottom: screenDelegate.isBottom
            anchors.top: !screenDelegate.isBottom
            margins.bottom: screenDelegate.isBottom ? 4 : 0
            margins.top: !screenDelegate.isBottom ? 4 : 0
            focusable: false
            color: "transparent"
            implicitWidth: 60
            implicitHeight: 3
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-dock-indicator"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            mask: Region { item: indicatorRect }

            Rectangle {
              id: indicatorRect
              anchors.centerIn: parent
              width: parent.width
              height: 3
              radius: 2
              color: Colors.primary
              opacity: screenDelegate.hidden ? 0.6 : 0.0
              Behavior on opacity { NumberAnimation { duration: 200 } }
            }
          }
        }

        // Window 3: Main dock
        Loader {
          active: Config.dockEnabled && screenDelegate.modelData && root.dockApps.length > 0
          sourceComponent: PanelWindow {
            id: dockWindow
            screen: screenDelegate.modelData
            anchors.bottom: screenDelegate.isBottom
            anchors.top: !screenDelegate.isBottom
            margins.bottom: screenDelegate.isBottom ? 12 : 0
            margins.top: !screenDelegate.isBottom ? 12 : 0
            focusable: false
            color: "transparent"
            implicitWidth: dockContent.implicitWidth + 24
            implicitHeight: 80

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-dock"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            mask: Region { item: dockBg }

            // Show/hide animations
            opacity: screenDelegate.hidden ? 0 : 1
            property real yOffset: screenDelegate.hidden ? (screenDelegate.isBottom ? 20 : -20) : 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on yOffset { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            transform: Translate { y: dockWindow.yOffset }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.NoButton
              onEntered: {
                screenDelegate.dockHovered = true;
                hideTimer.stop();
              }
              onExited: {
                screenDelegate.dockHovered = false;
                if (screenDelegate.autoHide && !screenDelegate.peekHovered) hideTimer.restart();
              }
            }

            DockContent {
              id: dockContent
              anchors.centerIn: parent
              dockApps: root.dockApps
              dockRoot: root
              anchorWindow: dockWindow
            }
          }
        }
      }
    }
  }
}
