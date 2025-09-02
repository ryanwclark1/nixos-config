{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  # Don't import the home module when using the system module to avoid conflicts
  # imports = [
  #   inputs.niri.homeModules.niri
  # ];

  programs = {
    # Configure niriswitcher
    niriswitcher = {
      enable = true;
    };

    # Niri configuration using structured settings
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
          border = { enable = true; width = 2; };
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
          { command = ["sh" "-c" "systemctl --user reset-failed waybar.service || true"]; }
          { command = ["systemctl" "--user" "start" "waybar.service"]; }
          { command = ["sh" "-c" "systemctl --user reset-failed swaync.service || true"]; }
          { command = ["systemctl" "--user" "start" "swaync.service"]; }
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
          "Mod+Q".action.close-window = {};

          "Mod+H".action.focus-column-left = {};
          "Mod+L".action.focus-column-right = {};
          "Mod+J".action.focus-window-down = {};
          "Mod+K".action.focus-window-up = {};

          "Mod+Shift+H".action.move-column-left = {};
          "Mod+Shift+L".action.move-column-right = {};
          "Mod+Shift+J".action.move-window-down = {};
          "Mod+Shift+K".action.move-window-up = {};

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

          "Mod+Shift+E".action.quit = {};

          # Applications (matching your Hyprland setup)
          "Mod+T".action.spawn = "kitty";
          "Mod+Return".action.spawn = "kitty";
          "Mod+D".action.spawn = "rofi -show drun";
          "Mod+Space".action.spawn = "rofi -show drun";
          "Mod+E".action.spawn = "code";
          "Mod+B".action.spawn = "google-chrome-stable";
          "Mod+N".action.spawn = "nautilus";
          "Mod+Alt+L".action.spawn = "hyprlock";

          # Screenshot (using same script as Hyprland and built-in actions)
          "Print".action.spawn = "~/.config/hypr/scripts/rofi/screenshot-menu.sh";
          "Mod+S".action.spawn = "~/.config/hypr/scripts/rofi/screenshot-menu.sh";
          "Mod+Print".action.screenshot-screen = {};
          "Alt+Print".action.screenshot-window = {};

          # Power menu
          "Mod+Escape".action.spawn = "~/.config/hypr/scripts/rofi/powermenu-unified.sh";

          # Clipboard history
          "Mod+V".action.spawn = "cliphist list | rofi -dmenu | cliphist decode | wl-copy";

          # Web search
          "Mod+Shift+W".action.spawn = "web-search";
        };
      };
    };
  };

  # Niri-specific packages would go here
  # Note: Basic Wayland tools (wl-clipboard, grim, slurp) are provided by common/wayland/
  # Note: wlroots tools (wlr-randr) are provided by window-managers/shared/utils.nix
  home.packages = with pkgs; [
    # Currently no Niri-specific packages needed
  ];
}
