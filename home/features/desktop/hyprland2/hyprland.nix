{
  config,
  lib,
  pkgs,
  ...
}:
let
	cat = "${pkgs.coreutils}/bin/cat";
	pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
	kitty = "${pkgs.kitty}/bin/kitty";
	nmtui = "${pkgs.networkmanager}/bin/nmtui";
in
{


  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      plugins = [ pkgs.rofi-calc pkgs.rofi-emoji ];
      extraConfig = {
        bw = 1;
        columns = 2;
        icon-theme = "Papirus-Dark";
      };
      extraConfig = {
        modi = "drun,emoji,calc";
        show-icons = true;
        drun-display-format = "{icon} {name}";
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-run = "   Run ";
        display-emoji = "   Emoji ";
        display-calc = "   Calc ";
        sidebar-mode = true;
      };
    };

    # fuzzel = {
    #   enable = true;
    #   package = pkgs.fuzzel;
    # };

    waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [
        {
          exclusive = true;
          layer = "top";
          position = "top";
          height = 18;
          passthrough = false;
          gtk-layer-shell = true;

          modules-left = [ "hyprland/window" ];
          modules-center = [ "network" "pulseaudio" "cpu" "custom/gpu" "hyprland/workspaces" "memory" "disk" "clock" "battery"];
          modules-right = [ "custom/notification" "tray" ];
          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              default = " ";
              active = " ";
              urgent = " ";
            };
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };
          clock = {
            format = "{: %I:%M %p}";
            interval = 1;
            # format = "{:%d/%m %H:%M:%S}";
            format-alt = "{:%Y-%m-%d %H:%M:%S %z}";
            on-click-left = "mode";
            tooltip-format = ''
              <big>{:%Y %B}</big>
              <tt><small>{calendar}</small></tt>'';
          };
          "hyprland/window" = {
            max-length = 60;
            separate-outputs = false;
          };
          memory = {
            interval = 5;
            format = "  {}%";
            tooltip = true;
          };
          cpu = {
            interval = 5;
            format = "  {usage:2}%";
            tooltip = true;
          };
          "custom/gpu" = {
              interval = 5;
              exec = "${cat} /sys/class/drm/card0/device/gpu_busy_percent";
              format = "󰒋  {}%";
            };
          disk = {
            format = "  {free}";
            tooltip = true;
          };
          network = {
            interval = 3;
            format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
            format-ethernet = ": {bandwidthDownOctets} : {bandwidthUpOctets}";
            format-wifi = "{icon} {signalStrength}% {essid}";
            format-disconnected = "󰤮";
            tooltip = true;
            tooltip-format = ''
              {ifname}
              {ipaddr}/{cidr}
              Up: {bandwidthUpBits}
              Down: {bandwidthDownBits}
            '';
            max-length = 15;
            on-click = "${kitty} -e ${nmtui}";
          };
          "tray" = {
            spacing = 12;
          };
          pulseaudio = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = "   0%{format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              headset = "󰋎";
              phone = "";
              portable = "";
              car = "";
              default = [ "" "" "" ];
            };
            on-click = pavucontrol;
            tooltip-format = "{source_volume}% / {desc}";
          };
          "custom/notification" = {
            tooltip = true;
            format = "{icon} {}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "task-waybar";
            escape = true;
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "󰒳";
              deactivated = "󰒲";
            };
          };
          battery = {
            interval = 10;
            states = {
              good = 95;
              warning = 20;
              critical = 10;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󱘖 {capacity}%";
            format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            on-click = "";
            tooltip = false;
          };
        }
      ];
      style = ''
          * {
            font-size: 16px;
            font-family: JetBrainsMono Nerd Font, Font Awesome, sans-serif;
                font-weight: bold;
          }
          window#waybar {
                background-color: rgba(26,27,38,0);
                border-bottom: 1px solid rgba(26,27,38,0);
                border-radius: 0px;
                color: #f8f8f2;
          }
          #workspaces {
                background: linear-gradient(180deg, #414868, #24283b);
                margin: 5px;
                padding: 0px 1px;
                border-radius: 15px;
                border: 0px;
                font-style: normal;
                color: #15161e;
          }
          #workspaces button {
                padding: 0px 5px;
                margin: 4px 3px;
                border-radius: 15px;
                border: 0px;
                color: #15161e;
                background-color: #1a1b26;
                opacity: 1.0;
                transition: all 0.3s ease-in-out;
          }
          #workspaces button.active {
                color: #15161e;
                background: #7aa2f7;
                border-radius: 15px;
                min-width: 40px;
                transition: all 0.3s ease-in-out;
                opacity: 1.0;
          }
          #workspaces button:hover {
                color: #15161e;
                background: #7aa2f7;
                border-radius: 15px;
                opacity: 1.0;
          }
          tooltip {
              background: #1a1b26;
              border: 1px solid #7aa2f7;
              border-radius: 10px;
          }
          tooltip label {
              color: #c0caf5;
          }
          #window {
                color: #565f89;
                background: #1a1b26;
                border-radius: 0px 15px 50px 0px;
                margin: 5px 5px 5px 0px;
                padding: 2px 20px;
          }
          #memory {
                color: #2ac3de;
                background: #1a1b26;
                border-radius: 15px 50px 15px 50px;
                margin: 5px;
                padding: 2px 20px;
          }
          #clock {
                color: #c0caf5;
                background: #1a1b26;
                border-radius: 15px 50px 15px 50px;
                margin: 5px;
                padding: 2px 20px;
          }
          #cpu {
                color: #b4f9f8;
                background: #1a1b26;
                border-radius: 50px 15px 50px 15px;
                margin: 5px;
                padding: 2px 20px;
          }
          #custom-gpu {
                color: #ff9e64;
                background: #1a1b26;
                border-radius: 15px 50px 15px 50px;
                margin: 5px;
                padding: 2px 20px;
          }
          #disk {
                color: #9ece6a;
                background: #1a1b26;
                border-radius: 15px 50px 15px 50px;
                margin: 5px;
                padding: 2px 20px;
          }
          #battery {
                color: #f7768e;
                background: #1a1b26;
                border-radius: 15px;
                margin: 5px;
                padding: 2px 20px;
          }
          #network {
                color: #ff9e64;
                background: #1a1b26;
                border-radius: 50px 15px 50px 15px;
                margin: 5px;
                padding: 2px 20px;
          }
          #tray {
                color: #bb9af7;
                background: #1a1b26;
                border-radius: 15px 0px 0px 50px;
                margin: 5px 0px 5px 5px;
                padding: 2px 20px;
          }
          #pulseaudio {
                color: #bb9af7;
                background: #1a1b26;
                border-radius: 50px 15px 50px 15px;
                margin: 5px;
                padding: 2px 20px;
          }
          #custom-notification {
                color: #7dcfff;
                background: #1a1b26;
                border-radius: 15px 50px 15px 50px;
                margin: 5px;
                padding: 2px 20px;
          }
      '';
    };
  };

  wayland.windowManager.hyprland = {
    enable = lib.mkDefault true;
    # package = pkgs.hyprland;
    # package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    # plugins = [
    #   inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
    # ];
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
          barsEnabled = "hyprctl -j getoption plugin:hyprbars:bar_height | ${lib.getExe pkgs.jq} -re '.int != 0'";
          setBarHeight = height: "hyprctl keyword plugin:hyprbars:bar_height ${toString height}";
          toggleOn = setBarHeight config.wayland.windowManager.hyprland.settings."plugin:hyprbars".bar_height;
          toggleOff = setBarHeight 0;
        in
        [
          "SUPER,m,exec,${barsEnabled} && ${toggleOff} || ${toggleOn}"
        ];
    };
  };

  # services = {
  #   hyprpaper = {
  #     enable = true;
  #     package = pkgs.hyprpaper;
  #   };
  # };
}