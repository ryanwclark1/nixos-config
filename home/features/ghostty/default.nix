{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  ghostty = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
in
{
  home.sessionVariables = {
    TERMINAL = "ghostty";
    # Additional OpenGL fallbacks for Ghostty specifically
    LIBGL_ALWAYS_SOFTWARE = "1";
  };

  programs.ghostty = {
    enable = true;
    package = ghostty;
    installVimSyntax = true;
    installBatSyntax = true;
    clearDefaultKeybinds = false;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    settings = {
      theme = "theme";
      font-size = 14;
      auto-update = "off";
      background-opacity = 0.7;
      background-blur = true;
      copy-on-select = true;
      
      # Fix for EGL display errors
      gtk-titlebar = false;
    };
    themes = {
      theme = {
        # background = "${base00}";
        foreground = "${base05}";
        cursor-color = "${base06}";
        palette = [
          "0=#${base03}"
          "1=#${base08}"
          "2=#${base0B}"
          "3=#${base0A}"
          "4=#${base0D}"
          "5=#${base17}"
          "6=#${base0C}"
          "7=#${base05}"
          "8=#${base04}"
          "9=#${base08}"
          "10=#${base0B}"
          "11=#${base0A}"
          "12=#${base0D}"
          "13=#${base17}"
          "14=#${base0C}"
          "15=#${base05}"
        ];
        selection-background = "${base04}";
        selection-foreground = "${base05}";
      };
    };
  };

  # home.file.".config/ghostty/config".text = ''
  #   # Font
  #   font-family = 
  #   font-size = 14
  #   font-thicken = true
  #   font-feature = ss01
  #   font-feature = ss04

  #   bold-is-bright = false
  #   adjust-box-thickness = 1

  #   # Theme
  #   # theme = "theme.conf"
  #   background-opacity = 0.7
  #   background-blur = true

  #   # cursor-style = bar
  #   # cursor-style-blink = true
  #   # adjust-cursor-thickness = 1

  #   # resize-overlay = never
  #   copy-on-select = true
  #   confirm-close-surface = false
  #   mouse-hide-while-typing = true

  #   # window-theme = ghostty
  #   # window-padding-x = 4
  #   # window-padding-y = 6
  #   # window-padding-balance = true
  #   # window-padding-color = background
  #   # window-inherit-working-directory = true
  #   # window-inherit-font-size = true
  #   # window-decoration = false

  #   gtk-titlebar = false
  #   # gtk-single-instance = true
  #   # gtk-tabs-location = bottom
  #   # gtk-wide-tabs = false

  #   auto-update = off
  # '';
}