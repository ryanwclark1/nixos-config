{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # Configure niriswitcher
    niriswitcher = {
      enable = true;
    };

    # Home Manager exposes `programs.niri.settings`/`package` here; the NixOS
    # module owns session enablement.
    niri = {
      settings = {
        environment."NIXOS_OZONE_WL" = "1";
        input = {
          keyboard = {
            xkb = {
              layout = "us";
            };
          };

          touchpad = {
            tap = true;
            dwt = true;
            natural-scroll = true;
          };
        };

        layout = {
          border = {
            enable = true;
            width = 2;
          };
          gaps = 8;
          center-focused-column = "never";
          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];
          # default-column-width = { proportion = 0.5; };
        };

        spawn-at-startup = [
          {
            command = [
              "sh"
              "-c"
              "systemctl --user reset-failed quickshell.service swayosd.service voxtype.service >/dev/null 2>&1 || true"
            ];
          }
          {
            command = [
              "systemctl"
              "--user"
              "start"
              "--no-block"
              "quickshell.service"
              "swayosd.service"
              "voxtype.service"
            ];
          }
          {
            command = [
              "sh"
              "-c"
              "systemctl --user reset-failed waybar.service || true"
            ];
          }
          {
            command = [
              "systemctl"
              "--user"
              "start"
              "waybar.service"
            ];
          }
          # {
          #   command = [
          #     "sh"
          #     "-c"
          #     "systemctl --user reset-failed swaync.service || true"
          #   ];
          # }
          # {
          #   command = [
          #     "systemctl"
          #     "--user"
          #     "start"
          #     "swaync.service"
          #   ];
          # }
        ];

        prefer-no-csd = true;

        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

        hotkey-overlay.skip-at-startup = true;

        animations.slowdown = 1.0;

        window-rules = [
          {
            geometry-corner-radius = {
              top-left = 12.0;
              top-right = 12.0;
              bottom-left = 12.0;
              bottom-right = 12.0;
            };
            clip-to-geometry = true;
          }
        ];

        binds = {
          "Mod+Q".action.close-window = null;

          "Mod+H".action.focus-column-left = null;
          "Mod+L".action.focus-column-right = null;
          "Mod+J".action.focus-window-down = null;
          "Mod+K".action.focus-window-up = null;

          "Mod+Shift+H".action.move-column-left = null;
          "Mod+Shift+L".action.move-column-right = null;
          "Mod+Shift+J".action.move-window-down = null;
          "Mod+Shift+K".action.move-window-up = null;

          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;

          "Mod+Shift+1".action.move-column-to-workspace = 1;
          "Mod+Shift+2".action.move-column-to-workspace = 2;
          "Mod+Shift+3".action.move-column-to-workspace = 3;
          "Mod+Shift+4".action.move-column-to-workspace = 4;
          "Mod+Shift+5".action.move-column-to-workspace = 5;

          "Mod+Shift+E".action.spawn = [ "quickshell" "ipc" "call" "Shell" "toggleSurface" "powerMenu" ];
          "Ctrl+Alt+Delete".action.spawn = [ "quickshell" "ipc" "call" "Shell" "toggleSurface" "powerMenu" ];

          # Applications and quick launchers aligned with the Hyprland setup.
          "Mod+Return".action.spawn = [ "ghostty" ];
          "Mod+Space".action.spawn = [ "qs-rofi" "-show" "drun" ];
          "Mod+X".action.spawn = [ "rofi" "-show" "drun" ];
          "Mod+Z".action.spawn = [ "qs-rofi" "-show" "drun" ];
          "Mod+R".action.spawn = [ "qs-rofi" "-show" "run" ];
          "Mod+E".action.spawn = [ "code" ];
          "Mod+B".action.spawn = [ "google-chrome" ];
          "Mod+N".action.spawn = [ "nautilus" ];
          "Mod+Alt+Space".action.spawn = [ "nautilus" ];
          "Mod+Alt+L".action.spawn = [ "hyprlock" ];
          "Mod+Ctrl+E".action.spawn = [ "qs-rofi" "-show" "emoji" ];
          "Mod+Ctrl+C".action.spawn = [ "qs-rofi" "-show" "calc" ];
          "Mod+Shift+T".action.spawn = [ "voxtype" "toggle" ];
          "Mod+F1".action.spawn = [ "qs-rofi" "-show" "keybinds" ];

          # Screenshot (using shared Wayland script)
          "Print".action.spawn = [ "sh" "-c" "~/.local/bin/scripts/wayland/screenshot.sh area" ];
          "Mod+S".action.spawn = [ "sh" "-c" "~/.local/bin/scripts/wayland/screenshot.sh area" ];
          "Mod+Print".action.screenshot-screen = null;
          "Alt+Print".action.screenshot-window = null;

          # Power menu
          "Mod+Escape".action.spawn = [ "quickshell" "ipc" "call" "Shell" "toggleSurface" "powerMenu" ];

          # Emergency close all Quickshell overlays (launcher, overview, menus)
          "Mod+Shift+Escape".action.spawn = [ "quickshell" "ipc" "call" "Shell" "panicClose" ];

          # Clipboard history
          "Mod+V".action.spawn = [ "sh" "-c" "cliphist list | rofi -dmenu | cliphist decode | wl-copy" ];
          "Mod+Shift+V".action.spawn = [ "sh" "-c" "cliphist list | rofi -dmenu -theme ~/.config/rofi/style/cliphist.rasi | cliphist decode | wl-copy" ];

          # Web search
          "Mod+Shift+W".action.spawn = [ "sh" "-c" "~/.config/desktop/window-managers/shared/scripts/rofi/rofi-web-search.sh" ];
        };
      };
    };
  };

  # Niri-specific packages would go here
  # Note: Basic Wayland tools (wl-clipboard, grim, slurp) are provided by window-managers/shared/
  # Note: wlroots tools (wlr-randr) are provided by window-managers/shared/utils.nix
  home.packages = with pkgs; [
    # Currently no Niri-specific packages needed
  ];
}
