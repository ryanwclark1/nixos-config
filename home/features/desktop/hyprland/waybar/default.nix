{
  config,
  lib,
  pkgs,
  ...
}:
with config.lib.stylix.colors.withHashtag;
with config.stylix.fonts;

let
  cat = "${pkgs.coreutils}/bin/cat";
  cliphist = "${pkgs.cliphist}/bin/cliphist";
  hypridle = lib.getExe config.services.hypridle.package;
  hyprlock = lib.getExe config.programs.hyprlock.package;
  alacritty = "${pkgs.alacritty}/bin/alacritty";
  missioncenter = "${pkgs.mission-center}/bin/missioncenter";
  nm-connection = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
  nmtui = "${pkgs.networkmanager}/bin/nmtui";
  pwvucontrol = "${pkgs.pwvucontrol}/bin/pwvucontrol";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  rofi = "${pkgs.rofi}/bin/rofi";
  chrome = "${pkgs.google-chrome}/bin/google-chrome-stable";
  firefox = lib.getExe config.programs.firefox.package;
  # thunar = "${pkgs.thunar}/bin/thunar";
  thunar = "thunar";
in
{

  # home =
  # {
  #   # file.".config/waybar/themes" = {
  #   #   source = ./themes;
  #   #   recursive = true;
  #   # };
  #   # file.".config/waybar/scripts" = {
  #   #   source = ./scripts;
  #   #   recursive = true;
  #   # };

  #   file.".config/waybar/scripts/update-checker.sh" = {
  #     text = ''
  #       #!/usr/bin/env bash

  #       #This script assumes your flake is in ~/nixos-config and that your flake's nixosConfigurations is named the same as your $hostname
  #       updates="$(cd ~/nixos-config && nix flake lock --update-input nixpkgs && nix build .#nixosConfigurations.$HOSTNAME.config.system.build.toplevel && nvd diff /run/current-system ./result | grep -e '\[U' | wc -l)"

  #       alt="has-updates"
  #       if [ $updates -eq 0 ]; then
  #           alt="updated"
  #       fi

  #       tooltip="System updated"
  #       if [ $updates != 0 ]; then
  #         tooltip=$(cd ~/nixos-config && nvd diff /run/current-system ./result | grep -e '\[U' | awk '{ for (i=3; i<NF; i++) printf $i " "; if (NF >= 3) print $NF; }' ORS='\\n' )
  #       fi

  #       echo "{ \"text\":\"$updates\", \"alt\":\"$alt\", \"tooltip\":\"$tooltip\" }"
  #     '';
  #     executable = true;
  #   };
  # };

  home.packages = with pkgs; [
    networkmanagerapplet
    mission-center
    qalculate-gtk
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
          "custom/applauncher"
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "group/hardware"
          "network"
          "battery"
          # "custom/speaker"
          "wireplumber"
          "custom/mic"
          "custom/hyprbindings"
          "custom/cliphist"
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
          bat = "BAT1";
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
            " "
            " "
            " "
            " "
            " "
          ];
          on-click = "";
          tooltip = false;
        };

        # Bluetooth
        bluetooth = {
          format = "";
          format-disabled = "󰂲";
          format-off = "";
          interval = 30;
          on-click = "blueman-manager";
          format-no-controller = "";
           tooltip-format = "Bluetooth";
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

        # Calculator
        "custom/calculator" = {
          format = "";
          on-click = "qalculate-gtk";
          tooltip-format = "Open calculator";
        };

        "custom/chatgpt" = {
          format = "";
          on-click = "";
          tooltip-format = "AI Support";
        };

        # Cliphist
        "custom/cliphist" = {
          format = "";
          on-click = "${config.home.homeDirectory}/.config/rofi/scripts/cliphist-copy.sh";
          on-click-right = "${config.home.homeDirectory}/.config/rofi/scripts/cliphist-delete.sh";
          on-click-middle = "${cliphist} wipe";
          tooltip-format = "Clipboard Manager";
        };

        # Power Menu
        "custom/exit" = {
          format = "";
          on-click = "${config.home.homeDirectory}/.config/rofi/scripts/power-big.sh";
          tooltip-format = "Power Menu";
        };

        "custom/gpu" = {
            interval = 20;
            exec = "${cat} /sys/class/drm/card0/device/gpu_busy_percent";
            format = "󰢮 {}%";
            tooltip = true;
            on-click = "${missioncenter}";
        };

        "custom/hyprbindings" = {
          tooltip = false;
          format = "󱕴";
          on-click = "sleep 0.1 && ${config.home.homeDirectory}/.config/hypr/scripts/list-hypr-bindings.sh";
        };

        # Hypridle inhibitor
        "custom/hypridle" = {
          format = "";
          return-type = "json";
          escape = true;
          exec-on-event = true;
          interval = 60;
          exec = "${config.home.homeDirectory}/.config/hypr/scripts/hypridle.sh status";
          on-click = "${config.home.homeDirectory}/.config/hypr/scripts/hypridle.sh toggle";
          on-click-right = "${hyprlock}";
        };

        "custom/logo" = {
          exec = "echo ' '";
          format = "{}";
        };

        "custom/speaker" = {
          tooltip = true;
          max-length = 7;
          exec = "${config.home.homeDirectory}/.config/waybar/scripts/speaker.sh";
          on-click = "${pwvucontrol}";
        };

        "custom/mic" = {
          # tooltip = true;
          exec = "microphone-status";
          # exec = "${pkgs.microphone-status}/bin/microphone-status";
          interval = 1;
          on-click = "${pwvucontrol}";
          format = "{}";
        };

        "custom/system" = {
          format = "󰇅";
          tooltip = true;
          tooltip-format = "System Information";
          on-click = "${missioncenter}";
        };

        "custom/nix-updates" = {
            exec = "update-checker";
            on-click = "update-checker && notify-send 'The system has been updated'"; # refresh on click
            interval = 3600; # refresh every hour
            tooltip = true;
            return-type = "json";
            format = "{} {icon}";
            format-icons = {
                has-updates = ""; # icon when updates needed
                updated = ""; # icon when all packages updated
            };
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
          # format = "{ifname}";
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format-ethernet = "";
          # format-wifi = "{icon}  {signalStrength}% {essid}";
          format-wifi = "{icon}";
          format-disconnected = "󰤮";
          # tooltip = true;
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}
          '';
          tooltip-format-ethernet = ''
              {ifname}
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
          on-click = "${alacritty} -e ${nmtui}";
          on-click-right = "${nm-connection}";
          tooltip = true;
        };

        # Audio
        # pulseaudio = {
        #   format = "{icon} {volume}% {format_source}";
        #   format-bluetooth = "{volume}% {icon} {format_source}";
        #   format-bluetooth-muted = " {icon} {format_source}";
        #   format-muted = "{format_source}";
        #   format-source = " {volume}%";
        #   format-source-muted = "";
        #   format-icons = {
        #     headphone = "";
        #     headset = "󰋎";
        #     phone = "";
        #     portable = "";
        #     car = "";
        #     default = [ "" "" " " ];
        #   };
        #   on-click = "${pwvucontrol}";
        #   tooltip-format = ''
        #   {source_volume}% / {desc}
        #   '';
        # };

        wireplumber = {
          format = "{icon}";
          format-muted = "󰖁";
          max-length = 2;
          scroll-step = 1;
          on-scroll-up = "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          format-icons = [ "" "" " " ];
          on-click = "${pwvucontrol}";
          max-volume = 100.0;
          tooltip = true;
          tooltip-format = ''
          {volume}%
          {node_name}
          '';
          reverse-scrolling = 1;
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

        "custom/applauncher" = {
          "format" = "󱗼";
          "on-click" = "${config.home.homeDirectory}/.config/rofi/scripts/applauncher-fullscreen.sh";
          "tooltip-format" = "Application Launcher";
        };

        "custom/chrome" = {
            "format" = "";
            "on-click" = "${chrome}";
            "tooltip-format" = "Open Chromium";
        };

        "custom/firefox" = {
            "format" = "";
            "on-click" = "${firefox}";
            "tooltip-format" = "Open Firefox";
        };

        "custom/thunar" = {
            "format" = "";
            "on-click" = "${thunar}";
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
      }];

      style = ''
        @define-color backgrounddark1 ${base00};
        @define-color backgrounddark2 ${base01};
        @define-color backgrounddark3 ${base02};
        @define-color workspacesbackground1 #FFFFFF;
        @define-color workspacesbackground2 #CCCCCC;
        @define-color bordercolor #FFFFFF;
        @define-color textcolor1 ${base07};
        @define-color textcolor2 ${base00};
        @define-color textcolor3 #FFFFFF;
        @define-color iconcolor ${base0E};

          * {
            font-size: 14px;
            font-family: ${sansSerif.name}, ${monospace.name};
            font-weight: bold;
          }

          /* -----------------------------------------------------
          * Window
          * ----------------------------------------------------- */

          window#waybar {
            background-color: @backgrounddark1;
            opacity: 0.8;
            color: @textcolor1;
            border-bottom: 0px solid #ffffff;
            transition-property: background-color;
            transition-duration: 0.5s;
          }

          window#waybar.hidden {
            opacity: 0.2;
          }

          window#waybar.empty #window {
            background-color: transparent;
          }

          /* -----------------------------------------------------
          * Modules
          * ----------------------------------------------------- */

          .modules-right {
            padding: 0 10px 0 10px;
            border-radius: 0px;
          }

          .modules-right > widget:last-child > #workspaces {
            margin-right: 0;
          }

          .modules-center {
            padding: 0 10px 0 10px;
            border-radius: 0px;
          }

          .modules-left {
            padding: 0 10px 0 10px;
            border-radius: 0px;
          }

          .modules-left > widget:first-child > #workspaces {
            margin-left: 0;
          }

          #hyprland-workspaces {
            border-radius: 0px;
            padding: 0 1px;
          }

          #workspaces button {
            min-width: 5px;
            color: @textcolor1;
          }

          /* -----------------------------------------------------
          * Tooltips
          * ----------------------------------------------------- */

          tooltip {
            border-radius: 10px;
            background-color: @backgrounddark2;
            opacity:0.8;
            padding:20px;
            margin:0px;
          }

          tooltip label {
            color: @textcolor1;
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
            color: @textcolor1;
            font-size: 14px;
          }

          #battery.icon {
            font-size: 16px;
          }

          #network.icon {
            font-size: 16px;
          }

          /* -----------------------------------------------------
          * Clock
          * ----------------------------------------------------- */

          #clock {
            margin: 0px;
            padding: 0 10px 0 10px;
            color: @textcolor1;
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
            color: @textcolor1;
          }

          #bluetooth {
            margin: 0px;
            padding: 0 10px 0 10px;
            color: @textcolor1;
            font-size: 16px;
            font-weight: bold;
          }

          #bluetooth.icon {
            font-size: 16px;
          }

          #custom-cliphist {
            margin: 0px;
            padding: 0 10px 0 10px;
            color: @textcolor1;
            font-size: 16px;
            font-weight: bold;
          }

          #group-hardware {
            margin: 0px;
            padding: 0 10px 0 10px;
            color: @textcolor1;
            font-size: 16px;
            font-weight: bold;
          }

          #disk {
            margin: 0px;
            padding: 0 10px 0 10px;
            font-size: 13px;
            color: @textcolor1;
          }

          #cpu,
          #memory,
          #custom-gpu {
            margin: 0px;
            padding: 0 10px 0 10px;
            font-size: 14px;
            color: @textcolor1;
          }

          #custom-exit {
            padding-right: 15px;
          }

          #custom-applauncher {
            font-size: 22px;
            padding-right: 2px;
            padding-left: 2px;
          }
      '';
    };
  };
}
