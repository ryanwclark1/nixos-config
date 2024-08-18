{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;

    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
    ];
    settings = {
      general = {
        gaps_in = 15;
        gaps_out = 20;
        border_size = 2.7;
        cursor_inactive_timeout = 4;
        # "col.active_border" = "0xff${config.colorscheme.palette.base0C}";
        # "col.inactive_border" = "0xff${config.colorscheme.palette.base02}";
      };
      group = {
        # "col.border_active" = "0xff${config.colorscheme.palette.base0B}";
        # "col.border_inactive" = "0xff${config.colorscheme.palette.base04}";
        groupbar = {
          font_size = 11;
        };
      };
      input = {
        kb_layout = "us";
      };
      dwindle.split_width_multiplier = 1.35;
      misc = {
        vfr = true;
        close_special_on_empty = true;
        # Unfullscreen when opening something
        new_window_takes_over_fullscreen = 2;
      };
      layerrule = [
        "blur,waybar"
        "ignorezero,waybar"
      ];
      decoration = {
        active_opacity = 0.97;
        inactive_opacity = 0.77;
        fullscreen_opacity = 1.0;
        rounding = 7;
        blur = {
          enabled = true;
          size = 5;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };
        drop_shadow = true;
        shadow_range = 12;
        shadow_offset = "3 3";
        # "col.shadow" = "0x44000000";
        # "col.shadow_inactive" = "0x66000000";
      };
      animations = {
        enabled = true;
        bezier = [
          "easein,0.11, 0, 0.5, 0"
          "easeout,0.5, 1, 0.89, 1"
          "easeinback,0.36, 0, 0.66, -0.56"
          "easeoutback,0.34, 1.56, 0.64, 1"
        ];
        animation = [
          "windowsIn,1,3,easeoutback,slide"
          "windowsOut,1,3,easeinback,slide"
          "windowsMove,1,3,easeoutback"
          "workspaces,1,2,easeoutback,slide"
          "fadeIn,1,3,easeout"
          "fadeOut,1,3,easein"
          "fadeSwitch,1,3,easeout"
          "fadeShadow,1,3,easeout"
          "fadeDim,1,3,easeout"
          "border,1,3,easeout"
        ];
      };
      "plugin:hyprbars" = {
        bar_height = 25;
        # bar_color = "0xdd${config.colorscheme.palette.base00}";
        # "col.text" = "0xee${config.colorscheme.palette.base05}";
        # bar_text_font = config.fontProfiles.regular.family;
        # bar_text_size = 12;
        bar_part_of_window = true;
        hyprbars-button =
          let
            closeAction = "hyprctl dispatch killactive";
            isOnSpecial = ''hyprctl activewindow -j | jq -re 'select(.workspace.name == "special")' >/dev/null'';
            moveToSpecial = "hyprctl dispatch movetoworkspacesilent special";
            moveToActive = "hyprctl dispatch movetoworkspacesilent name:$(hyprctl -j activeworkspace | jq -re '.name')";
            minimizeAction = "${isOnSpecial} && ${moveToActive} || ${moveToSpecial}";
            maximizeAction = "hyprctl dispatch togglefloating";
          in
          [
            # Red close button
            "rgb(255, 87, 51),12,,${closeAction}"
            # Yellow "minimize" (send to special workspace) button
            "rgb(255, 195, 0),12,,${minimizeAction}"
            # Green "maximize" (togglefloating) button
            "rgb(218, 247, 166),12,,${maximizeAction}"
          ];
      };
      bind =
        let
          swaylock = "${config.programs.swaylock.package}/bin/swaylock";
          playerctl = "${config.services.playerctld.package}/bin/playerctl";
          playerctld = "${config.services.playerctld.package}/bin/playerctld";
          makoctl = "${config.services.mako.package}/bin/makoctl";
          rofi = "${config.programs.rofi.package}/bin/rofi";
          # grimblast = "${pkgs.inputs.hyprwm-contrib.grimblast}/bin/grimblast";
          pactl = "${pkgs.pulseaudio}/bin/pactl";
          # gtk-play = "${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play";
          # notify-send = "${pkgs.libnotify}/bin/notify-send";

          gtk-launch = "${pkgs.gtk3}/bin/gtk-launch";
          xdg-mime = "${pkgs.xdg-utils}/bin/xdg-mime";
          defaultApp = type: "${gtk-launch} $(${xdg-mime} query default ${type})";

          # terminal = config.home.sessionVariables.TERMINAL;
          terminal = "${pkgs.kitty}/bin/kitty";
          browser = defaultApp "x-scheme-handler/https";
          editor = defaultApp "text/plain";
          barsEnabled = "hyprctl -j getoption plugin:hyprbars:bar_height | ${lib.getExe pkgs.jq} -re '.int != 0'";
          setBarHeight = height: "hyprctl keyword plugin:hyprbars:bar_height ${toString height}";
          toggleOn = setBarHeight config.wayland.windowManager.hyprland.settings."plugin:hyprbars".bar_height;
          toggleOff = setBarHeight 0;
        in
        [
          # Bar toggle
          "SUPER,m,exec,${barsEnabled} && ${toggleOff} || ${toggleOn}"
          # Program bindings
          "SUPER,Return,exec,${terminal}"
          "SUPER,e,exec,${editor}"
          "SUPER,v,exec,${editor}"
          "SUPER,b,exec,${browser}"
          # Brightness control (only works if the system has lightd)
          ",XF86MonBrightnessUp,exec,light -A 10"
          ",XF86MonBrightnessDown,exec,light -U 10"
          # Volume
          ",XF86AudioRaiseVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
          ",XF86AudioLowerVolume,exec,${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
          ",XF86AudioMute,exec,${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
          "SHIFT,XF86AudioMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
          ",XF86AudioMicMute,exec,${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
          # Screenshotting
          # ",Print,exec,${grimblast} --notify --freeze copy output"
          # "SHIFT,Print,exec,${grimblast} --notify --freeze copy active"
          # "CONTROL,Print,exec,${grimblast} --notify --freeze copy screen"
          # "SUPER,Print,exec,${grimblast} --notify --freeze copy area"
          # "ALT,Print,exec,${grimblast} --notify --freeze copy area"
          # Tally counter
          # "SUPER,z,exec,${notify-send} -t 1000 $(${tly} time) && ${tly} add && ${gtk-play} -i dialog-information" # Add new entry
          # "SUPERCONTROL,z,exec,${notify-send} -t 1000 $(${tly} time) && ${tly} undo && ${gtk-play} -i dialog-warning" # Undo last entry
          # "SUPERCONTROLSHIFT,z,exec,${tly} reset && ${gtk-play} -i complete" # Reset
          # "SUPERSHIFT,z,exec,${notify-send} -t 1000 $(${tly} time)" # Show current time
        ] ++
        (lib.optionals config.services.playerctld.enable [
          # Media control
          ",XF86AudioNext,exec,${playerctl} next"
          ",XF86AudioPrev,exec,${playerctl} previous"
          ",XF86AudioPlay,exec,${playerctl} play-pause"
          ",XF86AudioStop,exec,${playerctl} stop"
          "ALT,XF86AudioNext,exec,${playerctld} shift"
          "ALT,XF86AudioPrev,exec,${playerctld} unshift"
          "ALT,XF86AudioPlay,exec,systemctl --user restart playerctld"
        ]) ++
        # Screen lock
        (lib.optionals config.programs.swaylock.enable [
          ",XF86Launch5,exec,${swaylock} -S --grace 2"
          ",XF86Launch4,exec,${swaylock} -S --grace 2"
          "SUPER,backspace,exec,${swaylock} -S --grace 2"
        ]) ++
        # Notification manager
        (lib.optionals config.services.mako.enable [
          "SUPER,w,exec,${makoctl} dismiss"
        ]) ++

        # Launcher
        (lib.optionals config.programs.rofi.enable [
          "SUPER,x,exec,${rofi} -S drun -x 10 -y 10 -W 25% -H 60%"
          "SUPER,d,exec,${rofi} -S run"
        ] ++ (lib.optionals config.programs.password-store.enable [
          # ",Scroll_Lock,exec,${pass-rofi}" # fn+k
          # ",XF86Calculator,exec,${pass-rofi}" # fn+f12
          "SUPER,semicolon,exec,pass-rofi"
        ]));

    };
    # This is order sensitive, so it has to come here.
    extraConfig = ''
      # Passthrough mode (e.g. for VNC)
      bind=SUPER,P,submap,passthrough
      submap=passthrough
      bind=SUPER,P,submap,reset
      submap=reset
    '';
  };
}