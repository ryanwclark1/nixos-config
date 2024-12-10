{
  config,
  lib,
  pkgs,
  ...
}:


{
  services = {
    dunst =
    let
      opacity = lib.toHexString (((builtins.ceil (config.stylix.opacity.popups * 100)) * 255) / 100);
      rofi = lib.getExe config.programs.rofi.package;
    in
    {
      enable = true;
      package = pkgs.dunst;
      settings = {
        # https://dunst-project.org/documentation
        global = {
          monitor = 0;
          follow = "none";
          width = 500;
          height = 800;
          notification_limit = 20;
          offset = "0x10";
          origin = "top-center";
          scale = 0;
          progress_bar = true;
          progress_bar_horizontal_alignmen = "center";
          progress_bar_height = 10;
          progress_bar_min_width = 150;
          progress_bar_max_width = 300;
          progress_bar_frame_width = 1;
          progress_bar_corner_radius = 0;
          progress_bar_corners = "all";
          icon_corner_radius = 0;
          icon_corners = "all";
          indicate_hidden = true;
          # transparency = 30;
          seperator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          text_icon_padding = 0;
          frame_width = 3;
          gap_size = 0;
          frame_color = "${config.lib.stylix.colors.withHashtag.base0D}";
          seperator_color = "${config.lib.stylix.colors.withHashtag.base0D}";
          sort = true;
          idle_threshold = 0;
          layer = "overlay";
          force_xwayland = false;
          font = "${config.stylix.fonts.monospace.name} 12";
          line_height = 0;
          format = ''<b>%s</b>\n%b'';
          vertical_alignment = "center";
          show_age_threshold = 60;
          ignore_newline = false;
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = true;
          # enable_recursive_icon_lookup = true;
          # icon_theme = "Papirus-Dark,Adwaita";
          # icon_position = "left";
          # min_icon_size = 32;
          # max_icon_size = 128;

          sticky_history = true;
          history_length = 20;
          dmenu = "${rofi} -dmenu -p dunst";
          browser = "xdg-open";
          alway_run_script = true;
          title = "Dunst";
          class = "Dunst";
          force_xinerama = false;
          corner_radius = 10;
          corners = "all";
          mouse_left_click = "close_current";
          mouse_middle_click = "do_action, close_current";
          mouse_right_click = "close_all";
          ignore_dbusclose = false;
          override_pause_level = 0;
        };
        urgency_low = {
          background = "${config.lib.stylix.colors.withHashtag.base06}${opacity}";
          foreground = "${config.lib.stylix.colors.withHashtag.base0A}";
          timeout = 15;
        };

        urgency_normal = {
          background = "${config.lib.stylix.colors.withHashtag.base00}${opacity}";
          foreground = "${config.lib.stylix.colors.withHashtag.base0A}";
          timeout = 15;
        };

        urgency_critical = {
          background = "${config.lib.stylix.colors.withHashtag.base0F}${opacity}";
          foreground = "${config.lib.stylix.colors.withHashtag.base06}";
          timeout = 20;
        };

      };
      iconTheme = {
       name = "Papirus";
       size = "32x32";
       package = pkgs.papirus-icon-theme;
      };
      configFile = "${config.home.homeDirectory}/.config/dunst/dunstrc";
      # Set the service's WAYLAND_DISPLAY environment variable.
      # waylandDisplay = "";

    };
  };
}