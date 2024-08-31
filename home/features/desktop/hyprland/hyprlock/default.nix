{
  config,
  pkgs,
  ...
}:

with config.lib.stylix.colors;
with config.stylix.fonts;

{
  programs = {
    hyprlock = {
      enable = true;
      package = pkgs.hyprlock;
      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
          grace = 0;
          no_fade_in = false;
          no_fade_out = false;
        };

        # BACKGROUND
        background = {
          # monitor =
          path = "${config.stylix.image}";
          # color = "${base00}";
          blur_passes = 1; # 0 disables blurring
          blur_size = 7;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        };

        # TIME
        label = {
          # monitor =
          text = "$TIME";
          color = "${base00}";
          font_size = 60;
          font_family = "${sansSerif.name}";
          shadow_passes = 1;
          shadow_size = 1;
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
          inner_color = "${base05}";
          font_color = "${base00}";
          fade_on_empty = false;
          placeholder_text = "<span><i>󰌾  Logged in as </i><span>$USER</span></span>";
          hide_input = false;
          # check_color = $accent;
          fail_color = "${base08}";
          fail_text = ''<i>$FAIL <b>($ATTEMPTS)</b></i>'';
          capslock_color = "${base0A}";
          position = "0, -100";
          halign = "center";
          valign = "center";
        };
      };
    };
  };

}

    # USER AVATAR
    # image {
    #   monitor =
    #   path = ~/Pictures/pp/pp.png
    #   size = 125
    #   border_color = $accent
    #   position = 0, -450
    #   halign = center
    #   valign = center
    # }

#   # wallpaper
#   background {
#       monitor =
#       path = ${wallpaper.package}/${wallpaper.name}   # supports png, jpg, webp (no animations, though)
#       color = ${mkRGBA colors.background 1.0}
#       blur_passes = 1 # 0 disables blurring
#       blur_size = 7
#       noise = 0.0117
#       contrast = 0.8916
#       brightness = 0.8172
#       vibrancy = 0.1696
#       vibrancy_darkness = 0.0
#   }

#   shape {
#       monitor =
#       size = 1200, 800
#       color = ${mkRGBA colors.background 0.5}
#       rounding = ${builtins.toString radius}
#       border_size = 0
#       rotate = 0
#       xray = false # if true, make a "hole" in the background (rectangle of specified size, no rotation)
#       position = 150, 0
#       halign = left
#       valign = center
#       shadow_passes = 3
#   }


#   # avatar picture
#   image {
#       monitor =
#       path = /home/vagahbond/Pictures/avatar.png
#       size = 600 # lesser side if not 1:1 ratio
#       rounding = -1 # negative values mean circle
#       border_size = 0
#       border_color =${mkRGB colors.accent}
#       reload_time = -1 # seconds between reloading, 0 to reload with SIGUSR2
#       position = 650, 0
#       halign = center
#       valign = center
#       shadow_passes = 3
#   }


#   # input field, just in case
#   input-field {
#       monitor =
#       size = 400, 50
#       outline_thickness = 1
#       dots_size = 0.33 # Scale of input-field height, 0.2 - 0.8
#       dots_spacing = 0.15 # Scale of dots' absolute size, 0.0 - 1.0
#       dots_center = false
#       dots_rounding = -1 # -1 default circle, -2 follow input-field rounding
#       outer_color = ${mkRGB colors.accent}
#       inner_color = ${mkRGB colors.background}
#       font_color = ${mkRGB colors.text}
#       fade_on_empty = true
#       fade_timeout = 1000 # Milliseconds before fade_on_empty is triggered.
#       placeholder_text = <i>Input Password...</i> # Text rendered in the input box when it's empty.
#       hide_input = false
#       rounding = ${builtins.toString radius} # -1 means complete rounding (circle/oval)
#       check_color = ${mkRGB colors.warning}
#       fail_color = ${mkRGB colors.bad} # if authentication failed, changes outer_color and fail message color
#       fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i> # can be set to empty
#       fail_transition = 300 # transition time in ms between normal outer_color and fail_color
#       capslock_color = ${mkRGB colors.warning}
#       numlock_color = -1
#       bothlock_color = -1 # when both locks are active. -1 means don't change outer color (same for above)
#       invert_numlock = false # change color if numlock is off
#       swap_font_color = false # see below
#       position = -150, -300
#       halign = center
#       valign = center
#       shadow_passes = 3
#   }
