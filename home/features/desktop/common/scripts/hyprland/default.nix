{
  pkgs,
  lib,
  ...
}:

{
  # Hyprland-specific scripts (moved from window-managers/hyprland/scripts)
  # These scripts use hyprctl and other Hyprland-specific functionality


  home.packages = with pkgs; [
    # Hyprland utility scripts - maintained as external files

    # Close all windows utility - maintained as external file: ./close-all-windows.sh
    (writeShellScriptBin "close-all-windows" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"

      ''
      + builtins.readFile (./. + "/close-all-windows.sh")
    ))

    # Window information utility - maintained as external file: ./window-info.sh
    (writeShellScriptBin "window-info" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:$PATH"

      ''
      + builtins.readFile (./. + "/window-info.sh")
    ))

    # Workspace switcher utility - maintained as external file: ./workspace-switch.sh
    (writeShellScriptBin "workspace-switch" (
      ''
        PATH="${pkgs.hyprland}/bin:$PATH"

      ''
      + builtins.readFile (./. + "/workspace-switch.sh")
    ))

    # Hyprland keybindings menu - maintained as external file: ./keybindings-menu.sh
    (writeShellScriptBin "keybindings-menu" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libxkbcommon}/bin:${pkgs.walker}/bin:${pkgs.gawk}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin:$PATH"
      ''
      + builtins.readFile ./keybindings-menu.sh
    ))

    # Toggle workspace gaps - maintained as external file: ./workspace-toggle-gaps.sh
    (writeShellScriptBin "workspace-toggle-gaps" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./workspace-toggle-gaps.sh
    ))

    # toggle-nightlight and toggle-idle are now provided as os-toggle-nightlight
    # and os-toggle-idle from scripts/system/ (see common/default.nix)

    # Toggle window transparency - maintained as external file: ./toggle-transparency.sh
    (writeShellScriptBin "toggle-transparency" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./toggle-transparency.sh
    ))

    # Pop window (float + pin) - maintained as external file: ./window-pop.sh
    (writeShellScriptBin "window-pop" (
      ''
        PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
      ''
      + builtins.readFile ./window-pop.sh
    ))
  ];

  home.file = {
    # Hyprland utility scripts directory (only .sh files)
    ".config/desktop/window-managers/hyprland/scripts" = {
      force = true;
      source = lib.cleanSourceWith {
        src = ./.;
        filter = path: type: if type == "directory" then true else lib.hasSuffix ".sh" (baseNameOf path);
      };
      recursive = true;
      executable = true;
    };
  };
}
