{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.theme.colors)
    base00
    base01
    base02
    base05
    base08
    base09
    base0A
    base0B
    base0D
    base0E
    base0F
    ;
in
{
  # Environment variables for GTK rendering compatibility
  home.sessionVariables = { };

  gtk = {
    enable = lib.mkDefault true;
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 22;
    };
    iconTheme = {
      name = lib.mkDefault "Papirus";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "frappe";
        accent = "lavender";
      };
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
      # name = "Adwaita-purple";
      # package = pkgs.gnomeExtensions.auto-adwaita-colors;
    };
    font = {
      name = lib.mkForce "DejaVu Sans";
      package = pkgs.dejavu_fonts;
      size = 12;
    };
    gtk3 = {
      bookmarks = [
        "file:///home/administrator/Code"
        "file:///home/administrator/Downloads"
        "file:///mnt/share"
        "file:///mnt/conf"
        "file:///mnt/sync"
        "file:///mnt/family"
        "file:///mnt/rclark"
        "file:///mnt/ryan"
      ];
      extraConfig = {
        gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
        gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
        gtk-button-images = 0;
        gtk-menu-images = 0;
        gtk-enable-event-sounds = 1;
        gtk-enable-input-feedback-sounds = 0;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";
        # Removed gtk-application-prefer-dark-theme for libadwaita compatibility
      };
      #   gtk-application-prefer-dark-theme = 1;
      #   gtk-recent-files-limit = 20;
      # };
      extraCss = ''
        @define-color accent_color #${base0D};
        @define-color accent_bg_color #${base0D};
        @define-color accent_fg_color #${base00};
        @define-color destructive_color #${base08};
        @define-color destructive_bg_color #${base08};
        @define-color destructive_fg_color #${base00};
        @define-color success_color #${base0B};
        @define-color success_bg_color #${base0B};
        @define-color success_fg_color #${base00};
        @define-color warning_color #${base0E};
        @define-color warning_bg_color #${base0E};
        @define-color warning_fg_color #${base00};
        @define-color error_color #${base08};
        @define-color error_bg_color #${base08};
        @define-color error_fg_color #${base00};
        @define-color window_bg_color #${base00};
        @define-color window_fg_color #${base05};
        @define-color view_bg_color #${base00};
        @define-color view_fg_color #${base05};
        @define-color headerbar_bg_color #${base01};
        @define-color headerbar_fg_color #${base05};
        @define-color headerbar_border_color rgba(0.160156, 0.171875, 0.234375, 0.7);
        @define-color headerbar_backdrop_color @window_bg_color;
        @define-color headerbar_shade_color rgba(0, 0, 0, 0.07);
        @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.07);
        @define-color sidebar_bg_color #${base01};
        @define-color sidebar_fg_color #${base05};
        @define-color sidebar_backdrop_color @window_bg_color;
        @define-color sidebar_shade_color rgba(0, 0, 0, 0.07);
        @define-color secondary_sidebar_bg_color @sidebar_bg_color;
        @define-color secondary_sidebar_fg_color @sidebar_fg_color;
        @define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
        @define-color secondary_sidebar_shade_color @sidebar_shade_color;
        @define-color card_bg_color #${base01};
        @define-color card_fg_color #${base05};
        @define-color card_shade_color rgba(0, 0, 0, 0.07);
        @define-color dialog_bg_color #${base01};
        @define-color dialog_fg_color #${base05};
        @define-color popover_bg_color #${base01};
        @define-color popover_fg_color #${base05};
        @define-color popover_shade_color rgba(0, 0, 0, 0.07);
        @define-color shade_color rgba(0, 0, 0, 0.07);
        @define-color scrollbar_outline_color #${base02};
        @define-color blue_1 #${base0D};
        @define-color blue_2 #${base0D};
        @define-color blue_3 #${base0D};
        @define-color blue_4 #${base0D};
        @define-color blue_5 #${base0D};
        @define-color green_1 #${base0B};
        @define-color green_2 #${base0B};
        @define-color green_3 #${base0B};
        @define-color green_4 #${base0B};
        @define-color green_5 #${base0B};
        @define-color yellow_1 #${base0A};
        @define-color yellow_2 #${base0A};
        @define-color yellow_3 #${base0A};
        @define-color yellow_4 #${base0A};
        @define-color yellow_5 #${base0A};
        @define-color orange_1 #${base09};
        @define-color orange_2 #${base09};
        @define-color orange_3 #${base09};
        @define-color orange_4 #${base09};
        @define-color orange_5 #${base09};
        @define-color red_1 #${base08};
        @define-color red_2 #${base08};
        @define-color red_3 #${base08};
        @define-color red_4 #${base08};
        @define-color red_5 #${base08};
        @define-color purple_1 #${base0E};
        @define-color purple_2 #${base0E};
        @define-color purple_3 #${base0E};
        @define-color purple_4 #${base0E};
        @define-color purple_5 #${base0E};
        @define-color brown_1 #${base0F};
        @define-color brown_2 #${base0F};
        @define-color brown_3 #${base0F};
        @define-color brown_4 #${base0F};
        @define-color brown_5 #${base0F};
        @define-color light_1 #${base01};
        @define-color light_2 #${base01};
        @define-color light_3 #${base01};
        @define-color light_4 #${base01};
        @define-color light_5 #${base01};
        @define-color dark_1 #${base01};
        @define-color dark_2 #${base01};
        @define-color dark_3 #${base01};
        @define-color dark_4 #${base01};
        @define-color dark_5 #${base01};
      '';
    };
    gtk4 = {
      theme = null;
      extraConfig = {
        # Removed gtk-application-prefer-dark-theme for libadwaita compatibility
        # Dark theme is handled by AdwStyleManager:color-scheme instead
      };
      extraCss = ''
        @define-color accent_color #${base0D};
        @define-color accent_bg_color #${base0D};
        @define-color accent_fg_color #${base00};
        @define-color destructive_color #${base08};
        @define-color destructive_bg_color #${base08};
        @define-color destructive_fg_color #${base00};
        @define-color success_color #${base0B};
        @define-color success_bg_color #${base0B};
        @define-color success_fg_color #${base00};
        @define-color warning_color #${base0E};
        @define-color warning_bg_color #${base0E};
        @define-color warning_fg_color #${base00};
        @define-color error_color #${base08};
        @define-color error_bg_color #${base08};
        @define-color error_fg_color #${base00};
        @define-color window_bg_color #${base00};
        @define-color window_fg_color #${base05};
        @define-color view_bg_color #${base00};
        @define-color view_fg_color #${base05};
        @define-color headerbar_bg_color #${base01};
        @define-color headerbar_fg_color #${base05};
        @define-color headerbar_border_color rgba(0.160156, 0.171875, 0.234375, 0.7);
        @define-color headerbar_backdrop_color @window_bg_color;
        @define-color headerbar_shade_color rgba(0, 0, 0, 0.07);
        @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.07);
        @define-color sidebar_bg_color #${base01};
        @define-color sidebar_fg_color #${base05};
        @define-color sidebar_backdrop_color @window_bg_color;
        @define-color sidebar_shade_color rgba(0, 0, 0, 0.07);
        @define-color secondary_sidebar_bg_color @sidebar_bg_color;
        @define-color secondary_sidebar_fg_color @sidebar_fg_color;
        @define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
        @define-color secondary_sidebar_shade_color @sidebar_shade_color;
        @define-color card_bg_color #${base01};
        @define-color card_fg_color #${base05};
        @define-color card_shade_color rgba(0, 0, 0, 0.07);
        @define-color dialog_bg_color #${base01};
        @define-color dialog_fg_color #${base05};
        @define-color popover_bg_color #${base01};
        @define-color popover_fg_color #${base05};
        @define-color popover_shade_color rgba(0, 0, 0, 0.07);
        @define-color shade_color rgba(0, 0, 0, 0.07);
        @define-color scrollbar_outline_color #${base02};
        @define-color blue_1 #${base0D};
        @define-color blue_2 #${base0D};
        @define-color blue_3 #${base0D};
        @define-color blue_4 #${base0D};
        @define-color blue_5 #${base0D};
        @define-color green_1 #${base0B};
        @define-color green_2 #${base0B};
        @define-color green_3 #${base0B};
        @define-color green_4 #${base0B};
        @define-color green_5 #${base0B};
        @define-color yellow_1 #${base0A};
        @define-color yellow_2 #${base0A};
        @define-color yellow_3 #${base0A};
        @define-color yellow_4 #${base0A};
        @define-color yellow_5 #${base0A};
        @define-color orange_1 #${base09};
        @define-color orange_2 #${base09};
        @define-color orange_3 #${base09};
        @define-color orange_4 #${base09};
        @define-color orange_5 #${base09};
        @define-color red_1 #${base08};
        @define-color red_2 #${base08};
        @define-color red_3 #${base08};
        @define-color red_4 #${base08};
        @define-color red_5 #${base08};
        @define-color purple_1 #${base0E};
        @define-color purple_2 #${base0E};
        @define-color purple_3 #${base0E};
        @define-color purple_4 #${base0E};
        @define-color purple_5 #${base0E};
        @define-color brown_1 #${base0F};
        @define-color brown_2 #${base0F};
        @define-color brown_3 #${base0F};
        @define-color brown_4 #${base0F};
        @define-color brown_5 #${base0F};
        @define-color light_1 #${base01};
        @define-color light_2 #${base01};
        @define-color light_3 #${base01};
        @define-color light_4 #${base01};
        @define-color light_5 #${base01};
        @define-color dark_1 #${base01};
        @define-color dark_2 #${base01};
        @define-color dark_3 #${base01};
        @define-color dark_4 #${base01};
        @define-color dark_5 #${base01};
      '';
    };
  };
}
