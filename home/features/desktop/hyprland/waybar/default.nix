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
  nm-connection = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
  missioncenter = "${pkgs.mission-center}/bin/missioncenter";
  cliphist = "${pkgs.cliphist}/bin/cliphist";
  rofi = "${pkgs.rofi}/bin/rofi";
  hypridle = lib.getExe config.services.hypridle.package;
in
{
  home = {
    file.".config/waybar/themes" = {
      source = ./themes;
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
        # exclusive = true;
        # layer = "top";
        # position = "top";
        # passthrough = false;
        # gtk-layer-shell = true;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "network" "pulseaudio" "cpu" "custom/gpu"  "memory" "disk" "clock" "battery"];
        modules-right = [ "custom/notification" "tray" ];

        "hyprland/workspaces" = {
          format = "{}";
          format-icons = {
            default = "";
            active = "";
            urgent = "";
          };
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        "wlr/taskbar" = {
          format = "{icon}";
          icon-size = 18;
          tooltip-format = "{title}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = ["Alacritty" "kitty"];
          # app_ids-mapping = {
          #   firefoxdeveloperedition = "firefox-developer-edition"
          # };
          # rewrite = {
          #   "Firefox Web Browser" = "Firefox";
          #   "Foot Server" = "Terminal"
          # };
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

        # Empty
        "custom/empty" = {
          format = "";
        };

        # Empty
        "custom/tools" = {
          format = "";
          tooltip-format = "Tools";
        };

        # Cliphist
        "custom/cliphist" = {
          format = "";
          on-click = "sleep 0.1 && ${cliphist} list | ${rofi} -demu -replace -config ~/.config/rofi/config-cliphist.rasi | cliphist delete";
          on-click-right = "sleep 0.1 && ${cliphist} list | ${rofi} -demu -replace -config ~/.config/rofi/config-cliphist.rasi | cliphist decode | wl-copy";
          on-click-middle = "${cliphist} wipe";
          tooltip-format = "Clipboard Manager";
        };

        # Power Menu
        "custom/exit" = {
          format = "";
          on-click = "wlogout";
          tooltip-format = "Power Menu";
        };

        # Hypridle inhibitor
        "custom/hypridle" = {
          format = "";
          return-type = "json";
          escape = true;
          exec-on-event = true;
          interval = 60;
          exec = "~/.config/hypr/scripts/hypridle.sh status";
          on-click = "~/.config/hypr/scripts/hypridle.sh toggle";
          on-click-right = "hyprlock";
        };

        # System tray
        tray = {
          icon-size = 21;
          spacing = 10;
        };

        clock = {
          format = "{:%H:%M }";
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
              "months" = "<span color='#ffead3'><b>{}</b></span>";
              "days" = "<span color='#ecc6d9'><b>{}</b></span>";
              # "weeks" = "<span color='#99ffdd'><b>W{}</b></span>";
              "weekdays" = "<span color='#ffcc66'><b>{}</b></span>";
              "today" = "<span color='#ff6699'><b><u>{}</u></b></span>";
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

        "hyprland/window" = {
          max-length = 60;
          separate-outputs = false;
        };

        memory = {
          interval = 5;
          format = "  {}%";
          tooltip = true;
          on-click = "${missioncenter}";
        };

        cpu = {
          interval = 5;
          format = "  {usage:2}%";
          tooltip = true;
          on-click = "${missioncenter}";
        };

        "custom/gpu" = {
            interval = 5;
            exec = "${cat} /sys/class/drm/card0/device/gpu_busy_percent";
            format = "󰒋  {}%";
            on-click = "${missioncenter}";
        };

        disk = {
          interval = 30;
          format = "  {free}";
          tooltip = true;
          on-click = "${missioncenter}";
        };

        "hyprland/language" = {
          format = "/ K {short}";
        };

        # Group Hardware
        "group/hardware" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            children-class = "not-memory";
            transition-left-to-right = false;
          };
          modules = [
            "custom/system"
            "disk"
            "cpu"
            "custom/gpu"
            "memory"
            "hyprland/language"
          ];
        };

        # Group Tools
        "group/tools" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            children-class = "not-memory";
            transition-left-to-right = false;
          };
          modules = [
            "custom/tools"
            "custom/cliphist"
            "custom/hypridle"
            "custom/hyprshade"
          ];
        };

        "custom/chatgpt" = {
          format = "";
          on-click = "";
          tooltip-format = "AI Support";
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
            children-class = "not-memory";
            transition-left-to-right = true;
          };
          modules = [
            "custom/settings"
            "custom/waybarthemes"
            "custom/wallpaper"
          ];
        };

        network = {
          interval = 3;
          format = "{ifname}";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          format-ethernet = ": {bandwidthDownOctets} : {bandwidthUpOctets}";
          format-wifi = "{icon} {signalStrength}% {essid}";
          format-disconnected = "󰤮";
          # tooltip = true;
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}
          '';
          tooltip-format-ethernet = '' {ifname}
          IP: {ipaddr}
          up: {bandwidthUpBits} down: {bandwidthDownBits}'';
          tooltip-format-disconnected = "Disconnected";
          tooltip-format-wifi = ''  {ifname} @ {essid}
          IP: {ipaddr}
          Strength: {signalStrength}%
          Freq: {frequency}MHz
          Up: {bandwidthUpBits} Down: {bandwidthDownBits}'';
          max-length = 50;
          on-click = "${kitty} -e ${nmtui}";
          on-click-right = "${nm-connection}";
        };

        # tray = {
        #   spacing = 12;
        # };

        # Audio
        pulseaudio = {
          format = "{icon} {volume}% {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = "  {format_source}";
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
          on-click = "${pavucontrol}";
          tooltip-format = "{source_volume}% / {desc}";
        };

        # Bluetooth
        bluetooth = {
          format = " {status}";
          format-disabled = "";
          format-off = "";
          interval = 30;
          on-click = "blueman-manager";
          format-no-controller = "";
        };

        user = {
          format = "{user}";
          interval = 60;
          icon = false;
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
          interval = 10;
          states = {
            good = 95;
            warning = 20;
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = " {capacity}%";
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          on-click = "";
          tooltip = false;
        };
      }];

      style = ''
        * {
            /* `otf-font-awesome` is required to be installed for icons */
            font-family: JetBrainsMono Nerd Font, Font Awesome, sans-serif;
            font-size: 13px;
        }

        window#waybar {
            background-color: rgba(43, 48, 59, 0.5);
            border-bottom: 3px solid rgba(100, 114, 125, 0.5);
            color: #ffffff;
            transition-property: background-color;
            transition-duration: .5s;
        }

        window#waybar.hidden {
            opacity: 0.2;
        }

        /*
        window#waybar.empswayty {
            background-color: transparent;
        }
        window#waybar.solo {
            background-color: #FFFFFF;
        }
        */

        window#waybar.termite {
            background-color: #3F3F3F;
        }

        window#waybar.chromium {
            background-color: #000000;
            border: none;
        }

        #custom-ml4w-welcome {
            margin-right: 15px;
            background-image: url("../assets/ml4w-icon-20.png");
            background-repeat: no-repeat;
            background-position: center;
            padding-right: 20px;
            margin-right: 0px;
        }

        button {
            /* Use box-shadow instead of border so the text isn't offset */
            box-shadow: inset 0 -3px transparent;
            /* Avoid rounded borders under each button name */
            border: none;
            border-radius: 0;
        }

        /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
        button:hover {
            background: inherit;
            box-shadow: inset 0 -3px #ffffff;
        }

        #workspaces button {
            padding: 0 5px;
            background-color: transparent;
            color: #ffffff;
        }

        #workspaces button:hover {
            background: rgba(0, 0, 0, 0.2);
        }

        #workspaces button.focused {
            background-color: #64727D;
            box-shadow: inset 0 -3px #ffffff;
        }

        #workspaces button.urgent {
            background-color: #eb4d4b;
        }

        #mode {
            background-color: #64727D;
            border-bottom: 3px solid #ffffff;
        }

        #clock,
        #battery,
        #cpu,
        #memory,
        #disk,
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
            padding: 0 10px;
            color: #ffffff;
        }

        #window,
        #workspaces {
            margin: 0 4px;
        }

        /* If workspaces is the leftmost module, omit left margin */
        .modules-left > widget:first-child > #workspaces {
            margin-left: 0;
        }

        /* If workspaces is the rightmost module, omit right margin */
        .modules-right > widget:last-child > #workspaces {
            margin-right: 0;
        }

        #clock {
            background-color: #64727D;
        }

        #battery {
            background-color: #ffffff;
            color: #000000;
        }

        #battery.charging, #battery.plugged {
            color: #ffffff;
            background-color: #26A65B;
        }

        @keyframes blink {
            to {
                background-color: #ffffff;
                color: #000000;
            }
        }

        #battery.critical:not(.charging) {
            background-color: #f53c3c;
            color: #ffffff;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
        }

        label:focus {
            background-color: #000000;
        }

        #cpu {
            background-color: #2ecc71;
            color: #000000;
        }

        #memory {
            background-color: #9b59b6;
        }

        #disk {
            background-color: #964B00;
        }

        #backlight {
            background-color: #90b1b1;
        }

        #network {
            background-color: #2980b9;
        }

        #network.disconnected {
            background-color: #f53c3c;
        }

        #pulseaudio {
            background-color: #f1c40f;
            color: #000000;
        }

        #pulseaudio.muted {
            background-color: #90b1b1;
            color: #2a5c45;
        }

        #wireplumber {
            background-color: #fff0f5;
            color: #000000;
        }

        #wireplumber.muted {
            background-color: #f53c3c;
        }

        #custom-media {
            background-color: #66cc99;
            color: #2a5c45;
            min-width: 100px;
        }

        #custom-media.custom-spotify {
            background-color: #66cc99;
        }

        #custom-media.custom-vlc {
            background-color: #ffa000;
        }

        #temperature {
            background-color: #f0932b;
        }

        #temperature.critical {
            background-color: #eb4d4b;
        }

        #tray {
            background-color: #2980b9;
        }

        #tray > .passive {
            -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
            -gtk-icon-effect: highlight;
            background-color: #eb4d4b;
        }

        #idle_inhibitor {
            background-color: #2d3436;
        }

        #idle_inhibitor.activated {
            background-color: #ecf0f1;
            color: #2d3436;
        }

        #mpd {
            background-color: #66cc99;
            color: #2a5c45;
        }

        #mpd.disconnected {
            background-color: #f53c3c;
        }

        #mpd.stopped {
            background-color: #90b1b1;
        }

        #mpd.paused {
            background-color: #51a37a;
        }

        #language {
            background: #00b093;
            color: #740864;
            padding: 0 5px;
            margin: 0 5px;
            min-width: 16px;
        }

        #keyboard-state {
            background: #97e1ad;
            color: #000000;
            padding: 0 0px;
            margin: 0 5px;
            min-width: 16px;
        }

        #keyboard-state > label {
            padding: 0 5px;
        }

        #keyboard-state > label.locked {
            background: rgba(0, 0, 0, 0.2);
        }

        #scratchpad {
            background: rgba(0, 0, 0, 0.2);
        }

        #scratchpad.empty {
          background-color: transparent;
        }

      '';
    };
  };
}
