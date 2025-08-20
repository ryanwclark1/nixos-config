{
  inputs,
  pkgs,
  ...
}:

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
    source = ../scripts;
    recursive = true;
    executable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
    xwayland.enable = true;
    systemd = {
      enable = false;
      enableXdgAutostart = true;
    };
    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
    ];
    
    extraConfig = ''
      # Source all configuration files
      source = ~/.config/hypr/conf/monitor.conf
      source = ~/.config/hypr/conf/environment.conf
      source = ~/.config/hypr/conf/autostart.conf
      source = ~/.config/hypr/conf/keyboard.conf
      source = ~/.config/hypr/conf/cursor.conf
      source = ~/.config/hypr/conf/layout.conf
      source = ~/.config/hypr/conf/misc.conf
      source = ~/.config/hypr/conf/decoration.conf
      source = ~/.config/hypr/conf/animation.conf
      source = ~/.config/hypr/conf/window.conf
      source = ~/.config/hypr/conf/windowrule.conf
      source = ~/.config/hypr/conf/workspace.conf
      source = ~/.config/hypr/conf/keybinding.conf
      source = ~/.config/hypr/conf/plugin-hyprexpo.conf
      source = ~/.config/hypr/conf/custom.conf
      
      # Source color scheme
      source = ~/.config/hypr/conf/colors-hyprland.conf
    '';
  };
}