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

  readonly property bool supportsWorkspaceRename: isHyprland
  readonly property bool supportsWorkspaceMove: isHyprland
  readonly property bool supportsHyprctlSettings: isHyprland

  function notifyUnsupported(actionName) {
    Quickshell.execDetached([
      "notify-send",
      "Unsupported action",
      actionName + " is currently only implemented for Hyprland."
    ]);
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
    if (isHyprland) {
      Quickshell.execDetached(["hyprctl", "dispatch", "workspace", ws]);
      return;
    }
    if (isNiri) {
      Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", ws]);
      return;
    }
    notifyUnsupported("Focus workspace");
  }

  function closeWorkspaceWindows(id) {
    if (!isHyprland) {
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
