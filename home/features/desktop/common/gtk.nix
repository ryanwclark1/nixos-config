{
  # config,
  lib,
  pkgs,
  ...
}:

# rec
{
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
        gtk-application-prefer-dark-theme = 1;
      };
      #   gtk-application-prefer-dark-theme = 1;
      #   gtk-recent-files-limit = 20;
      # };
      extraCss = ''
        @define-color accent_color #8caaee;
        @define-color accent_bg_color #8caaee;
        @define-color accent_fg_color #303446;
        @define-color destructive_color #e78284;
        @define-color destructive_bg_color #e78284;
        @define-color destructive_fg_color #303446;
        @define-color success_color #a6d189;
        @define-color success_bg_color #a6d189;
        @define-color success_fg_color #303446;
        @define-color warning_color #ca9ee6;
        @define-color warning_bg_color #ca9ee6;
        @define-color warning_fg_color #303446;
        @define-color error_color #e78284;
        @define-color error_bg_color #e78284;
        @define-color error_fg_color #303446;
        @define-color window_bg_color #303446;
        @define-color window_fg_color #c6d0f5;
        @define-color view_bg_color #303446;
        @define-color view_fg_color #c6d0f5;
        @define-color headerbar_bg_color #292c3c;
        @define-color headerbar_fg_color #c6d0f5;
        @define-color headerbar_border_color rgba(0.160156, 0.171875, 0.234375, 0.7);
        @define-color headerbar_backdrop_color @window_bg_color;
        @define-color headerbar_shade_color rgba(0, 0, 0, 0.07);
        @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.07);
        @define-color sidebar_bg_color #292c3c;
        @define-color sidebar_fg_color #c6d0f5;
        @define-color sidebar_backdrop_color @window_bg_color;
        @define-color sidebar_shade_color rgba(0, 0, 0, 0.07);
        @define-color secondary_sidebar_bg_color @sidebar_bg_color;
        @define-color secondary_sidebar_fg_color @sidebar_fg_color;
        @define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
        @define-color secondary_sidebar_shade_color @sidebar_shade_color;
        @define-color card_bg_color #292c3c;
        @define-color card_fg_color #c6d0f5;
        @define-color card_shade_color rgba(0, 0, 0, 0.07);
        @define-color dialog_bg_color #292c3c;
        @define-color dialog_fg_color #c6d0f5;
        @define-color popover_bg_color #292c3c;
        @define-color popover_fg_color #c6d0f5;
        @define-color popover_shade_color rgba(0, 0, 0, 0.07);
        @define-color shade_color rgba(0, 0, 0, 0.07);
        @define-color scrollbar_outline_color #414559;
        @define-color blue_1 #8caaee;
        @define-color blue_2 #8caaee;
        @define-color blue_3 #8caaee;
        @define-color blue_4 #8caaee;
        @define-color blue_5 #8caaee;
        @define-color green_1 #a6d189;
        @define-color green_2 #a6d189;
        @define-color green_3 #a6d189;
        @define-color green_4 #a6d189;
        @define-color green_5 #a6d189;
        @define-color yellow_1 #e5c890;
        @define-color yellow_2 #e5c890;
        @define-color yellow_3 #e5c890;
        @define-color yellow_4 #e5c890;
        @define-color yellow_5 #e5c890;
        @define-color orange_1 #ef9f76;
        @define-color orange_2 #ef9f76;
        @define-color orange_3 #ef9f76;
        @define-color orange_4 #ef9f76;
        @define-color orange_5 #ef9f76;
        @define-color red_1 #e78284;
        @define-color red_2 #e78284;
        @define-color red_3 #e78284;
        @define-color red_4 #e78284;
        @define-color red_5 #e78284;
        @define-color purple_1 #ca9ee6;
        @define-color purple_2 #ca9ee6;
        @define-color purple_3 #ca9ee6;
        @define-color purple_4 #ca9ee6;
        @define-color purple_5 #ca9ee6;
        @define-color brown_1 #eebebe;
        @define-color brown_2 #eebebe;
        @define-color brown_3 #eebebe;
        @define-color brown_4 #eebebe;
        @define-color brown_5 #eebebe;
        @define-color light_1 #292c3c;
        @define-color light_2 #292c3c;
        @define-color light_3 #292c3c;
        @define-color light_4 #292c3c;
        @define-color light_5 #292c3c;
        @define-color dark_1 #292c3c;
        @define-color dark_2 #292c3c;
        @define-color dark_3 #292c3c;
        @define-color dark_4 #292c3c;
        @define-color dark_5 #292c3c;
      '';
    };
    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      extraCss = ''
        @define-color accent_color #8caaee;
        @define-color accent_bg_color #8caaee;
        @define-color accent_fg_color #303446;
        @define-color destructive_color #e78284;
        @define-color destructive_bg_color #e78284;
        @define-color destructive_fg_color #303446;
        @define-color success_color #a6d189;
        @define-color success_bg_color #a6d189;
        @define-color success_fg_color #303446;
        @define-color warning_color #ca9ee6;
        @define-color warning_bg_color #ca9ee6;
        @define-color warning_fg_color #303446;
        @define-color error_color #e78284;
        @define-color error_bg_color #e78284;
        @define-color error_fg_color #303446;
        @define-color window_bg_color #303446;
        @define-color window_fg_color #c6d0f5;
        @define-color view_bg_color #303446;
        @define-color view_fg_color #c6d0f5;
        @define-color headerbar_bg_color #292c3c;
        @define-color headerbar_fg_color #c6d0f5;
        @define-color headerbar_border_color rgba(0.160156, 0.171875, 0.234375, 0.7);
        @define-color headerbar_backdrop_color @window_bg_color;
        @define-color headerbar_shade_color rgba(0, 0, 0, 0.07);
        @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.07);
        @define-color sidebar_bg_color #292c3c;
        @define-color sidebar_fg_color #c6d0f5;
        @define-color sidebar_backdrop_color @window_bg_color;
        @define-color sidebar_shade_color rgba(0, 0, 0, 0.07);
        @define-color secondary_sidebar_bg_color @sidebar_bg_color;
        @define-color secondary_sidebar_fg_color @sidebar_fg_color;
        @define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
        @define-color secondary_sidebar_shade_color @sidebar_shade_color;
        @define-color card_bg_color #292c3c;
        @define-color card_fg_color #c6d0f5;
        @define-color card_shade_color rgba(0, 0, 0, 0.07);
        @define-color dialog_bg_color #292c3c;
        @define-color dialog_fg_color #c6d0f5;
        @define-color popover_bg_color #292c3c;
        @define-color popover_fg_color #c6d0f5;
        @define-color popover_shade_color rgba(0, 0, 0, 0.07);
        @define-color shade_color rgba(0, 0, 0, 0.07);
        @define-color scrollbar_outline_color #414559;
        @define-color blue_1 #8caaee;
        @define-color blue_2 #8caaee;
        @define-color blue_3 #8caaee;
        @define-color blue_4 #8caaee;
        @define-color blue_5 #8caaee;
        @define-color green_1 #a6d189;
        @define-color green_2 #a6d189;
        @define-color green_3 #a6d189;
        @define-color green_4 #a6d189;
        @define-color green_5 #a6d189;
        @define-color yellow_1 #e5c890;
        @define-color yellow_2 #e5c890;
        @define-color yellow_3 #e5c890;
        @define-color yellow_4 #e5c890;
        @define-color yellow_5 #e5c890;
        @define-color orange_1 #ef9f76;
        @define-color orange_2 #ef9f76;
        @define-color orange_3 #ef9f76;
        @define-color orange_4 #ef9f76;
        @define-color orange_5 #ef9f76;
        @define-color red_1 #e78284;
        @define-color red_2 #e78284;
        @define-color red_3 #e78284;
        @define-color red_4 #e78284;
        @define-color red_5 #e78284;
        @define-color purple_1 #ca9ee6;
        @define-color purple_2 #ca9ee6;
        @define-color purple_3 #ca9ee6;
        @define-color purple_4 #ca9ee6;
        @define-color purple_5 #ca9ee6;
        @define-color brown_1 #eebebe;
        @define-color brown_2 #eebebe;
        @define-color brown_3 #eebebe;
        @define-color brown_4 #eebebe;
        @define-color brown_5 #eebebe;
        @define-color light_1 #292c3c;
        @define-color light_2 #292c3c;
        @define-color light_3 #292c3c;
        @define-color light_4 #292c3c;
        @define-color light_5 #292c3c;
        @define-color dark_1 #292c3c;
        @define-color dark_2 #292c3c;
        @define-color dark_3 #292c3c;
        @define-color dark_4 #292c3c;
        @define-color dark_5 #292c3c;
      '';
    };
  };
}