{
  config,
  inputs,
  lib,
  ...
}:
let
  ghostty = inputs.ghostty.packages.x86_64-linux.default;
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

  # xdg.configFile."ghostty/config".text = ''
  #   # Font
  #   font-family = "DejaVu Sans"
  #   font-size = 14
  #   font-thicken = true
  #   font-feature = ss01
  #   font-feature = ss04

  #   bold-is-bright = false
  #   adjust-box-thickness = 1

  #   # Theme
  #   theme = "catppuccin-frappe"
  #   background-opacity = 0.7

  #   cursor-style = bar
  #   cursor-style-blink = true
  #   adjust-cursor-thickness = 1

  #   resize-overlay = never
  #   copy-on-select = false
  #   confirm-close-surface = false
  #   mouse-hide-while-typing = true

  #   window-theme = ghostty
  #   window-padding-x = 4
  #   window-padding-y = 6
  #   window-padding-balance = true
  #   window-padding-color = background
  #   window-inherit-working-directory = true
  #   window-inherit-font-size = true
  #   window-decoration = false

  #   gtk-titlebar = false
  #   gtk-single-instance = true
  #   gtk-tabs-location = bottom
  #   gtk-wide-tabs = false

  #   auto-update = off
  # '';
  # xdg.configFile."ghostty/themes/catppuccin-mocha".text = ''
  #   palette = 0=#45475a
  #   palette = 1=#f38ba8
  #   palette = 2=#a6e3a1
  #   palette = 3=#f9e2af
  #   palette = 4=#89b4fa
  #   palette = 5=#f5c2e7
  #   palette = 6=#94e2d5
  #   palette = 7=#bac2de
  #   palette = 8=#585b70
  #   palette = 9=#f38ba8
  #   palette = 10=#a6e3a1
  #   palette = 11=#f9e2af
  #   palette = 12=#89b4fa
  #   palette = 13=#f5c2e7
  #   palette = 14=#94e2d5
  #   palette = 15=#a6adc8
  #   background = 1e1e2e
  #   foreground = cdd6f4
  #   cursor-color = f5e0dc
  #   selection-background = 353749
  #   selection-foreground = cdd6f4
  # '';
  # xdg.configFile."ghostty/themes/catppuccin-frappe".text = ''
  #   palette = 0=#51576d
  #   palette = 1=#e78284
  #   palette = 2=#a6d189
  #   palette = 3=#e5c890
  #   palette = 4=#8caaee
  #   palette = 5=#f4b8e4
  #   palette = 6=#81c8be
  #   palette = 7=#b5bfe2
  #   palette = 8=#626880
  #   palette = 9=#e78284
  #   palette = 10=#a6d189
  #   palette = 11=#e5c890
  #   palette = 12=#8caaee
  #   palette = 13=#f4b8e4
  #   palette = 14=#81c8be
  #   palette = 15=#a5adce
  #   background = 303446
  #   foreground = c6d0f5
  #   cursor-color = f2d5cf
  #   selection-background = 44495d
  #   selection-foreground = c6d0f5
  # '';
}

# Stylix
# background = 303446
# cursor-color = c6d0f5
# foreground = c6d0f5
# palette = 0=#303446
# palette = 1=#e78284
# palette = 2=#a6d189
# palette = 3=#e5c890
# palette = 4=#8caaee
# palette = 5=#ca9ee6
# palette = 6=#81c8be
# palette = 7=#c6d0f5
# palette = 8=#51576d
# palette = 9=#e78284
# palette = 10=#a6d189
# palette = 11=#e5c890
# palette = 12=#8caaee
# palette = 13=#ca9ee6
# palette = 14=#81c8be
# palette = 15=#babbf1
# selection-background = 414559
# selection-foreground = c6d0f5