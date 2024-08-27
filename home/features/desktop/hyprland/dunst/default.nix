{ pkgs, ... }:

{
  services = {
    dunst = {
      enable = true;
      package = pkgs.dunst;
      # $XDG_CONFIG_HOME/dunst/dunstrc
      settings = {
        global = {
          monitor = 0;
          follow = "none";
          width = 300;
          height = 300;
          offset = "30x30";
          origin = "top-center";
          scale = 0;
          notification_limit = 20;
          progress_bar = true;
          progress_bar_height = 10;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;
          progress_bar_max_width = 300;
          progress_bar_corner_radius = 10;
          indicate_hidden = "yes";
          transparency = 30;
          seperator_height = 2;
          padding = 8;
          horizontal_padding = 8;
          text_icon_padding = 0;
          frame_width = 1;
          frame_color = "#ffffff";
          gap_size = 0;
          seperator_color = "frame";
          sort = "yes";
          icon_corner_radius = 0;
          font = "Droid Sans 9";
          line_height = 1;
          markup = "full";
          format = "<b>%s</b>\n%b";
          alignment = "left";
          vertical_alignment = "center";
          show_age_threshold = 60;
          ellipsize = "middle";
          ignore_newline = "no";
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = "yes";
          enable_recursive_icon_lookup = true;
          # icon_theme = "Papirus-Dark,Adwaita";
          icon_position = "left";
          min_icon_size = 32;
          max_icon_size = 128;
          sticky_history = "yes";
          history_length = 20;
          dmenu = "dmenu -p dunst:";
          browser = "xdg-open";
          alway_run_script = true;
          title = "Dunst";
          class = "Dunst";
          corner_radius = 10;
          ignore_dbusclose = false;
          force_xwayland = false;
          force_xinerama = false;
          mouse_left_click = "close_current";
          mouse_middle_click = "do_action, close_current";
          mouse_right_click = "close_all";
        };

        urgency_low = {
          background = "#37474f";
          foreground = "#eceff1";
          timeout = 10;
        };

        urgency_normal = {
          background = "#37474f";
          foreground = "#eceff1";
          timeout = 10;
        };

        urgency_critical = {
          background = "#37474f";
          foreground = "#eceff1";
          timeout = 10;
        };

      };
      # setting.global.icon_path = "/usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/";
      # iconTheme = {
      #  name = "Papirus";
      #  size = 32;
      #  package = pkgs.papirus-icon-theme;
      # };
      # Allows using a mutable configuration file generated from the immutable one, useful in scenarios where live reloading is desired.
      configFile = "$XDG_CONFIG_HOME/dunst/dunstrc";
      # Set the service's WAYLAND_DISPLAY environment variable.
      # waylandDisplay = "";

    };
  };
}