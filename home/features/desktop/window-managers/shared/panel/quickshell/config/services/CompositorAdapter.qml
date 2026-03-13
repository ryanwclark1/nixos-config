import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  readonly property string desktopEnv: (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
  readonly property string sessionDesktop: (Quickshell.env("DESKTOP_SESSION") || "").toLowerCase()
  readonly property bool hasHyprSig: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
  readonly property bool hasNiriSocket: (Quickshell.env("NIRI_SOCKET") || "") !== ""

  readonly property bool isHyprland: hasHyprSig || desktopEnv.indexOf("hyprland") !== -1 || sessionDesktop.indexOf("hyprland") !== -1
  readonly property bool isNiri: hasNiriSocket || desktopEnv.indexOf("niri") !== -1 || sessionDesktop.indexOf("niri") !== -1
  readonly property string compositor: isHyprland ? "hyprland" : (isNiri ? "niri" : "unknown")

  readonly property bool supportsWorkspaceListing: isHyprland || isNiri
  readonly property bool supportsWorkspaceFocus: isHyprland || isNiri
  readonly property bool supportsWorkspaceOsd: isHyprland || isNiri
  readonly property bool supportsWindowListing: isHyprland
  readonly property bool supportsWorkspaceRename: isHyprland
  readonly property bool supportsWorkspaceMove: isHyprland
  readonly property bool supportsWorkspaceCloseWindows: isHyprland
  readonly property bool supportsScratchpad: isHyprland
  readonly property bool supportsDisplayConfig: isHyprland
  readonly property bool supportsOverview: isHyprland
  readonly property bool supportsHotkeysListing: isHyprland
  readonly property bool supportsDispatcherActions: isHyprland
  readonly property bool supportsHyprctlSettings: isHyprland

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

  function workspaceListCommand() {
    if (isHyprland) {
      return [
        "sh",
        "-c",
        "hyprctl workspaces -j 2>/dev/null; printf '\\n'; hyprctl activeworkspace -j 2>/dev/null"
      ];
    }
    if (isNiri) return ["niri", "msg", "-j", "workspaces"];
    return ["sh", "-c", "echo '[]'"];
  }

  function activeWorkspaceNameCommand() {
    if (isHyprland)
      return ["sh", "-c", "hyprctl activeworkspace -j 2>/dev/null | jq -r '.name // empty'"];
    if (isNiri) {
      return [
        "sh",
        "-c",
        "niri msg -j workspaces 2>/dev/null | jq -r '(if type == \"array\" then . else (.workspaces // []) end)[] | select(.is_active == true or .active == true or .is_focused == true or .focused == true) | (.name // .idx // .id // .index // empty)' | head -n1"
      ];
    }
    return ["sh", "-c", "echo ''"];
  }

  function lockCommand() {
    return ["os-lock-screen"];
  }

  function logoutCommand() {
    if (isHyprland) return ["hyprctl", "dispatch", "exit"];
    return ["os-power", "logout"];
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
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", ws]);
      return;
    }
  }

  function closeWorkspaceWindows(id) {
    if (!supportsWorkspaceCloseWindows) {
      notifyUnsupported("Close workspace windows");
      return;
    }

    Quickshell.execDetached([
      "sh",
      "-c",
      "hyprctl clients -j | jq -r '.[] | select(.workspace.id == " + String(id) + ") | .address' | xargs -I {} hyprctl dispatch closewindow address:{}"
    ]);
  }
}
