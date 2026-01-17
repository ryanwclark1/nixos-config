{
  imports = [
    ./panel
    ./launcher
    ./notifications
    ./media
    ./session
    ./clipboard
    ./scripts/system-menu.nix # System menu launcher (walker-based)
    ./scripts/rofi/system-menu-rofi.nix # System menu launcher (rofi-based)
    ./utils.nix
  ];

  # Shared window manager scripts
  home.file = {
    # TODO: Relocate
    # Rofi scripts (common across window managers)
    ".local/bin/scripts/rofi/rofi-apps-unified.sh" = {
      force = true;
      source = ./scripts/rofi/rofi-apps-unified.sh;
      executable = true;
    };
    # Symlink for backward compatibility
    ".local/bin/scripts/rofi/apps-unified.sh" = {
      force = true;
      source = ./scripts/rofi/rofi-apps-unified.sh;
      executable = true;
    };

    ".config/desktop/window-managers/shared/scripts" = {
      source = ./scripts;
      recursive = true;
      executable = true;
    };
  };
}
