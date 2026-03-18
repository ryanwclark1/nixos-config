import QtQuick
import Quickshell
import Quickshell.Wayland
import "."
import "../../services"
import "../../shared"

Scope {
  id: root

  function normalizeAppId(id) {
    if (!id) return "";
    return id.toLowerCase().replace(/\.desktop$/, "");
  }

  function _lookupEntry(appId) {
    if (!appId) return null;
    try {
      if (typeof DesktopEntries !== 'undefined') {
        return DesktopEntries.heuristicLookup
          ? DesktopEntries.heuristicLookup(appId)
          : (DesktopEntries.byId ? DesktopEntries.byId(appId) : null);
      }
    } catch (e) {}
    return null;
  }

  function getAppName(appId) {
    var entry = _lookupEntry(appId);
    return (entry && entry.name) ? entry.name : (appId || "");
  }

  function getAppIcon(appId) {
    var entry = _lookupEntry(appId);
    return (entry && entry.icon) ? Config.resolveIconSource(entry.icon) : Config.resolveIconSource(appId);
  }

  function getAppActions(appId) {
    var entry = _lookupEntry(appId);
    if (!entry || !entry.actions) return [];
    var result = [];
    for (var i = 0; i < entry.actions.length; i++) {
      var a = entry.actions[i];
      if (a && a.name) result.push({ name: a.name, action: a });
    }
    return result;
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
  }

  // Resolve desktop entry id with local cache (pure, no side effects)
  function resolveDesktopEntryIdCached(appId, cache) {
    if (!appId) return appId;
    if (cache.hasOwnProperty(appId)) return cache[appId];
    var entry = _lookupEntry(appId);
    var resolved = (entry && entry.id) ? entry.id : appId;
    cache[appId] = resolved;
    return resolved;
  }

  ScriptModel {
    id: dockModel
    values: {
      // These dependencies auto-trigger re-evaluation
      var toplevels = CompositorAdapter.toplevels;
      var pinned = Config.dockPinnedApps || [];
      var groupApps = Config.dockGroupApps;  // force dep

      // Local cache — no property writes, no binding loop
      var entryCache = {};

      var combined = [];
      var processedIds = {};

      for (var i = 0; i < pinned.length; i++) {
        var pinnedId = pinned[i];
        var normPinned = root.normalizeAppId(pinnedId);
        var matchingToplevels = [];

        for (var j = 0; j < toplevels.length; j++) {
          var tl = toplevels[j];
          var tlAppId = CompositorAdapter.windowAppId(tl);
          if (!tl || !tlAppId) continue;
          var normTl = root.normalizeAppId(tlAppId);
          var resolved = root.normalizeAppId(root.resolveDesktopEntryIdCached(tlAppId, entryCache));
          if (normTl === normPinned || resolved === normPinned)
            matchingToplevels.push(tl);
        }

        combined.push({
          appId: pinnedId,
          pinned: true,
          toplevels: matchingToplevels,
          name: matchingToplevels.length > 0 ? matchingToplevels[0].title : root.getAppName(pinnedId)
        });
        processedIds[normPinned] = true;
      }

      var grouped = {};
      for (var k = 0; k < toplevels.length; k++) {
        var tl2 = toplevels[k];
        var tl2AppId = CompositorAdapter.windowAppId(tl2);
        if (!tl2 || !tl2AppId) continue;
        var norm2 = root.normalizeAppId(tl2AppId);
        var resolved2 = root.normalizeAppId(root.resolveDesktopEntryIdCached(tl2AppId, entryCache));
        if (processedIds[norm2] || processedIds[resolved2]) continue;

        var groupKey = groupApps ? norm2 : (norm2 + "_" + k);
        if (!grouped[groupKey]) {
          grouped[groupKey] = {
            appId: tl2AppId,
            pinned: false,
            toplevels: [],
            name: tl2.title
          };
        }
        grouped[groupKey].toplevels.push(tl2);
      }

      var keys = Object.keys(grouped);
      for (var m = 0; m < keys.length; m++)
        combined.push(grouped[keys[m]]);

      return combined;
    }
  }

  readonly property alias dockApps: dockModel.values

  Variants {
    model: Quickshell.screens

    delegate: Component {
      Item {
        id: screenDelegate
        required property ShellScreen modelData

        readonly property string dockPosition: Config.dockPosition
        readonly property bool isBottom: dockPosition === "bottom"
        readonly property bool isTop: dockPosition === "top"
        readonly property bool isLeft: dockPosition === "left"
        readonly property bool isRight: dockPosition === "right"
        readonly property bool vertical: isLeft || isRight
        readonly property bool autoHide: Config.dockAutoHide
        readonly property bool dockAllowed: Config.dockEnabled && !Config.dockConflictsOnScreen(screenDelegate.modelData)
        property bool hidden: autoHide
        property bool dockHovered: false
        property bool peekHovered: false

        readonly property int _dockShowDelayMs: 100
        readonly property int _dockHideDelayMs: 500

        Timer {
          id: showTimer
          interval: screenDelegate._dockShowDelayMs
          onTriggered: screenDelegate.hidden = false
        }

        Timer {
          id: hideTimer
          interval: screenDelegate._dockHideDelayMs
          onTriggered: {
            if (!screenDelegate.dockHovered && !screenDelegate.peekHovered)
              screenDelegate.hidden = true;
          }
        }

        Loader {
          active: screenDelegate.dockAllowed && screenDelegate.autoHide && screenDelegate.modelData
          sourceComponent: PanelWindow {
            screen: screenDelegate.modelData
            anchors.bottom: screenDelegate.isBottom
            anchors.top: screenDelegate.isTop
            anchors.left: screenDelegate.isLeft
            anchors.right: screenDelegate.isRight
            focusable: false
            color: "transparent"
            implicitWidth: screenDelegate.vertical ? 1 : 200
            implicitHeight: screenDelegate.vertical ? 200 : 1
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

        Loader {
          active: screenDelegate.dockAllowed && screenDelegate.autoHide && screenDelegate.modelData
          sourceComponent: PanelWindow {
            screen: screenDelegate.modelData
            anchors.bottom: screenDelegate.isBottom
            anchors.top: screenDelegate.isTop
            anchors.left: screenDelegate.isLeft
            anchors.right: screenDelegate.isRight
            margins.bottom: screenDelegate.isBottom ? 4 : 0
            margins.top: screenDelegate.isTop ? 4 : 0
            margins.left: screenDelegate.isLeft ? 4 : 0
            margins.right: screenDelegate.isRight ? 4 : 0
            focusable: false
            color: "transparent"
            implicitWidth: screenDelegate.vertical ? 3 : 60
            implicitHeight: screenDelegate.vertical ? 60 : 3
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-dock-indicator"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            mask: Region { item: indicatorRect }

            Rectangle {
              id: indicatorRect
              anchors.centerIn: parent
              width: screenDelegate.vertical ? 3 : parent.width
              height: screenDelegate.vertical ? parent.height : 3
              radius: Colors.radiusMicro
              color: Colors.primary
              opacity: screenDelegate.hidden ? 0.6 : 0.0
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
            }
          }
        }

        Loader {
          active: screenDelegate.dockAllowed && screenDelegate.modelData && root.dockApps.length > 0
          sourceComponent: PanelWindow {
            id: dockWindow
            screen: screenDelegate.modelData
            property string tooltipEdge: screenDelegate.dockPosition
            anchors.bottom: screenDelegate.isBottom
            anchors.top: screenDelegate.isTop
            anchors.left: screenDelegate.isLeft
            anchors.right: screenDelegate.isRight
            margins.bottom: screenDelegate.isBottom ? 12 : 0
            margins.top: screenDelegate.isTop ? 12 : 0
            margins.left: screenDelegate.isLeft ? 12 : 0
            margins.right: screenDelegate.isRight ? 12 : 0
            focusable: false
            color: "transparent"
            implicitWidth: Math.max(1, dockContent.implicitWidth + Colors.paddingLarge)
            implicitHeight: Math.max(1, dockContent.implicitHeight + Colors.paddingLarge)

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-dock"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            mask: Region { item: dockContent.background }

            Item {
              id: dockAnimWrapper
              anchors.fill: parent

              opacity: screenDelegate.hidden ? 0 : 1
              visible: opacity > 0
              property real xOffset: screenDelegate.hidden ? (screenDelegate.isLeft ? -20 : (screenDelegate.isRight ? 20 : 0)) : 0
              property real yOffset: screenDelegate.hidden ? (screenDelegate.isBottom ? 20 : (screenDelegate.isTop ? -20 : 0)) : 0
              Behavior on opacity { Anim {} }
              Behavior on xOffset { Anim {} }
              Behavior on yOffset { Anim {} }
              transform: Translate { x: dockAnimWrapper.xOffset; y: dockAnimWrapper.yOffset }

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
                vertical: screenDelegate.vertical
              }
            }
          }
        }
      }
    }
  }
}
