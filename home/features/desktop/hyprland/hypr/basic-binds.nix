{
  config,
  lib,
  pkgs,
  ...
}:

{
  wayland.windowManager.hyprland.settings = {
    # Mouse bindings
    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];

    bind = lib.flatten [
      # Window management
      [
        "SUPER, Q, killactive"
        "ALT, F4, killactive"
        "SUPER SHIFT, E, exit"
        "SUPER SHIFT, SPACE, togglefloating"
        "SUPER, F, fullscreen, 1"
        "SUPER SHIFT, F, fullscreen, 0"
        "SUPER, P, togglesplit"
        "SUPER, G, togglegroup"
        "SUPER, T, lockactivegroup, toggle"
        "SUPER, I, pseudo"
      ]

      # Window sizing
      [
        "SUPER, minus, splitratio, -0.1"
        "SUPER, equal, splitratio, 0.1"
        "SUPER SHIFT, minus, splitratio, -0.2"
        "SUPER SHIFT, equal, splitratio, 0.2"
      ]

      # Workspace navigation
      [
        "SUPER, Tab, workspace, e+1"
        "SUPER SHIFT, Tab, workspace, e-1"
        "SUPER, apostrophe, workspace, previous"
        "SUPER, mouse_down, workspace, e+1"
        "SUPER, mouse_up, workspace, e-1"
      ]

      # Special workspace
      [
        "SUPER, U, togglespecialworkspace, scratchpad"
        "SUPER SHIFT, U, movetoworkspace, special:scratchpad"
      ]

      # Applications
      [
        "SUPER, Return, exec, kitty"
        "SUPER, E, exec, code"
        "SUPER, B, exec, google-chrome-stable"
        "SUPER, N, exec, nautilus"
        "SUPER ALT, SPACE, exec, nautilus"
      ]

      # Rofi menus
      (lib.optionals config.programs.rofi.enable [
        "SUPER, SPACE, exec, rofi -show drun -theme ${config.home.homeDirectory}/.config/rofi/style/launcher-center.rasi"
        "SUPER, X, exec, rofi -show drun -theme ${config.home.homeDirectory}/.config/rofi/style/launcher-center.rasi"
        "SUPER, Z, exec, rofi -show drun -theme ${config.home.homeDirectory}/.config/rofi/style/launcher-full.rasi"
        "SUPER SHIFT, W, exec, web-search"
        "SUPER, V, exec, cliphist list | rofi -dmenu -theme ${config.home.homeDirectory}/.config/rofi/style/cliphist.rasi | cliphist decode | wl-copy"
      ])

      # Screenshot
      [
        ", Print, exec, screenshooting"
        "SHIFT, Print, exec, screenshooting screen"
        "CTRL, Print, exec, screenshooting window"
        "ALT, Print, exec, grimblast --freeze save area - | tesseract - - | wl-copy && notify-send -t 3000 'OCR result copied to buffer'"
        "SUPER, S, exec, screenshooting"
        "SUPER SHIFT, S, exec, rofi -dmenu -theme ${config.home.homeDirectory}/.config/rofi/scripts/screenshot.sh"
      ]

      # Power menu
      [
        "SUPER, Escape, exec, wlogout"
        "SUPER, BackSpace, exec, wlogout"
      ]

      # Movement (vim keys)
      (let
        mvfocus = dir: "SUPER, ${dir}, movefocus, ${dir}";
        mvwindow = dir: "SUPER SHIFT, ${dir}, movewindow, ${dir}";
        resizeactive = (dir: amount: "SUPER CTRL, ${dir}, resizeactive, ${amount}");
      in [
        (mvfocus "H") (mvfocus "L") (mvfocus "K") (mvfocus "J")
        (mvfocus "left") (mvfocus "right") (mvfocus "up") (mvfocus "down")
        (mvwindow "H") (mvwindow "L") (mvwindow "K") (mvwindow "J")
        (mvwindow "left") (mvwindow "right") (mvwindow "up") (mvwindow "down")
        (resizeactive "H" "-20 0") (resizeactive "L" "20 0")
        (resizeactive "K" "0 -20") (resizeactive "J" "0 20")
        (resizeactive "left" "-20 0") (resizeactive "right" "20 0")
        (resizeactive "up" "0 -20") (resizeactive "down" "0 20")
      ])

      # Workspace switching (numbers)
      (builtins.concatLists (builtins.genList (
        i: let
          ws = toString (i + 1);
        in [
          "SUPER, ${ws}, workspace, ${ws}"
          "SUPER SHIFT, ${ws}, movetoworkspace, ${ws}"
        ]
      ) 9))

      # Workspace switching (numpad)
      (builtins.concatLists (builtins.genList (
        i: let
          ws = toString (i + 1);
        in [
          "SUPER, KP_${ws}, workspace, ${ws}"
          "SUPER SHIFT, KP_${ws}, movetoworkspace, ${ws}"
        ]
      ) 9))

      # Function keys
      [
        "SUPER, F1, exec, ${config.home.homeDirectory}/.config/hypr/scripts/keybindings.sh"
      ]

      # Media keys
      (lib.optionals config.services.playerctld.enable [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioStop, exec, playerctl stop"
        "SHIFT, XF86AudioNext, exec, playerctld shift"
        "SHIFT, XF86AudioPrev, exec, playerctld unshift"
        "SHIFT, XF86AudioPlay, exec, systemctl --user restart playerctld"
      ])

      # Volume control
      [
        ", XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        "SHIFT, XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SOURCE@ 5%+"
        "SHIFT, XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-"
        "SHIFT, XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ]

      # Brightness control
      [
        ", XF86MonBrightnessUp, exec, brightnessctl -q set +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl -q set 10%-"
      ]

      # Plugin bindings
      [
        "SUPER ALT, grave, hyprexpo:expo, toggle"
      ]
    ];
  };
}
