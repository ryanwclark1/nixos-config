{
  config,
  lib,
  pkgs,
  ...
}:

# TODO: Fix ssh functionality
{
  imports = [
    ./style.nix
  ];

  home =
  let
    cliphist = lib.getExe pkgs.cliphist;
    rofi = lib.getExe pkgs.rofi-wayland;
    # style_dir = "${config.home.homeDirectory}/.config/rofi/style";
  in
  {
    file.".config/rofi" = {
      source = ./config;
      recursive = true;
    };
    file.".config/rofi/scripts/cliphist-delete.sh" = {
      text = ''
        #!/usr/bin/env bash
        sleep 0.1 && ${cliphist} list | ${rofi} -dmenu -theme ${config.home.homeDirectory}/.config/rofi/style/cliphist | ${cliphist} delete
        '';
      executable = true;
    };
    file.".config/rofi/scripts/cliphist-copy.sh" = {
      text = ''
        #!/usr/bin/env bash
        sleep 0.1 && ${cliphist} list | ${rofi} -dmenu -theme ${config.home.homeDirectory}/.config/rofi/style/cliphist | ${cliphist} delete
      '';
      executable = true;
    };
    file.".config/rofi/scripts/applauncher-fullscreen.sh" = {
      text = ''
        #!/usr/bin/env bash

        dir="${config.home.homeDirectory}/.config/rofi/style"
        theme='launcher-full'

        rofi_cmd() {
          rofi -show drun \
            -theme "$dir/$theme.rasi"
        }

        rofi_cmd
      '';
      executable = true;
    };
    # TODO: Fix lastlogin/uptime.  Why host?  Suspend function
    file.".config/rofi/scripts/power-big.sh" = {
      text = ''
        #!/usr/bin/env bash

        # Current Theme
        dir="${config.home.homeDirectory}/.config/rofi/style"
        theme='power-big'
        background="$(hyprctl hyprpaper listloaded)"

        # CMDs
        lastlogin="$(last -n 1 "$USER" | tr -s ' ' | cut -d' ' -f5-7)"
        uptime="$(awk -F '( |,)' '{print $6, $7, $8}' <(uptime))"
        host="$(hostname)"

        # Options
        shutdown=' '
        reboot=''
        lock=''
        suspend='󰏦'
        logout='󰍃'
        yes=' '
        no=' '

        # Rofi CMD
        rofi_cmd() {
          rofi -dmenu \
            -p "Goodbye $USER" \
            -mesg "Uptime: $uptime" \
            -theme "$dir/$theme.rasi"
        }

        # Confirmation CMD
        confirm_cmd() {
          rofi -dmenu \
            -p 'Confirmation' \
            -mesg 'Are You Sure?' \
            -theme "$dir/shared/confirm-big.rasi"
        }

        # Ask for confirmation
        confirm_exit() {
          echo -e "$yes\n$no" | confirm_cmd
        }

        # Pass variables to rofi dmenu
        run_rofi() {
          echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
        }

        # Execute Command
        run_cmd() {
          selected="$(confirm_exit)"
          if [[ "$selected" == "$yes" ]]; then
            case $1 in
              '--shutdown')
                systemctl poweroff
                ;;
              '--reboot')
                systemctl reboot
                ;;
              '--suspend')
                mpc -q pause
                amixer set Master mute
                systemctl suspend
                ;;
              '--logout')
                case "$DESKTOP_SESSION" in
                  hyprland)
                    hyprctl dispatch exit
                    ;;
                  plasma)
                    qdbus org.kde.ksmserver /KSMServer logout 0 0 0
                    ;;
                  *)
                    echo "Unsupported session: $DESKTOP_SESSION"
                    ;;
                esac
                ;;
            esac
          else
            exit 0
          fi
        }

        # Actions
        chosen="$(run_rofi)"
        case $chosen in
          $shutdown)
            run_cmd --shutdown
            ;;
          $reboot)
            run_cmd --reboot
            ;;
          $lock)
            if command -v hyprlock &> /dev/null; then
              hyprlock
            else
              echo "hyprlock does not exist."
            fi
            ;;
          $suspend)
            run_cmd --suspend
            ;;
          $logout)
            run_cmd --logout
            ;;
        esac
      '';
      executable = true;
    };
  };

  # home.file = {

  programs = {
    rofi =
    let
      alacrity = lib.getExe pkgs.alacritty;
    in {
      enable = true;
      package = pkgs.rofi-wayland;
      # configPath = "${config.home.homeDirectory}/.config/rofi/config.rasi";
      # cycle = true;
      # font = "JetBrainsMono";
      # location = "center";
      terminal = "${alacrity}";
      # xoffset = 0;
      # yoffset = 0;
      plugins = [
        pkgs.rofi-emoji-wayland
      ];
      # extraConfig = {
      #   bw = 1;
      #   columns = 2;
      #   icon-theme = "Papirus-Dark";
      #   modi = "drun,ssh";
      #   show-icons = true;
      #   drun-display-format = "{icon} {name}";
      #   disable-history = false;
      #   hide-scrollbar = true;
      #   display-drun = "   Apps ";
      #   display-run = "   Run ";
      #   display-emoji = "   Emoji ";
      #   display-calc = "   Calc ";
      #   display-filebrowser = "FILES";
      #   display-window = "WINDOW";
      #   sidebar-mode = true;
      #   hover-select = false;
      #   scroll-method = 1;
      #   me-select-entry = "";
      #   me-accept-entry = "MousePrimary";
      #   window-format = "{w} · {c} · {t}";
      # };
      # theme = {
      #   "@theme" = "base";
      #   window = {
      #     width = "900px";
      #     x-offset = "0px";
      #     y-offset = "0px";
      #     spacing = "0px";
      #     padding = "0px";
      #     margin = "0px";
      #     color = "#FFFFFF";
      #     border = "3px";
      #     border-color = "#FFFFFF";
      #     cursor = "default";
      #     transparency = "real";
      #     location = "center";
      #     anchor = "center";
      #     fullscreen = false;
      #     enabled = true;
      #     border-radius = "10px";
      #     # background-color = "transparent";
      #   };

      #   mainbox = {
      #     enabled = true;
      #     orientation = "horizontal";
      #     spacing = "0px";
      #     margin = "0px";
      #     # background-color = @background;
      #     children = [
      #       "imagebox"
      #       "listbox"
      #     ];
      #   };

      #   imagebox = {
      #     padding = "18px";
      #     background-color = "transparent";
      #     orientation = "vertical";
      #     children = [
      #       "inputbar"
      #       "dummy"
      #       "mode-switcher"
      #     ];
      #   };

      #   listbox = {
      #     spacing = "20px";
      #     background-color = "transparent";
      #     orientation = "vertical";
      #     children = [
      #       "message"
      #       "listview"
      #     ];
      #   };

      #   dummy = {
      #     background-color = "transparent";
      #   };

      #   inputbar = {
      #     enabled = true;
      #     # text-color = @foreground;
      #     spacing = "10px";
      #     padding = "15px";
      #     border-radius = "10px";
      #     # border-color = @foreground;
      #     # background-color = @background;
      #     children = [
      #       "textbox-prompt-colon"
      #       "entry"
      #     ];
      #   };

      #   textbox-prompt-colon = {
      #     enabled = true;
      #     expand = false;
      #     str = "";
      #     padding = "0px 5px 0px 0px";
      #     background-color = "transparent";
      #     # text-color = inherit;
      #   };

      #   entry = {
      #     enabled = true;
      #     background-color = "transparent";
      #     # text-color = inherit;
      #     cursor = "text";
      #     placeholder = "Search";
      #     # placeholder-color = inherit;
      #   };

      #   mode-switcher ={
      #     enabled = true;
      #     spacing = "20px";
      #     background-color = "transparent";
      #     # text-color = @foreground;
      #   };

      #   button = {
      #     padding = "10px";
      #     border-radius = "10px";
      #     # background-color = @background;
      #     # text-color = inherit;
      #     cursor = "pointer";
      #     border = "0px";
      #   };

      #   # button selected = {
      #     # background-color = @color11;
      #     # text-color = @foreground;
      #   # };

      #   listview = {
      #     enabled = true;
      #     columns = 1;
      #     lines = 8;
      #     cycle = false;
      #     dynamic = false;
      #     scrollbar = false;
      #     layout = "vertical";
      #     reverse = false;
      #     fixed-height = true;
      #     fixed-columns = true;
      #     spacing = "0px";
      #     padding = "10px";
      #     margin = "0px";
      #     # background-color = @background;
      #     border = "0px";
      #   };

      #   element = {
      #     enabled = true;
      #     padding = "10px";
      #     margin = "5px";
      #     cursor = "pointer";
      #     # background-color = @background;
      #     border-radius = "10px";
      #     border = "3px";
      #   };

      #   # element normal.normal = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element normal.urgent = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element normal.active = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element selected.normal = {
      #   #   background-color = @color11;
      #   #   text-color = @foreground;
      #   # };

      #   # element selected.urgent = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element selected.active = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element alternate.normal = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element alternate.urgent = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   # element alternate.active = {
      #   #   background-color = inherit;
      #   #   text-color = @foreground;
      #   # };

      #   element-icon = {
      #     # background-color = "transparent";
      #     # text-color = inherit;
      #     size = "32px";
      #     # cursor = inherit;
      #   };

      #   element-text = {
      #     # background-color = "transparent";
      #     # text-color = inherit;
      #     # cursor = inherit;
      #     vertical-align = "0.5";
      #     horizontal-align = "0.0";
      #   };


      #   message = {
      #     background-color = "transparent";
      #     border = "0px";
      #     margin = "20px 0px 0px 0px";
      #     padding = "0px";
      #     spacing = "0px";
      #     border-radius =  "10px";
      #   };

      #   textbox = {
      #     padding = "15px";
      #     margin = "0px";
      #     border-radius = "0px";
      #     # background-color = @background;
      #     # text-color = @foreground;
      #     vertical-align = "0.5";
      #     horizontal-align = "0.0";
      #   };

      #   error-message = {
      #     padding = "15px";
      #     border-radius = "20px";
      #     # background-color = @background;
      #     # text-color = @foreground;
      #   };

      # };


      pass = {
        enable = true;
        package = pkgs.rofi-pass-wayland;
        stores = [
          "/home/administrator/.local/share/keyrings"
        ];
      };
    };
  };
}