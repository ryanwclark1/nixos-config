{
  config,
  lib,
  ...
}:
# let

  # remote = lib.getExe (pkgs.writeShellScriptBin "remote" ''
  #   socket="$(basename "$(find ~/.ssh -name 'administrator@*' | head -1 | cut -d ':' -f1)")"
  #   host="''${socket#master-}"
  #   ssh "$host" "$@"
  # '');
# in
{
  wayland.windowManager.hyprland.settings = {
    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];

    bind =
      [
        "SUPER, q, killactive" # Kill active window
        "ALT, F4, killactive"  # Kill active window
        "SUPER SHIFT, e, exit"

        "SUPER SHIFT, space, togglefloating"

        "SUPER, minus, splitratio,-0.25"
        "SUPER,equal, splitratio,0.25"

        # "SUPER SHIFT, minus,splitratio,-0.3333333"
        # "SUPER SHIFT, equal,splitratio,0.3333333"

        "SUPER, g, togglegroup"
        "SUPER, t, lockactivegroup, toggle"

        "SUPER, apostrophe, workspace, previous"
        "SUPER SHIFT, apostrophe, workspace, next"

        "SUPER, u, togglespecialworkspace"
        "SUPER SHIFT, u, movetoworkspacesilent, special"
        "SUPER, i, pseudo"
      ] ++
      ([
        # Program bindings
        "SUPER, S, exec, screenshooting"  # Area selection by default
        "SUPER, e, exec, code"
        "SUPER, b,  exec, handlr launch x-scheme-handler/https"
        "SUPER ALT, space, exec, nautilus"
        "SUPER, backspace, exec, wlogout"
        # "SUPER ALT,Return, exec,${remote} ${defaultApp "x-scheme-handler/terminal"}"
        # "SUPER ALT,e, exec,${remote} ${defaultApp "text/plain"}"
        # "SUPER ALT,b, exec,${remote} ${defaultApp "x-scheme-handler/https"}"
        "SUPER, Return, exec, ghostty" # xterm is a symlink, not actually xterm
      ]) ++
      # Media control
      (
        lib.optionals config.services.playerctld.enable [
          # Media control
          ",XF86AudioNext, exec, playerctl next"
          ",XF86AudioPrev, exec, playerctl previous"
          ",XF86AudioPlay, exec, playerctl play-pause"
          ",XF86AudioStop, exec, playerctl stop"
          "SHIFT,XF86AudioNext, exec, playerctld shift"
          "SHIFT,XF86AudioPrev, exec, playerctld unshift"
          "SHIFT,XF86AudioPlay, exec, systemctl --user restart playerctld"
        ]
      ) ++
      # Brightness control
      ([
          ",XF86MonBrightnessUp, exec, brightnessctl -q set +10%"
          ",XF86MonBrightnessDown, exec, brightnessctl -q set 10%-"
      ])
      ++
      # Volume control
      ([
        ",XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        "SHIFT,XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SOURCE@ 5%+"
        "SHIFT,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-"
        "SHIFT,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ]) ++
      # Screen lock
      # (
      #   let
      #     hyprlock = lib.getExe config.programs.hyprlock.package;
      #   in
      #   lib.optionals config.programs.hyprlock.enable [
      #     "SUPER,backspace, exec,${config.home.homeDirectory}/.config/rofi/scripts/powermenu_t4"
      #     "SUPER,XF86Calculator, exec,${config.home.homeDirectory}/.config/rofi/scripts/powermenu_t4"
      #   ]
      # )
      # ++
      # Notification manager
      # (
      #   let
      #     makoctl = lib.getExe' config.services.mako.package "makoctl";
      #   in
      #     lib.optionals config.services.mako.enable [
      #       "SUPER,w, exec,${makoctl} dismiss"
      #       "SUPER SHIFT,w, exec,${makoctl} restore"
      #     ]
      # )
      # ++
      # Launcher
      (
        lib.optionals config.programs.rofi.enable [
          "SUPER, x, exec, rofi -show drun -theme ${config.home.homeDirectory}/.config/rofi/style/launcher-center.rasi"
          "SUPER, z, exec, rofi -show drun -theme ${config.home.homeDirectory}/.config/rofi/style/launcher-full.rasi"
          "SUPERSHIFT, W, exec,web-search"
        ] ++
        (
          lib.optionals config.services.cliphist.enable [
            ''SUPER, c, exec,selected=$(cliphist list | rofi -dmenu -theme ${config.home.homeDirectory}/.config/rofi/style/cliphist.rasi) | cliphist decode | wl-copy''
          ]
        )
      ) ++
      # Screenshot and OCR
      ([
        ", Print, exec, screenshooting"  # Area selection
        "SHIFT, Print, exec, screenshooting screen"  # Full screen
        "CTRL, Print, exec, screenshooting window"  # Active window
        "ALT, Print, exec, grimblast --freeze save area - | tesseract - - | wl-copy && notify-send -t 3000 'OCR result copied to buffer'"
      ]) ++
      (
        let
          screenshot = "screenshooting";
          binding = mod: cmd: key: arg: "${mod}, ${key}, ${cmd}, ${arg}";
          mvfocus = binding "SUPER" "movefocus";
          ws = binding "SUPER" "workspace";
          resizeactive = binding "SUPER CTRL" "resizeactive";
          mvactive = binding "SUPER ALT" "moveactive";
          mvtows = binding "SUPER SHIFT" "movetoworkspace";
          e = "exec, ags request --instance hyprpanel";
          arr = [1 2 3 4 5 6 7 8 9];
        in
        [
          "CTRL SHIFT, R, ${e} quit; ags -b hypr"
          "SUPER, R, ${e} -t launcher"
          "SUPER, Tab, ${e} -t overview"
          ", XF86PowerOff, ${e} -r 'powermenu.shutdown()'"
          ", XF86Launch4, ${e} -r 'recorder.start()'"
          # Additional screenshot bindings (duplicates removed since we have them above)

          "ALT, Tab, focuscurrentorlast"
          "CTRL ALT, Delete, exit"
          "ALT, Q, killactive"
          "SUPER, F, togglefloating"
          # "SUPER, G, fullscreen"
          # "SUPER, O, fakefullscreen"
          "SUPER, P, togglesplit"
          "SUPER, G,fullscreen,1"
          "SUPER SHIFT, G,fullscreen,0"

          (mvfocus "k" "u")
          (mvfocus "j" "d")
          (mvfocus "l" "r")
          (mvfocus "h" "l")
          (ws "left" "e-1")
          (ws "right" "e+1")
          (mvtows "left" "e-1")
          (mvtows "right" "e+1")
          (resizeactive "k" "0 -20")
          (resizeactive "j" "0 20")
          (resizeactive "l" "20 0")
          (resizeactive "h" "-20 0")
          (mvactive "k" "0 -20")
          (mvactive "j" "0 20")
          (mvactive "l" "20 0")
          (mvactive "h" "-20 0")
        ]
        ++ (map (i: ws (toString i) (toString i)) arr)
        ++ (map (i: mvtows (toString i) (toString i)) arr)
      );
      # ++
      # # Bindings for moving windows and workspaces
      # (
      #   let
      #     workspaces = [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" ];
      #     # Map keys (arrows and hjkl) to hyprland directions (l, r, u, d)
      #     directions = rec {
      #         left = "l";
      #         right = "r";
      #         up = "u";
      #         down = "d";
      #         h = left;
      #         l = right;
      #         k = up;
      #         j = down;
      #     };
      #   in
      #   # Change workspace
      #   (map (n: "SUPER,${n},workspace,name:${n}") workspaces)
      #   ++
      #   # Move window to workspace
      #   (map (n: "SUPER SHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)
      #   ++
      #   # Move focusWallpaper managers (hyprpaper, waypaper)
      #   (lib.mapAttrsToList (key: direction: "SUPER,${key},movefocus,${direction}") directions)
      #   ++
      #   # Swap windows
      #   (lib.mapAttrsToList (key: direction: "SUPER SHIFT,${key},swapwindow,${direction}") directions)
      #   ++
      #   # Move windows
      #   (lib.mapAttrsToList (key: direction: "SUPER CONTROL,${key},movewindoworgroup,${direction}") directions)
      #   ++
      #   # Move monitor focus
      #   (lib.mapAttrsToList (key: direction: "SUPER ALT,${key},focusmonitor,${direction}") directions)
      #   ++
      #   # Move workspace to other monitor
      #   (lib.mapAttrsToList (key: direction: "SUPER ALT SHIFT,${key},movecurrentworkspacetomonitor,${direction}") directions)
      # );
  };
}
