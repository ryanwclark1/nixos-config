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
  hyprlock = lib.getExe config.programs.hyprlock.package;
  terminal = "${pkgs.alacritty}/bin/alacritty";
  missioncenter = "${pkgs.mission-center}/bin/missioncenter";
  nm-connection = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
  nmtui = "${pkgs.networkmanager}/bin/nmtui";
  pwvucontrol = "${pkgs.pwvucontrol}/bin/pwvucontrol";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  chrome = "${pkgs.google-chrome}/bin/google-chrome-stable";
  firefox = lib.getExe config.programs.firefox.package;
  thunar = "thunar";
  # betterTransition = "all 0.3s cubic-bezier(.55,-0.68,.48,1.682)";
in
{

  imports = [
    ./style.nix
  ];

  programs = {
    waybar = {
      enable = true;
      package = pkgs.waybar;
      settings = [
        {
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
            "custom/nix-updates"
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
            on-click = "cliphist-copy";
            on-click-right = "cliphist-delete";
            on-click-middle = "${cliphist} wipe";
            tooltip-format = "Clipboard Manager";
          };

          # Power Menu
          "custom/exit" = {
            format = "";
            on-click = "${pkgs.wlogout}/bin/wlogout";
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
            on-click = "sleep 0.1 && list-hypr-bindings";
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
            interval = 5;
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format-ethernet = "";
            format-wifi = "{icon}";
            format-disconnected = "󰤮";
            tooltip-format = ''
              Network
              Interface: {ifname}
              IP: {ipaddr}/{cidr}
              : {bandwidthUpBits} : {bandwidthDownBits}
            '';
            tooltip-format-ethernet = ''
              Ethernet
               : {ifname}
              IP: {ipaddr}/{cidr}
              : {bandwidthUpBits} : {bandwidthDownBits}
            '';
            tooltip-format-disconnected = "Disconnected";
            tooltip-format-wifi = ''
              Wi-Fi
               : {ifname} @ {essid}
              IP: {ipaddr}/{cidr}
              Strength: {signalStrength}%
              Freq: {frequency}MHz
              : {bandwidthUpBits} : {bandwidthDownBits}
            '';
            max-length = 50;
            on-click = "${terminal} -e ${nmtui}";
            on-click-right = "${nm-connection}";
            tooltip = true;
          };

          wireplumber = {
            format = "{icon}";
            format-muted = " ";
            max-length = 2;
            scroll-step = 1;
            on-scroll-up = "${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+";
            on-scroll-down = "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 2%-";
            format-icons = [ " " " " " " ];
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
            "on-click" = "rofi -show drun -theme $HOME/.config/rofi/style/launcher-full.rasi";
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
        }
      ];
    };
  };
}
