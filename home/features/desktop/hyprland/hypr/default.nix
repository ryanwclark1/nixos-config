{
  # lib,
  # config,
  ...
}:
# let
#   hypridle = lib.getExe config.services.hypridle.package;
# in
{
  imports = [
    ./basic-binds.nix
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

  # home.file.".config/hypr/hyprland.conf" = {
  #   source = ./hyprland.conf;
  # };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    settings ={
      # "exec-once" = [
      #   "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      # ];
      source = [
        "~/.config/hypr/conf/monitor.conf"
        "~/.config/hypr/conf/cursor.conf"
        "~/.config/hypr/conf/environment.conf"
        "~/.config/hypr/conf/keyboard.conf"
        "~/.config/hypr/conf/colors-hyprland.conf"
        "~/.config/hypr/conf/autostart.conf"
        "~/.config/hypr/conf/window.conf"
        "~/.config/hypr/conf/decoration.conf"
        "~/.config/hypr/conf/layout.conf"
        "~/.config/hypr/conf/workspace.conf"
        "~/.config/hypr/conf/misc.conf"
        # "~/.config/hypr/conf/keybinding.conf"
        "~/.config/hypr/conf/windowrule.conf"
        "~/.config/hypr/conf/animation.conf"
        "~/.config/hypr/conf/ml4w.conf"
        "~/.config/hypr/conf/custom.conf"
      ];
    };

  };
}
