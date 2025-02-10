{
  lib,
  config,
  ...
}:
let
  hypridle = lib.getExe config.services.hypridle.package;
in

{
  imports = [
    ./basic-binds.nix
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
    source = ./scripts;
    recursive = true;
    executable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    settings ={

      source = [
        "~/.config/hypr/conf/monitor.conf"
      ];

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "NIXOS_OZONE_WL, 1"
        "GDK_BACKEND, wayland, x11"
        "CLUTTER_BACKEND, wayland"
        "QT_QPA_PLATFORM=wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION, 1"
        "QT_AUTO_SCREEN_SCALE_FACTOR, 1"
        "SDL_VIDEODRIVER, x11"
        "MOZ_ENABLE_WAYLAND, 1"
      ];

      monitor = [
        ",highres,auto,1"
      ];

      "exec-once" =[
        "dbus-update-activation-environment --systemd --all"
        "systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${hypridle} &"
        # "killall -q ags; sleep .5 && cd ~/.config/ags && ags run ~/.config/ags/app.ts &"
        # "nm-applet --indicator"
        # The cliphist service is now systemd 
        # "${wl-paste} --watch ${cliphist} store"
        # "systemctl --user start waybar"
      ];

      general = {
        border_size = 1;
        gaps_in = 3;
        gaps_out = 5;
        gaps_workspaces = 0;
        # "col.active_border" = "0xffffffff";
        # "col.inactive_border" = "0xff444444";
        # "col.nogroup_border" = "0xffffaaff";
        # "col.nogroup_border_active" = "0xffff00ff";
        layout = "dwindle";
        no_focus_fallback = false;
        resize_on_border = true;
        extend_border_grab_area = 15;
        hover_icon_on_border = true;
        allow_tearing = false;
        resize_corner = 0;
      };

      decoration = {
        rounding = 10;
        active_opacity = .97;
        inactive_opacity = 0.87;
        fullscreen_opacity = 1.0;
        # drop_shadow = true;
        # shadow_range = 12;
        # shadow_render_power = 3;
        # shadow_ignore_window = true;
        # "col.shadow" = "0xee1a1a1a";
        # "col.shadow_inactive" = "unset";
        # shadow_offset = "3 3";
        # shadow_scale = 1.0;
        dim_inactive = false;
        dim_strength = 0.5;
        dim_special = 0.2;
        dim_around = 0.4;
        blur = {
          enabled = true;
          size = 8;
          passes = 4;
          ignore_opacity = false;
          new_optimizations = true;
          xray = true;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          special = false;
          popups = true;
          popups_ignorealpha = 0.2;
        };
      };

      input = {
        kb_layout = "us";
        kb_options = [
          "caps:super"
          "grp:alt_shift_toggle"
        ];
        numlock_by_default = false;
        resolve_binds_by_sym = false;
        repeat_rate = 25;
        repeat_delay = 600;
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        force_no_accel = false;
        left_handed = false;
        scroll_button = 0;
        scroll_button_lock = false;
        scroll_factor = 1.5;
        natural_scroll = false;
        follow_mouse = 1;
        mouse_refocus = true;
        float_switch_override_focus = 1;
        special_fallthrough = false;
        off_window_axis_events = 1;
        # emulate_discrete_scroll = 1;
        touchpad = {
          disable_while_typing = true;
          natural_scroll = true;
          scroll_factor = 1.0;
          clickfinger_behavior = false;
          tap-to-click = true;
          drag_lock = false;
          tap-and-drag = false;
        };

      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

      group = {
        insert_after_current = true;
        focus_removed_window = true;
        merge_groups_on_drag = true;
        # "col.border_active" = "0x66ffff00";
        # "col.border_inactive" = "0x66777700";
        # "col.border_locked_active" = "0x66ff5500";
        # "col.border_locked_inactive" = "0x66775500";
        groupbar = {
          enabled = true;
          font_size = 11;
          gradients = true;
          height = 14;
          stacked = false;
          priority = 3;
          render_titles = true;
          scrolling = true;
          # text_color = "0xffffffff";
          # "col.active" = "0x66ffff00";
          # "col.inactive" = "0x66777700";
          # "col.locked_active" = "0x66ff5500";
          # "col.locked_inactive" = "0x66775500";
        };
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        # "col.splash" = "0xffffffff";
        font_family = "Sans";
        vfr = true;
        vrr = 0;
        mouse_move_enables_dpms = false;
        key_press_enables_dpms = false;
        always_follow_on_dnd = true;
        layers_hog_keyboard_focus = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        disable_autoreload = false;
        enable_swallow = false;
        focus_on_activate = true;
        mouse_move_focuses_monitor = true;
        render_ahead_of_time = false;
        render_ahead_safezone = 1;
        allow_session_lock_restore = false;
        # background_color = "0x111111";
        close_special_on_empty = true;
        # Unfullscreen when opening something
        new_window_takes_over_fullscreen = 2;
        # exit_window_retains_fullscreen = false;
        initial_workspace_tracking = 1;
        middle_click_paste = true;
        render_unfocused_fps = 15;
        # disable_xdg_env_checks = false;
      };

      binds = {
        pass_mouse_when_bound = false;
        scroll_event_delay = 300;
        workspace_back_and_forth = false;
        allow_workspace_cycles = false;
        workspace_center_on = 0;
        focus_preferred_method = 0;
        ignore_group_lock = false;
        movefocus_cycles_fullscreen = false;
        disable_keybind_grabbing = false;
        window_direction_monitor_fallback = true;
      };

      cursor = {
        # sync_gsettings_theme = true;
        no_hardware_cursors = false;
        no_break_fs_vrr = false;
        min_refresh_rate = 24;
        hotspot_padding = 1;
        inactive_timeout = 0;
        no_warps = false;
        persistent_warps = false;
        warp_on_change_workspace = false;
        zoom_factor = 1.0;
        zoom_rigid = false;
        enable_hyprcursor = true;
        hide_on_key_press = false;
        hide_on_touch = true;
        # allow_dumb_copy = false;
      };

      dwindle = {
        pseudotile = true;
        force_split = 0;
        preserve_split = false;
        smart_split = false;
        smart_resizing = true;
        permanent_direction_override = false;
        special_scale_factor = 1;
        split_width_multiplier = 1.0;
        # no_gaps_when_only = 0;
        use_active_for_splits = true;
        default_split_ratio = 1.0;
      };

      windowrule = let
        f = regex: "float, ^(${regex})$";
      in [
        (f "org.gnome.Calculator")
        (f "pwvucontrol")
        (f "nm-connection-editor")
        (f "blueberry.py")
        (f "org.gnome.Settings")
        (f "org.gnome.design.Palette")
        (f "Color Picker")
        (f "xdg-desktop-portal")
        (f "xdg-desktop-portal-gnome")
        (f "de.haeckerfelix.Fragments")
        (f "com.github.Aylur.ags")
      ];

      windowrulev2 = [
        "stayfocused, title:^()$,class:^(steam)$"
        "minsize 1 1, title:^()$,class:^(steam)$"
        "opacity 0.70, class:^(com.mitchellh.ghostty)$"
        "opacity 0.97, class:^(code)$"
      ];

      layerrule = [
        "animation fade,hyprpicker"
        "animation fade,selection"

        "animation fade,waybar"
        "blur,waybar"
        "ignorezero,waybar"

        "blur,notifications"
        "ignorezero,notifications"

        "blur,rofi"
        "ignorezero,rofi"

        "noanim,wallpaper"
      ];

      animations = {
        enabled = true;
        bezier = [
          "easein,0.1, 0, 0.5, 0"
          "easeinback,0.35, 0, 0.95, -0.3"
          "easeout,0.5, 1, 0.9, 1"
          "easeoutback,0.35, 1.35, 0.65, 1"
          "easeinout,0.45, 0, 0.55, 1"
        ];

        animation = [
          "fadeIn,1,3,easeout"
          "fadeLayersIn,1,3,easeoutback"
          "layersIn,1,3,easeoutback,slide"
          "windowsIn,1,3,easeoutback,slide"

          "fadeLayersOut,1,3,easeinback"
          "fadeOut,1,3,easein"
          "layersOut,1,3,easeinback,slide"
          "windowsOut,1,3,easeinback,slide"

          "border,1,3,easeout"
          "fadeDim,1,3,easeinout"
          "fadeShadow,1,3,easeinout"
          "fadeSwitch,1,3,easeinout"
          "windowsMove,1,3,easeoutback"
          "workspaces,1,2.6,easeoutback,slide"
        ];
      };
    };
  };
}