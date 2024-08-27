{
  pkgs,
  ...
}:
let
  cat = "${pkgs.coreutils}/bin/cat";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  kitty = "${pkgs.kitty}/bin/kitty";
  nmtui = "${pkgs.networkmanager}/bin/nmtui";
  nm-connection = "${pkgs.networkmanager}/bin/nm-connection-editor";
  mission-center = "${pkgs.mission-center}/bin/mission-center";
  cliphist = "${pkgs.cliphist}/bin/cliphist";
  rofi = "${pkgs.rofi}/bin/rofi";
in
{
  programs = {
    waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [{
        exclusive = true;
        layer = "top";
        position = "top";
        height = 11;
        passthrough = false;
        gtk-layer-shell = true;
        modules-left = [ "hyprland/window" ];
        modules-center = [ "network" "pulseaudio" "cpu" "custom/gpu" "hyprland/workspaces" "memory" "disk" "clock" "battery"];
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
          on-click = "${mission-center}";
        };

        cpu = {
          interval = 5;
          format = "  {usage:2}%";
          tooltip = true;
          on-click = "${mission-center}";
        };

        "custom/gpu" = {
            interval = 5;
            exec = "${cat} /sys/class/drm/card0/device/gpu_busy_percent";
            format = "󰒋  {}%";
            on-click = "${mission-center}";
        };

        disk = {
          interval = 30;
          format = "  {free}";
          tooltip = true;
          on-click = "${mission-center}";
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

        # Group Links
        "group/links" = {
          orientation = "horizontal";
          modules = [
            custom/chatgpt"
            custom/empty"
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
          tooltip-format-ethernet = '' {ifname}\nIP: {ipaddr}\n up: {bandwidthUpBits} down: {bandwidthDownBits}'';
          tooltip-format-disconnected = "Disconnected";
          tooltip-format-wifi = ''  {ifname} @ {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\nFreq: {frequency}MHz\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}'';
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
            font-size: 12px;
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
}
