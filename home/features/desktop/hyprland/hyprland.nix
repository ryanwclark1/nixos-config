{
  lib,
  ...
}:

{
  wayland = {
    windowManager = {
      hyprland = {
        settings = {
          general = {
            gaps_in = 4;
            gaps_out = 8;
            border_size = 3;
            cursor_inactive_timeout = 4;
            layout = "dwindle";
            resize_on_border = true;
          };
          decoration = {
            active_opacity = 0.97;
            inactive_opacity = 0.77;
            fullscreen_opacity = 1.0;
            rounding = 10;
            blur = {
              enabled = true;
              size = 5;
              passes = 3;
              new_optimizations = true;
              ignore_opacity = true;
            };
          };
          group = {
            groupbar = {
              font_size = 11;
            };
          };
          input = {
            kb_layout = "us";
            kb_options = "caps:super";
            follow_mouse = 1;
            touchpad = {
              natural_scroll = true;
            };
            sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
          };
          gestures = {
            workspace_swipe = true;
            workspace_swipe_fingers = 3;
          };
          dwindle = {
            pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true;
            split_width_multiplier = 1.35;
          };
          misc = {
            vfr = true;
            close_special_on_empty = true;
            new_window_takes_over_fullscreen = 2;
            mouse_move_enables_dpms = true;
            key_press_enables_dpms = false;
          };
          layerrule = [
            "blur,waybar"
            "ignorezero,waybar"
          ];
          animations = {
            enable = true;
            bezier = [
              "wind, 0.05, 0.9, 0.1, 1.05"
              "winIn, 0.1, 1.1, 0.1, 1.1"
              "winOut, 0.3, -0.3, 0, 1"
              "liner, 1, 1, 1, 1"
            ];
            animation = [
              "windows, 1, 6, wind, slide"
              "windowsIn, 1, 6, winIn, slide"
              "windowsOut, 1, 5, winOut, slide"
              "windowsMove, 1, 5, wind, slide"
              "border, 1, 1, liner"
              "borderangle, 1, 30, liner, loop"
              "fade, 1, 10, default"
              "workspaces, 1, 5, wind"
            ];

          };
           bind = let
            workspaces = [
              "0"
              "1"
              "2"
              "3"
              "4"
              "5"
              "6"
              "7"
              "8"
              "9"
              "F1"
              "F2"
              "F3"
              "F4"
              "F5"
              "F6"
              "F7"
              "F8"
              "F9"
              "F10"
              "F11"
              "F12"
            ];
            # Map keys (arrows and hjkl) to hyprland directions (l, r, u, d)
            directions = rec {
              left = "l";
              right = "r";
              up = "u";
              down = "d";
              h = left;
              l = right;
              k = up;
              j = down;
            };
          in
            [
              "SUPERSHIFT,q,killactive"
              "SUPERSHIFT,e,exit"

              "SUPER,s,togglesplit"
              "SUPER,f,fullscreen,1"
              "SUPERSHIFT,f,fullscreen,0"
              "SUPERSHIFT,space,togglefloating"

              "SUPER,minus,splitratio,-0.25"
              "SUPERSHIFT,minus,splitratio,-0.3333333"

              "SUPER,equal,splitratio,0.25"
              "SUPERSHIFT,equal,splitratio,0.3333333"

              "SUPER,g,togglegroup"
              "SUPER,t,lockactivegroup,toggle"
              "SUPER,tab,changegroupactive,f"
              "SUPERSHIFT,tab,changegroupactive,b"

              "SUPER,apostrophe,workspace,previous"
              "SUPERSHIFT,apostrophe,workspace,next"
              "SUPER,dead_grave,workspace,previous"
              "SUPERSHIFT,dead_grave,workspace,next"

              "SUPER,u,togglespecialworkspace"
              "SUPERSHIFT,u,movetoworkspacesilent,special"
              "SUPER,i,pseudo"
            ]
            ++
            # Change workspace
            (map (n: "SUPER,${n},workspace,name:${n}") workspaces)
            ++
            # Move window to workspace
            (map (n: "SUPERSHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)
            ++
            # Move focus
            (lib.mapAttrsToList (key: direction: "SUPER,${key},movefocus,${direction}") directions)
            ++
            # Swap windows
            (lib.mapAttrsToList (key: direction: "SUPERSHIFT,${key},swapwindow,${direction}") directions)
            ++
            # Move windows
            (lib.mapAttrsToList (
                key: direction: "SUPERCONTROL,${key},movewindoworgroup,${direction}"
              )
              directions)
            ++
            # Move monitor focus
            (lib.mapAttrsToList (key: direction: "SUPERALT,${key},focusmonitor,${direction}") directions)
            ++
            # Move workspace to other monitor
            (lib.mapAttrsToList (
                key: direction: "SUPERALTSHIFT,${key},movecurrentworkspacetomonitor,${direction}"
              )
              directions);
        };
      };
    };
  };
}