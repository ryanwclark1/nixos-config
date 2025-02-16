{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  ghostty = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs.ghostty = {
    enable = true;
    package = ghostty;
    installVimSyntax = true;
    installBatSyntax = true;
    clearDefaultKeybinds = false;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
  };

  home.sessionVariables = {
    TERMINAL = "ghostty";
  };

  home.file.".config/ghostty/config".text = ''
    # Font
    font-family = 
    font-size = 14
    font-thicken = true
    font-feature = ss01
    font-feature = ss04

    bold-is-bright = false
    adjust-box-thickness = 1

    # Theme
    # theme = "theme.conf"
    background-opacity = 0.7
    background-blur = true

    # cursor-style = bar
    # cursor-style-blink = true
    # adjust-cursor-thickness = 1

    # resize-overlay = never
    copy-on-select = true
    confirm-close-surface = false
    mouse-hide-while-typing = true

    # window-theme = ghostty
    # window-padding-x = 4
    # window-padding-y = 6
    # window-padding-balance = true
    # window-padding-color = background
    # window-inherit-working-directory = true
    # window-inherit-font-size = true
    # window-decoration = false

    gtk-titlebar = false
    # gtk-single-instance = true
    # gtk-tabs-location = bottom
    # gtk-wide-tabs = false

    auto-update = off
  '';
}