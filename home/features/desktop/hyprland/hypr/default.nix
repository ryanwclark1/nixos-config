{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    # ./basic-binds.nix
    ./colors-hyprland.nix
  ];

  home.file.".config/hypr/conf" = {
    source = ./conf;
    recursive = true;
  };

  home.file.".config/hypr/effects" = {
    source = ./effects;
    recursive = true;
  };

  home.file.".config/hypr/shaders" = {
    source = ./shaders;
    recursive = true;
  };

  home.file.".config/hypr/scripts" = {
    source = ./scripts;
    recursive = true;
    executable = true;
  };

  # programs.uwsm = {};

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
    xwayland.enable = true;
    systemd = {
      enable = false;
      enableXdgAutostart = true;
    };
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    plugins = [
      # inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
      # inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprwinwrap
    ];
    settings ={
      source = [
        "~/.config/hypr/conf/animation.conf"
        # "~/.config/hypr/conf/autostart.conf"
        "~/.config/hypr/conf/autostart-uwsm.conf"
        "~/.config/hypr/conf/colors-hyprland.conf"
        "~/.config/hypr/conf/cursor.conf"
        "~/.config/hypr/conf/custom.conf"
        "~/.config/hypr/conf/decoration.conf"
        "~/.config/hypr/conf/environment.conf"
        "~/.config/hypr/conf/keybinding.conf"
        "~/.config/hypr/conf/keyboard.conf"
        "~/.config/hypr/conf/layout.conf"
        "~/.config/hypr/conf/misc.conf"
        "~/.config/hypr/conf/ml4w.conf"
        "~/.config/hypr/conf/monitor.conf"
        "~/.config/hypr/conf/window.conf"
        "~/.config/hypr/conf/windowrule.conf"
        "~/.config/hypr/conf/workspace.conf"
      ];
    };
  };
}
