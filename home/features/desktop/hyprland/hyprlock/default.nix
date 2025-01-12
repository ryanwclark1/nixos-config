{
  config,
  pkgs,
  ...
}:

{
  programs = {
    hyprlock = {
      enable = true;
      package = pkgs.hyprlock;
      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = false;
          grace = 0;
          no_fade_in = false;
          no_fade_out = true;
          text_trim = true;
          fractional_scaling = 2;
        };

        auth = {
          # fingerprint = lib.mkIf config.services.fprintd.enable true;
          fingerprint = {
            enabled = true;
          };
        };

        # BACKGROUND
        background = {
          # monitor =
          path = "${config.stylix.image}";
          color = "rgb(48,52,70)";
          blur_passes = 1; # 0 disables blurring
          blur_size = 7;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.05;
          reload_time = -1;
          crossfade_time = -1.0;
          zindex = -1;
        };

        # TIME
        label = {
          # monitor =
          text = "$TIME";
          color = "rgb(48,52,70)";
          font_size = 72;
          font_family = "${config.stylix.fonts.sansSerif.name}";
          shadow_passes = 1;
          shadow_size = 1;
          rotate = 0;
          position = "0, -200";
          halign = "center";
          valign = "top";
        };

        # INPUT FIELD
        input-field = {
          # monitor =
          size = "400, 60";
          outline_thickness = 1;
          dots_size = 0.33; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = false;
          dots_rounding = -1; # -1 default circle, -2 follow input-field rounding
          # outer_color = $accent;
          inner_color = "rgb(198,208,245)";
          font_color = "rgb(48,52,70)";
          fade_on_empty = false;
          placeholder_text = "<span><i>󰌾  Logged in as </i><span>$USER</span></span>";
          hide_input = false;
          # check_color = $accent;
          fail_color = "rgb(231,130,132)";
          fail_text = ''<i>$FAIL <b>($ATTEMPTS)</b></i>'';
          capslock_color = "rgb(229,200,144)";
          numlock_color = "rgb(229,200,144)";
          bothlock_color = "rgb(229,200,144)";
          position = "0, -100";
          halign = "center";
          valign = "center";
          zindex = 0;
        };
      };
    };
  };
}
