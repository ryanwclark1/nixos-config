{
  pkgs,
  ...
}:

{
  imports = [
    ./clipboard
    ./launcher
    ./media
    ./notifications
    ./panel
    ./launcher/scripts/rofi/system-menu-rofi.nix # System menu launcher (rofi-based)
    ./launcher/scripts/walker/system-menu.nix # System menu launcher (walker-based)
    ./session
  ];

  home.packages = with pkgs; [
    # wlroots-based compositor tools (only for wlroots compositors like Hyprland, Sway, Niri)
    wlr-randr # Display configuration for wlroots compositors (Hyprland, Sway, etc.)
    swaybg # Wayland wallpaper daemon (fallback)
    swww # Animated wallpaper daemon for wlroots compositors
  ];

  # Shared window manager scripts
  home.file = {
    # Rofi scripts (common across window managers)
    ".local/bin/scripts/rofi/rofi-apps-unified.sh" = {
      force = true;
      source = ./launcher/scripts/rofi/rofi-apps-unified.sh;
      executable = true;
    };

    # Shared scripts directory (for reference/config access)
    ".config/desktop/window-managers/shared/scripts" = {
      source = ./launcher/scripts;
      recursive = true;
      executable = true;
    };
  };
}
