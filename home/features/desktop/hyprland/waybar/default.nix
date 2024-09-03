{
  config,
  lib,
  pkgs,
  ...
}:
with config.lib.stylix.colors.withHashtag;

let
  cat = "${pkgs.coreutils}/bin/cat";
  cliphist = "${pkgs.cliphist}/bin/cliphist";
  hypridle = lib.getExe config.services.hypridle.package;
  hyprlock = lib.getExe config.programs.hyprlock.package;
  kitty = "${pkgs.kitty}/bin/kitty";
  missioncenter = "${pkgs.mission-center}/bin/missioncenter";
  nm-connection = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
  nmtui = "${pkgs.networkmanager}/bin/nmtui";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  rofi = "${pkgs.rofi}/bin/rofi";
  chrome = "${pkgs.google-chrome}/bin/google-chrome-stable";
  firefox = lib.getExe config.programs.firefox.package;
  # thunar = "${pkgs.thunar}/bin/thunar";
in
{
  home = {
    file.".config/waybar/themes" = {
      source = ./themes;
      recursive = true;
    };
    file.".config/waybar/scripts" = {
      source = ./scripts;
      recursive = true;
    };
  };

  home.packages = with pkgs; [
    networkmanagerapplet
    mission-center
  ];

  programs = {
    waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [{
        layer = "top";
        position = "top";
        # mode = "overlay";
        # exclusive = false;
        fixed-center = true;
        # passthrough = true;
        reload_style_on_change = true; # Testing
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        # modules-center = [ "network" "pulseaudio" "cpu" "custom/gpu"  "memory" "disk" "clock" "battery"];
        modules-right = [
          "group/hardware"
          "battery"
          "custom/speaker"
          "custom/mic"
          "bluetooth"
          "custom/exit"
        ];

        backlight = {
          format = "{icon} {percentage}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
          scroll-step = 1;
        };

        battery = {
          bat = "BAT0";
          interval = 10;
          states = {
            good = 95;
            warning = 20;
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = " {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          on-click = "";
          tooltip = false;
        };

        # Bluetooth
        bluetooth = {
          format = "";
          format-disabled = "󰂲";
          format-off = "";
          interval = 30;
          on-click = "blueman-manager";
          format-no-controller = "";
        };

        clock = {
          format = "{:%H:%M}";
          interval = 60;
          max-length = 25;
          # format = "{:%d/%m %H:%M:%S}";
          format-alt = "{:%Y-%m-%d %H:%M:%S}";
          on-click-left = "mode";
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
          calendar = {
            "mode" = "year";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            "format" = {
              "months" = "<span color='${base07}'><b>{}</b></span>";
              "days" = "<span color='${base05}'><b>{}</b></span>";
              "weekdays" = "<span color='${base0A}'><b>{}</b></span>";
              "today" = "<span color='${base08}'><b><u>{}</u></b></span>";
            };
          };
          "actions" = {
            "on-click-right" = "mode";
            "on-click-forward" = "tz_up";
            "on-click-backward" = "tz_down";
            "on-scroll-up" = "shift_up";
            "on-scroll-down" = "shift_down";
          };
        };

        cpu = {
          interval = 5;
          format = " {usage}%";
          tooltip = true;
          on-click = "${missioncenter}";
        };

        "custom/chatgpt" = {
          format = "";
          on-click = "";
          tooltip-format = "AI Support";
        };

        # Cliphist
        "custom/cliphist" = {
          format = "";
          on-click = "sleep 0.1 && ${cliphist} list | ${rofi} -demu -theme ${config.xdg.configHome}/rofi/style/cliphist | ${cliphist} delete";
          on-click-right = "sleep 0.1 && ${cliphist} list | ${rofi} -demu -theme ${config.xdg.configHome}/rofi/style/cliphist | ${cliphist} decode | wl-copy";
          on-click-middle = "${cliphist} wipe";
          tooltip-format = "Clipboard Manager";
        };

        # Power Menu
        "custom/exit" = {
          format = "";
          on-click = "${config.xdg.configHome}/rofi/scripts/power-big.sh";
          tooltip-format = "Power Menu";
        };

        "custom/gpu" = {
            interval = 20;
            exec = "${cat} /sys/class/drm/card0/device/gpu_busy_percent";
            format = "󰢮 {}%";
            tooltip = true;
            on-click = "${missioncenter}";
        };

        # Hypridle inhibitor
        "custom/hypridle" = {
          format = "";
          return-type = "json";
          escape = true;
          exec-on-event = true;
          interval = 60;
          exec = "${config.xdg.configHome}/hypr/scripts/hypridle.sh status";
          on-click = "${config.xdg.configHome}/hypr/scripts/hypridle.sh toggle";
          on-click-right = "${hyprlock}";
        };

        "custom/speaker" = {
          tooltip =false;
          max-length = 7;
          exec = "${config.xdg.configHome}/waybar/scripts/speaker.sh";
          on-click = "${pavucontrol}";
        };

        "custom/mic" = {
          tooltip = false;
          max-length = 7;
          exec = "${config.xdg.configHome}/waybar/scripts/mic.sh";
          on-click = "${pavucontrol}";
        };

        "custom/system" = {
          format = " 󰇅 ";
          tooltip = true;
          tooltip-format = "System Information";
          on-click = "${missioncenter}";
        };

        disk = {
          interval = 60;
          format = " {free}";
          tooltip = true;
          on-click = "${missioncenter}";
        };

        "hyprland/window" = {
          max-length = 60;
          separate-outputs = false;
        };

        # "hyprland/window" = {
        #   rewrite = {
        #     (.*) - Brave = "$1";
        #     (.*) - Chromium = "$1";
        #     (.*) - Brave Search = "$1";
        #     (.*) - Outlook = "$1";
        #     (.*) Microsoft Teams = "$1"
        #   };
        #   separate-outputs = true
        # };

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            default = "";
            active = "";
            urgent = "";
          };
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        # Group Hardware
        "group/hardware" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            children-class = "child-hardware";
            transition-left-to-right = false;
          };
          modules = [
            "custom/system"
            "disk"
            "cpu"
            # "custom/gpu"
            "memory"
            # "hyprland/language"
          ];
        };

        # Group Links
        "group/links" = {
          orientation = "horizontal";
          modules = [
            "custom/chatgpt"
            "custom/empty"
          ];
        };

        # Group Settings
        "group/settings" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            children-class = "child-settings";
            transition-left-to-right = true;
          };
          modules = [
            "custom/settings"
            "custom/waybarthemes"
            "custom/wallpaper"
          ];
        };

        # Group Tools
        "group/tools" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            children-class = "child-tools";
            transition-left-to-right = false;
          };
          modules = [
            "custom/tools"
            "custom/cliphist"
            "custom/hypridle"
            "custom/hyprshade"
          ];
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰒳";
            deactivated = "󰒲";
          };
        };

        memory = {
          interval = 5;
          format = " {}%";
          tooltip = true;
          on-click = "${missioncenter}";
        };

        network = {
          interval = 3;
          format = "{ifname}";
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format-ethernet = "󰈁 Connected";
          format-wifi = "{icon} {signalStrength}% {essid}";
          format-disconnected = "󰤮";
          # tooltip = true;
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}
          '';
          tooltip-format-ethernet = ''
             {ifname}
            IP: {ipaddr}
            : {bandwidthUpBits} : {bandwidthDownBits}
          '';
          tooltip-format-disconnected = "Disconnected";
          tooltip-format-wifi = ''
              {ifname} @ {essid}
            IP: {ipaddr}
            Strength: {signalStrength}%
            Freq: {frequency}MHz
            : {bandwidthUpBits} : {bandwidthDownBits}
          '';
          max-length = 50;
          on-click = "${kitty} -e ${nmtui}";
          on-click-right = "${nm-connection}";
        };

        # Audio
        pulseaudio = {
          format = "{icon} {volume}% {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = "{format_source}";
          format-source = " {volume}%";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = [ "" " " " " ];
          };
          on-click = "${pavucontrol}";
          tooltip-format = "{source_volume}% / {desc}";
        };

        # System tray
        tray = {
          icon-size = 21;
          spacing = 10;
        };

        user = {
          format = "{user}";
          interval = 60;
          icon = false;
        };

        "custom/chrome" = {
            "format" = "";
            "on-click" = "${chrome}";
            "tooltip-format" = "Open Chromium";
        };
        "custom/firecox" = {
            "format" = "";
            "on-click" = "${firefox}";
            "tooltip-format" = "Open Firefox";
        };
        "custom/thunar" = {
            "format" = "";
            "on-click" = "thunar";
            # "on-click" = "${thunar}";
            "tooltip-format" = "Open filemanager";
        };
        "custom/quicklinkempty" = {
        };
        "group/quicklinks" = {
            orientation = "horizontal";
            modules = [
                "custom/chrome"
                "custom/firefox"
                "custom/quicklinkempty"
                "custom/thunar"
            ];
        };



        # "custom/notification" = {
        #   tooltip = true;
        #   format = "{icon} {}";
        #   format-icons = {
        #     notification = "<span foreground='red'><sup></sup></span>";
        #     none = "";
        #     dnd-notification = "<span foreground='red'><sup></sup></span>";
        #     dnd-none = "";
        #     inhibited-notification = "<span foreground='red'><sup></sup></span>";
        #     inhibited-none = "";
        #     dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
        #     dnd-inhibited-none = "";
        #   };
        #   return-type = "json";
        #   exec-if = "which swaync-client";
        #   exec = "swaync-client -swb";
        #   on-click = "task-waybar";
        #   escape = true;
        # };
      }];

        # @background #1E1D2FFF;
        # @backgroundalt #282839FF;
        # @foreground #D9E0EEFF;
        # @selected #7AA2F7FF;
        # @active #ABE9B3FF;
        # @urgent #F28FADFF;

      style =
      ''

        * {
          font-size: 12px;
          font-family: JetBrainsMono Nerd Font, Font Awesome, sans-serif;
          font-weight: bold;
        }

        window#waybar {
          background-color: @background;
          border-bottom: 0px solid #ffffff;
          color: #e5e9f0;
          transition-property: background-color;
          transition-duration: 0.5s;
          opacity: 0.5;
        }

        .modules-right {
          padding: 0 10px 0 10px;
          /* margin: 0px 10px 0px 10px; */
          border-radius: 0px;
          background: #2e3440;
          /* opacity: 0.7; */
        }

        .modules-center {
          padding: 0 10px 0 10px;
          /* margin: 0px 10px 0px 10px; */
          border-radius: 0px;
          background: #2e3440;
          /* opacity: 0.7; */
        }

        .modules-left {
          padding: 0 10px 0 10px;
          /* margin: 0px 10px 0px 10px; */
          border-radius: 0px;
          background: #2e3440;
          /* opacity: 0.7; */
        }

        #hyprland-workspaces {
          border-radius: 0px;
          padding: 0 1px;
        }

        #workspaces button {
          min-width: 5px;
        }

        #custom-exit,
        #battery,
        #custom-system,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #wireplumber,
        #custom-media,
        #tray,
        #mode,
        #idle_inhibitor,
        #scratchpad,
        #mpd {
          margin: 0px;
          padding: 0 10px 0 10px;
          color: #ffffff;
          font-size: 14px;
        }

        #clock {
          margin: 0px;
          padding: 0 10px 0 10px;
          color: #ffffff;
          font-size: 16px;
          font-weight: bold;
        }

        #clock.calendar {
          font-size: 16px;
        }

        #custom-speaker,
        #custom-mic {
          margin: 0px;
          padding: 0 10px 0 10px;
          font-size: 14px;
          color: #ffffff;
        }

        #bluetooth {
          margin: 0px;
          padding: 0 10px 0 10px;
          color: #ffffff;
          font-size: 16px;
          font-weight: bold;
        }

        #group-hardware {
          margin: 0px;
          padding: 0 10px 0 10px;
          color: #ffffff;
          font-size: 16px;
          font-weight: bold;
        }

        #disk {
          margin: 0px;
          padding: 0 10px 0 10px;
          font-size: 13px;
          color: #ffffff;
        }

        #cpu,
        #memory,
        #custom-gpu {
          margin: 0px;
          padding: 0 10px 0 10px;
          font-size: 14px;
          color: #ffffff;
        }

        #custom-exit {
          padding-right: 15px;
        }
      '';
    };
  };
}
