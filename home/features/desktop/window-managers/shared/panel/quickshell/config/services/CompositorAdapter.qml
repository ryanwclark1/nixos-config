import QtQuick
import Quickshell

pragma Singleton

QtObject {
  id: root

  readonly property string desktopEnv: (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
  readonly property string sessionDesktop: (Quickshell.env("DESKTOP_SESSION") || "").toLowerCase()
  readonly property bool hasHyprSig: (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || "") !== ""
  readonly property bool hasNiriSocket: (Quickshell.env("NIRI_SOCKET") || "") !== ""

  readonly property bool desktopSaysHyprland: desktopEnv.indexOf("hyprland") !== -1 || sessionDesktop.indexOf("hyprland") !== -1
  readonly property bool desktopSaysNiri: desktopEnv.indexOf("niri") !== -1 || sessionDesktop.indexOf("niri") !== -1

  readonly property bool isNiri: desktopSaysNiri || (hasNiriSocket && !desktopSaysHyprland)
  readonly property bool isHyprland: desktopSaysHyprland || (hasHyprSig && !desktopSaysNiri)
  readonly property string compositor: isHyprland ? "hyprland" : (isNiri ? "niri" : "unknown")

  readonly property bool supportsWorkspaceListing: isHyprland || isNiri
  readonly property bool supportsWorkspaceFocus: isHyprland || isNiri
  readonly property bool supportsWorkspaceOsd: isHyprland || isNiri
  readonly property bool supportsWindowListing: isHyprland
  readonly property bool supportsWorkspaceRename: isHyprland
  readonly property bool supportsWorkspaceMove: isHyprland
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

  function hotkeysCommand() {
    if (supportsHotkeysListing) return ["hyprctl", "binds", "-j"];
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
      "hyprctl getoption general:gaps_out -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption general:gaps_in -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption decoration:active_opacity -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption general:layout -j 2>/dev/null"
    ];
  }

  function nightLightStatusCommand() {
    if (!supportsHyprctlSettings) return ["sh", "-c", "echo 'off'"];
    return ["sh", "-c", "hyprctl hyprsunset temperature 2>/dev/null | grep -v '6000' >/dev/null && echo 'on' || echo 'off'"];
  }

  // Returns shell snippet setting share_out=0/1 for PrivacyService polling.
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

  // Returns wallpaper backend fallback snippet that may set ok=1.
  // `wallpaperArgQuoted` must be a shell-quoted argument (e.g. 'DP-1,/path/image.jpg').
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

  function dispatchAction(action, arg, unsupportedName) {
    if (!supportsDispatcherActions) {
      notifyUnsupported(unsupportedName || ("Dispatch " + String(action || "")));
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

  function moveWindowToWorkspace(address, workspaceId) {
    if (!supportsWorkspaceMove) {
      notifyUnsupported("Move window to workspace");
      return;
    }
    dispatchAction("movetoworkspace", String(workspaceId) + ",address:" + String(address), "Move window to workspace");
  }

  function focusWindowAddress(address) {
    if (!supportsDispatcherActions) {
      notifyUnsupported("Focus window");
      return;
    }
    dispatchAction("focuswindow", "address:" + String(address), "Focus window");
  }

  function toggleScratchpadWorkspace(name) {
    if (!supportsScratchpad) {
      notifyUnsupported("Toggle scratchpad");
      return;
    }
    dispatchAction("togglespecialworkspace", String(name || "scratchpad"), "Toggle scratchpad");
  }

}
