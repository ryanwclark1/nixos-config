pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "."

QtObject {
  id: root

  readonly property string desktopEnv: (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
  readonly property string sessionDesktop: (Quickshell.env("DESKTOP_SESSION") || "").toLowerCase()
  readonly property bool hasHyprSig: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
  readonly property bool hasWaylandDisplay: (Quickshell.env("WAYLAND_DISPLAY") || "") !== ""
  readonly property bool hasNiriSocket: (Quickshell.env("NIRI_SOCKET") || "") !== ""

  readonly property bool desktopSaysHyprland: desktopEnv.indexOf("hyprland") !== -1 || sessionDesktop.indexOf("hyprland") !== -1
  readonly property bool desktopSaysNiri: desktopEnv.indexOf("niri") !== -1 || sessionDesktop.indexOf("niri") !== -1

  readonly property bool isNiri: desktopSaysNiri || (hasNiriSocket && !desktopSaysHyprland)
  readonly property bool isHyprland: desktopSaysHyprland || (hasHyprSig && !desktopSaysNiri)
  readonly property string compositor: isHyprland ? "hyprland" : (isNiri ? "niri" : "unknown")

  // ── Capability flags ────────────────────────────
  // Niri now supports window listing via NiriService event stream IPC.
  readonly property bool supportsWorkspaceListing: isHyprland || isNiri
  readonly property bool supportsWorkspaceFocus: isHyprland || isNiri
  readonly property bool supportsWorkspaceOsd: isHyprland || isNiri
  readonly property bool supportsWindowListing: isHyprland || isNiri
  readonly property bool supportsWindowFocus: isHyprland || isNiri
  readonly property bool supportsWindowClose: isHyprland || isNiri
  readonly property bool supportsWorkspaceRename: isHyprland
  readonly property bool supportsWorkspaceMove: isHyprland || isNiri
  readonly property bool supportsScratchpad: isHyprland
  readonly property bool supportsDisplayConfig: isHyprland
  readonly property bool supportsOverview: isHyprland || isNiri
  readonly property bool supportsHotkeysListing: isHyprland || isNiri
  readonly property bool supportsDispatcherActions: isHyprland
  readonly property bool supportsHyprctlSettings: isHyprland
  readonly property bool supportsKeyboardLayouts: isNiri

  // ── Toplevel abstraction ───────────────────
  readonly property bool hasHyprlandToplevels: isHyprland && typeof Hyprland !== "undefined"
  readonly property bool hasToplevelManager: hasHyprlandToplevels || typeof ToplevelManager !== "undefined"
  readonly property var toplevels: {
    if (hasHyprlandToplevels)
      return Hyprland.toplevels || [];
    if (typeof ToplevelManager !== "undefined")
      return ToplevelManager.toplevels ? (ToplevelManager.toplevels.values || []) : [];
    return [];
  }
  readonly property var activeToplevel: {
    if (hasHyprlandToplevels)
      return Hyprland.activeToplevel || null;
    if (typeof ToplevelManager !== "undefined")
      return ToplevelManager.activeToplevel;
    return null;
  }
  readonly property var activeWindow: {
    if (isNiri)
      return niriActiveWindow;
    if (activeToplevel)
      return activeToplevel;
    return null;
  }
  readonly property string activeWindowSource: {
    if (isNiri && windowHasData(niriActiveWindow))
      return "niri";
    if (hasHyprlandToplevels && activeToplevel)
      return "hyprland-qml";
    if (!hasHyprlandToplevels && activeToplevel)
      return "toplevel-manager";
    return "none";
  }
  readonly property bool activeWindowReady: activeWindowSource !== "none"
  readonly property string activeWindowTitle: {
    return windowTitle(activeWindow);
  }
  readonly property string activeWindowAppId: {
    return windowAppId(activeWindow);
  }
  readonly property string activeWindowDebugSummary: {
    return "compositor=" + compositor
      + " source=" + activeWindowSource
      + " ready=" + activeWindowReady
      + " title=" + windowTitle(activeWindow)
      + " appId=" + windowAppId(activeWindow)
      + " id=" + windowIdentifier(activeWindow);
  }

  // ── Fullscreen detection ──────────────────────
  readonly property bool hasFullscreenWindow: {
    if (isNiri) {
      var wins = NiriService.windows;
      for (var i = 0; i < wins.length; i++) {
        if (wins[i].is_fullscreen) return true;
      }
      return false;
    }
    if (isHyprland) {
      // Check focused workspace's hasFullscreen (reactive via Hyprland QML module)
      if (typeof Hyprland !== "undefined" && Hyprland.workspaces) {
        var wsValues = Hyprland.workspaces.values || Hyprland.workspaces;
        for (var j = 0; j < wsValues.length; j++) {
          if (wsValues[j].focused && wsValues[j].hasFullscreen) return true;
        }
      }
      return false;
    }
    return false;
  }

  // ── MRU window tracking ─────────────────────────
  property var _hyprlandMruIds: []

  readonly property var mruWindowIds: {
    if (isNiri) return NiriService.mruWindowIds;
    if (isHyprland) return _hyprlandMruIds;
    return [];
  }

  onActiveToplevelChanged: {
    if (!isHyprland) return;
    var tl = activeToplevel;
    if (!tl) return;
    var addr = String(tl.address || "");
    if (addr === "") return;
    var newOrder = _hyprlandMruIds.filter(function(id) { return id !== addr; });
    newOrder.unshift(addr);
    _hyprlandMruIds = newOrder;
  }

  // ── Niri reactive state (delegated to NiriService) ──
  // These provide zero-latency access to Niri state without polling.
  readonly property var niriWorkspaces: isNiri ? NiriService.allWorkspaces : []
  readonly property int niriFocusedWorkspaceIndex: isNiri ? NiriService.focusedWorkspaceIndex : -1
  readonly property var niriWindows: isNiri ? NiriService.windows : []
  readonly property var niriActiveWindow: isNiri ? NiriService.activeWindow : null
  readonly property bool niriInOverview: isNiri ? NiriService.inOverview : false
  readonly property var niriOutputs: isNiri ? NiriService.outputs : ({})
  readonly property var niriDisplayScales: isNiri ? NiriService.displayScales : ({})
  readonly property var niriKeyboardLayoutNames: isNiri ? NiriService.keyboardLayoutNames : []
  readonly property int niriKeyboardLayoutIndex: isNiri ? NiriService.currentKeyboardLayoutIndex : 0

  // ── Focused screen name ──────────────────────
  // Returns the output/monitor name where the user is currently focused.
  // Used by IPC to target surfaces to the correct screen.
  readonly property string focusedScreenName: {
    if (isNiri) {
      var aw = NiriService.activeWindow;
      if (aw && aw.workspace_id !== undefined) {
        var ws = NiriService.workspaces[aw.workspace_id];
        if (ws && ws.output) return ws.output;
      }
      // Fallback: first output
      var outputKeys = Object.keys(NiriService.outputs || {});
      return outputKeys.length > 0 ? outputKeys[0] : "";
    }
    if (isHyprland && typeof Hyprland !== "undefined" && Hyprland.focusedMonitor) {
      return Hyprland.focusedMonitor.name || "";
    }
    return "";
  }

  Component.onCompleted: {
    if (hasHyprlandToplevels && typeof Hyprland.refreshToplevels === "function")
      Hyprland.refreshToplevels();
    // Seed MRU list from existing toplevels so AltTab works immediately
    if (isHyprland)
      Qt.callLater(_seedHyprlandMru);
  }

  function _seedHyprlandMru() {
    if (_hyprlandMruIds.length > 0) return;
    var tls = toplevels || [];
    var ids = [];
    var activeAddr = activeToplevel ? String(activeToplevel.address || "") : "";
    if (activeAddr !== "")
      ids.push(activeAddr);
    for (var i = 0; i < tls.length; i++) {
      var addr = String(tls[i].address || "");
      if (addr !== "" && addr !== activeAddr)
        ids.push(addr);
    }
    if (ids.length > 0)
      _hyprlandMruIds = ids;
  }

  function windowTitle(windowRef) {
    return windowRef ? String(windowRef.title || "") : "";
  }

  function windowHasData(windowRef) {
    if (!windowRef)
      return false;
    return windowIdentifier(windowRef) !== ""
      || windowTitle(windowRef) !== ""
      || windowAppId(windowRef) !== "";
  }

  function windowIdentifier(windowRef) {
    if (!windowRef)
      return "";
    return String(windowRef.address || windowRef.id || "");
  }

  function windowAppId(windowRef) {
    if (!windowRef)
      return "";
    return String(windowRef.app_id || windowRef.appId || windowRef.class || "");
  }

  function sameWindow(left, right) {
    if (!left || !right)
      return false;
    if (left === right)
      return true;

    var leftId = windowIdentifier(left);
    var rightId = windowIdentifier(right);
    if (leftId && rightId)
      return leftId === rightId;

    var leftTitle = windowTitle(left);
    var rightTitle = windowTitle(right);
    var leftApp = windowAppId(left);
    var rightApp = windowAppId(right);
    return leftTitle !== "" && leftApp !== "" && leftTitle === rightTitle && leftApp === rightApp;
  }

  function workspaceNameById(wsId) {
    if (wsId === undefined) return "";
    if (isHyprland && typeof Hyprland !== "undefined" && Hyprland.workspaces) {
      var wsValues = Hyprland.workspaces.values || Hyprland.workspaces;
      for (var i = 0; i < wsValues.length; i++) {
        if (wsValues[i].id === wsId)
          return String(wsValues[i].name || wsId);
      }
    }
    if (isNiri && NiriService.workspaces) {
      var ws = NiriService.workspaces[wsId];
      if (ws) return String(ws.name || ws.idx || wsId);
    }
    return String(wsId);
  }

  function matchesCompositorTag(tag) {
    var needs = String(tag || "any").toLowerCase();
    if (needs === "" || needs === "any") return true;
    if (needs === "hyprland") return isHyprland;
    if (needs === "niri") return isNiri;
    return false;
  }

  function notifyUnsupported(actionName) {
    Quickshell.execDetached([
      "notify-send",
      "Unsupported action",
      actionName + " is not supported on current compositor (" + compositor + ")."
    ]);
  }

  // ═══════════════════════════════════════════════
  //  Command factories (for polling-based consumers)
  // ═══════════════════════════════════════════════

  function hotkeysCommand() {
    if (isHyprland) return ["hyprctl", "binds", "-j"];
    return ["sh", "-c", "echo '[]'"];
  }

  function monitorListCommand() {
    if (supportsDisplayConfig) return ["hyprctl", "monitors", "-j"];
    return ["sh", "-c", "echo '[]'"];
  }

  function monitorKeywordCommand(spec) {
    if (!supportsDisplayConfig) return ["sh", "-c", "true"];
    return ["hyprctl", "keyword", "monitor", String(spec || "")];
  }

  function hyprlandSettingsSnapshotCommand() {
    if (!supportsHyprctlSettings) return ["sh", "-c", "printf '{}'"];
    return [
      "sh",
      "-c",
      "hyprctl getoption general:gaps_out -j 2>/dev/null | tr '\\n' ' '; "
      + "printf '\\n'; "
      + "hyprctl getoption general:gaps_in -j 2>/dev/null | tr '\\n' ' '; "
      + "printf '\\n'; "
      + "hyprctl getoption decoration:active_opacity -j 2>/dev/null | tr '\\n' ' '; "
      + "printf '\\n'; "
      + "hyprctl getoption general:layout -j 2>/dev/null | tr '\\n' ' '"
    ];
  }

  function screenshareProbeSnippet() {
    if (isHyprland) {
      return "share=$(hyprctl clients -j 2>/dev/null | jq '[.[] | select(.class | ascii_downcase | test(\"screencopy|xdg-desktop-portal\"))] | length' 2>/dev/null || echo 0); "
        + "share2=$(pgrep -c -f 'xdg-desktop-portal-hyprland\\|pipewire-screenshare\\|obs.*screen' 2>/dev/null || echo 0); "
        + "if [ \"$share\" -gt 0 ] || [ \"$share2\" -gt 0 ]; then share_out=1; else share_out=0; fi; ";
    }
    if (isNiri) {
      return "share=$(pgrep -c -f 'xdg-desktop-portal\\|pipewire-screenshare\\|obs.*screen\\|grim\\|slurp' 2>/dev/null || echo 0); "
        + "if [ \"$share\" -gt 0 ]; then share_out=1; else share_out=0; fi; ";
    }
    return "share=$(pgrep -c -f 'xdg-desktop-portal\\|pipewire-screenshare\\|obs.*screen' 2>/dev/null || echo 0); "
      + "if [ \"$share\" -gt 0 ]; then share_out=1; else share_out=0; fi; ";
  }

  function wallpaperCompositorFallbackSnippet(wallpaperArgQuoted) {
    if (isHyprland) {
      return "if [ \"$ok\" -eq 0 ] && command -v hyprctl >/dev/null 2>&1; then "
        + "  if hyprctl hyprpaper wallpaper " + String(wallpaperArgQuoted || "''") + "; then "
        + "    echo BACKEND:hyprpaper; ok=1; "
        + "  fi; "
        + "fi; ";
    }
    return "";
  }

  // ═══════════════════════════════════════════════
  //  Actions — compositor-agnostic
  // ═══════════════════════════════════════════════

  function lockCommand() {
    return ["os-lock-screen"];
  }

  function logout() {
    if (isHyprland) {
      Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
      return true;
    }
    if (isNiri)
      return NiriService.quit();

    Quickshell.execDetached(["os-power", "logout"]);
    return true;
  }

  function focusWorkspace(id) {
    var ws = String(id);
    if (!supportsWorkspaceFocus) {
      notifyUnsupported("Focus workspace");
      return;
    }
    if (isHyprland) {
      Quickshell.execDetached(["hyprctl", "dispatch", "workspace", ws]);
      return;
    }
    if (isNiri) {
      if (ws === "e-1") {
        NiriService.focusWorkspaceRelative(-1);
        return;
      }
      if (ws === "e+1") {
        NiriService.focusWorkspaceRelative(1);
        return;
      }
      // Use NiriService IPC for instant response instead of spawning a subprocess.
      NiriService.focusWorkspace(parseInt(ws, 10));
      return;
    }
  }

  function focusWindow(windowId) {
    if (!supportsWindowFocus) {
      notifyUnsupported("Focus window");
      return;
    }
    if (isHyprland) {
      dispatchAction("focuswindow", "address:" + String(windowId), "Focus window");
      return;
    }
    if (isNiri) {
      NiriService.focusWindow(windowId);
      return;
    }
  }

  function closeWindow(windowId) {
    if (!supportsWindowClose) {
      notifyUnsupported("Close window");
      return;
    }
    if (isHyprland) {
      dispatchAction("closewindow", "address:" + String(windowId), "Close window");
      return;
    }
    if (isNiri) {
      NiriService.closeWindow(windowId);
      return;
    }
  }

  function moveWindowToWorkspace(addressOrId, workspaceId) {
    if (!supportsWorkspaceMove) {
      notifyUnsupported("Move window to workspace");
      return;
    }
    if (isHyprland) {
      dispatchAction("movetoworkspace", String(workspaceId) + ",address:" + String(addressOrId), "Move window to workspace");
      return;
    }
    if (isNiri) {
      NiriService.moveWindowToWorkspace(addressOrId, parseInt(String(workspaceId), 10), false);
      return;
    }
  }

  function renameWorkspace(workspaceId, newName) {
    if (!supportsWorkspaceRename) {
      notifyUnsupported("Rename workspace");
      return;
    }
    if (isHyprland) {
      dispatchAction("renameworkspace", String(workspaceId) + " " + String(newName), "Rename workspace");
      return;
    }
  }

  function toggleOverview() {
    if (!supportsOverview) {
      notifyUnsupported("Toggle overview");
      return;
    }
    if (isHyprland) {
      dispatchAction("overview:toggle", "", "Toggle overview");
      return;
    }
    if (isNiri) {
      NiriService.toggleOverview();
      return;
    }
  }

  function dispatchAction(action, arg, unsupportedName) {
    if (!supportsDispatcherActions) {
      // Allow Niri-specific actions through NiriService
      if (isNiri) {
        Logger.w("CompositorAdapter", "dispatchAction not supported on Niri. Use NiriService directly for:", action);
      } else {
        notifyUnsupported(unsupportedName || ("Dispatch " + String(action || "")));
      }
      return;
    }
    var args = ["hyprctl", "dispatch", String(action || "")];
    if (arg !== undefined && arg !== null && String(arg) !== "")
      args.push(String(arg));
    Quickshell.execDetached(args);
  }

  function setHyprKeyword(key, value, unsupportedName) {
    if (!supportsHyprctlSettings) {
      notifyUnsupported(unsupportedName || ("Set " + String(key || "")));
      return;
    }
    Quickshell.execDetached(["hyprctl", "keyword", String(key || ""), String(value || "")]);
  }

  // ═══════════════════════════════════════════════
  //  Niri-specific keyboard layout
  // ═══════════════════════════════════════════════

  function getCurrentKeyboardLayoutName() {
    if (isNiri) return NiriService.getCurrentKeyboardLayoutName();
    return "";
  }

  function switchKeyboardLayout() {
    if (isNiri) { NiriService.switchLayout(); return; }
    notifyUnsupported("Switch keyboard layout");
  }
}
